import Foundation

class HStack: Drawable {
    
    
    private var children: [Child]
    
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
        
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)
        
        var forceRest = false
        
        let childDraws = children.map{ child -> DidRedraw in
            
            if child.requiresRedraw == .no && !forced && !forceRest {
                return .skippedDraw
            }
            
            let redrew = child.drawable.draw(with: screenWriter.bound(to: child.drawBounds),
                                             in: child.drawBounds,
                                             force: forced || forceRest)
            switch redrew {
                case .skippedDraw:
                    break
                case .drew:
                    forceRest = true
            }
            
            return redrew
        }
        
        if forceRest {
            let usedBounds = getDrawBounds(given: bounds, with: Arrange(.alignStart, .fill))
            let backgroundLine = Array(repeating: "/", count: bounds.width - usedBounds.width).joined()
            
            for row in bounds.row ..< bounds.row + bounds.height {
                screenWriter.moveTo(bounds.column + usedBounds.width, row)
                screenWriter.printLineAtCursor(backgroundLine)
            }
        }
        
        return childDraws.contains(.drew) ? .drew : .skippedDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)
        
        children = children.map { child in
            if child.drawable.update(with: cause, in: child.drawBounds) == .yes {
                return child.requiringRedraw(.yes)
            }else {
                return child.requiringRedraw(.no)
            }
        }
        
        return children.map(\.requiresRedraw).contains(.yes) ? .yes : .no
    }
    
    func childrenWithUpdatedDrawBounds(children: [Child], in bounds: GlobalDrawBounds) -> [Child]{
        
        var restNeedsToRedraw = false
        var availableBounds = bounds
        return children.map{ child in
            let drawBounds = child.drawable.getDrawBounds(given: availableBounds, with: Arrange(.alignStart, .fill))
            
            availableBounds = availableBounds.offsetSize(columns: -drawBounds.width, rows: 0)
                .offset(columns: drawBounds.width, rows: 0)
            
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
        let width = sizes.map(\.width).reduce(0,+)
        let height = sizes.map(\.height).max() ?? 0
        
        return DrawSize(width: width, height: height)
    }
    
    
    
    
}
