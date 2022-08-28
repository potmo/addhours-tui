import Foundation

class VStack: Drawable {
    private var children: [Child]
    private var lastBounds: GlobalDrawBounds? = nil
    
    struct Child {
        let drawable: Drawable
        let requiresRedraw: RequiresRedraw
        let drawBounds: GlobalDrawBounds
        func requiringRedraw(_ requiresRedraw:RequiresRedraw) -> Self {
            return Child(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds)
        }
        
        func updateDrawBounds(with drawBounds: GlobalDrawBounds) -> Self {
            return Child(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds)
        }
    }
    
    init(@DrawableBuilder _ content: () -> [Drawable]) {
        self.children = content().map{ drawable in
            Child(drawable: drawable, requiresRedraw: .yes, drawBounds: GlobalDrawBounds())
        }
    }
    
    @discardableResult
    func addChild(_ child: Drawable)->Self {
        children.insert(Child(drawable: child, requiresRedraw: .yes, drawBounds: GlobalDrawBounds()), at: 0)
        self.childrenRequiresRedraw(after: 0)
        return self
    }
    
    private func childrenRequiresRedraw(after index: Int) {
        children = children.enumerated().map{ i, child in
            if i > index {
                return child.requiringRedraw(.yes)
            } else {
                return child
            }
        }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        var forceRest = forced
        
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)

        let childDraws = children.map{ child -> DidRedraw in
            
            if child.requiresRedraw == .no && !forceRest {
                return .skippedDraw
            }
            
            //TODO: The forced concept is a bit off. If we call draw it should draw
            let redrew = child.drawable.draw(with: screenWriter.bound(to: child.drawBounds),
                                             in: child.drawBounds,
                                             force: forceRest)
            
            switch redrew {
                case .skippedDraw:
                    break
                case .drew:
                    forceRest = true
            }
            
            return redrew
        }
        let usedBounds = getDrawBounds(given: bounds, with: Arrange(.fill, .alignStart))
        if usedBounds != lastBounds || forced {
            
            if lastBounds == nil || forced {
                lastBounds = bounds
            }
            
            let backgroundLine = Array(repeating: "/", count: bounds.width).joined()
            let linesToDraw = max(0,lastBounds!.height - usedBounds.height)
            
            for row in usedBounds.row + usedBounds.height ..< usedBounds.row + usedBounds.height + linesToDraw {
                screenWriter.moveTo(bounds.column, row)
                screenWriter.printLineAtCursor(backgroundLine)
            }
            
            lastBounds = usedBounds
        }
        
        return childDraws.contains(.drew) ? .drew : .skippedDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)
        
        children = children.map { child in
            let childRequiresRedraw = child.drawable.update(with: cause, in: child.drawBounds)
            return child.requiringRedraw(childRequiresRedraw)
        }
        
        return children.map(\.requiresRedraw).contains(.yes) ? .yes : .no
    }
    
    func childrenWithUpdatedDrawBounds(children: [Child], in bounds: GlobalDrawBounds) -> [Child]{
      
        var restNeedsToRedraw = false
        var availableBounds = bounds
        return children.map{ child in
            let drawBounds = child.drawable.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
                        
            availableBounds = availableBounds.offsetSize(columns: 0, rows: -drawBounds.height)
                .offset(columns: 0, rows: drawBounds.height)
            
            if restNeedsToRedraw || drawBounds != child.drawBounds {
                restNeedsToRedraw = true
                return child.updateDrawBounds(with: drawBounds)
                        .requiringRedraw(.yes)
            }
            
            return child
        }
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: getMinimumSize(),
                                     horizontally: arrangeDirective.horizontal,
                                     vertically: arrangeDirective.vertical)
        
    }
    
    func getMinimumSize() -> DrawSize {
        let sizes = children.map(\.drawable).map{$0.getMinimumSize()}
        let width = sizes.map(\.width).max() ?? 0
        let height = sizes.map(\.height).reduce(0,+)
        
        return DrawSize(width: width, height: height)
    }
    
   
    
    
}
