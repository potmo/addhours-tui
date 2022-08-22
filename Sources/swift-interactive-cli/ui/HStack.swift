import Foundation

class HStack: Drawable {
    
    private var children: [Drawable]
    private var lastDrawBounds: [GlobalDrawBounds]
    
    init(@DrawableBuilder _ content: () -> [Drawable]) {
        self.children = content()
        self.lastDrawBounds = []
    }
    
    @discardableResult
    func addChild(child: Drawable) -> Self {
        children.append(child)
        return self
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        var childRedrew = false
        var forceRest = false
        let childDrawBounds = getChildDrawBounds(in: bounds)
        let currentDrawBounds = childDrawBounds.map(\.0)
        
        // if the bounds does not match then that means that we need to redraw all of them
        if lastDrawBounds != currentDrawBounds {
            forceRest = true
        }
        
        for (drawBounds, child) in childDrawBounds {
            
            guard !drawBounds.isFullyOutside(bounds) else {
                continue
            }
            
            let redraw = child.draw(with: screenWriter.bound(to: drawBounds),
                                    in: drawBounds,
                                    force: forced || forceRest)
            switch redraw {
                case .skippedDraw:
                    continue
                case .drew:
                    childRedrew = true
                    forceRest = true
            }
        }
        
        if forceRest {
            //let usedBounds = getDrawBounds(given: bounds, with: Arrange(.alignStart, .fill))
            //TODO: implement fill
            //screenWriter.fill(bounds: bounds, with: "/", excluding: usedBounds)
        }
        
        return childRedrew ? .drew : .skippedDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {

        let childDrawBounds = getChildDrawBounds(in: bounds)
        var childrenNeedsToDraw: RequiresRedraw = .no
        
        for (drawBounds, child) in childDrawBounds {
            if child.update(with: cause, in: drawBounds) == .yes {
                childrenNeedsToDraw = .yes
            }
        }
        
        lastDrawBounds = childDrawBounds.map(\.0)
        
        return childrenNeedsToDraw
    }
    
    
    func getChildDrawBounds(in bounds: GlobalDrawBounds) -> [(GlobalDrawBounds, Drawable)]{
        var childBounds: [(GlobalDrawBounds, Drawable)] = []
        
        var availableBounds = bounds
        for child in children {
            let drawBounds = child.getDrawBounds(given: availableBounds, with: Arrange(.alignStart, .fill))
            availableBounds = availableBounds.offsetSize(columns: -drawBounds.width, rows: 0)
                .offset(columns: drawBounds.width, rows: 0)
            childBounds.append((drawBounds, child))
        }
        
        return childBounds
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: getMinimumSize(),
                                     horizontally: arrangeDirective.horizontal,
                                     vertically: arrangeDirective.vertical)
        
    }
    
    func getMinimumSize() -> DrawSize {
        let sizes = children.map{$0.getMinimumSize()}
        let width = sizes.map(\.width).reduce(0,+)
        let height = sizes.map(\.height).max() ?? 0
        
        return DrawSize(width: width, height: height)
    }
    
    
    
    
}
