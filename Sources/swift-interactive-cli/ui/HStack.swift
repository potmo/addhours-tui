import Foundation

class HStack: Drawable {
    var children: [TypeErasedContainerChild]
    
    private var lastBounds: GlobalDrawBounds? = nil
    
    init(@DrawableBuilder _ content: () -> [Drawable]) {
        self.children = []
        setChildren(to: content())
    }
    
    @discardableResult
    func addChild(_ child: Drawable, at index: Int)->Self {
        children.insert(TypeErasedContainerChild(drawable: child, requiresRedraw: .yes, drawBounds: GlobalDrawBounds(), didDraw: .skippedDraw), at: index)
        return self
    }
    
    @discardableResult
    func addChild(_ child: Drawable)->Self {
        children.append(TypeErasedContainerChild(drawable: child, requiresRedraw: .yes, drawBounds: GlobalDrawBounds(), didDraw: .skippedDraw))
        return self
    }
    
    @discardableResult
    func removeChild(_ child: Drawable)->Self {
        children.removeAll(where: { container in container.drawable === child})
        return self
    }
    
    @discardableResult
    func removeAllChildren() -> Self {
        children = []
        return self
    }
    
    @discardableResult
    func setChildren(to drawables: [Drawable]) -> Self {
        self.children = []
        drawables.forEach{ drawable in
            self.addChild(drawable)
        }
        return self
    }
    
    @discardableResult
    func setChildren(@DrawableBuilder _ content: () -> [Drawable]) -> Self {
        setChildren(to: content())
        return self
    }

    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)
        
        children = children.map{ child in
            return child.draw(with: screenWriter.bound(to: child.drawBounds),
                              force: forced)
            
        }
        let usedBounds = getDrawBounds(given: bounds, with: Arrange(.alignStart, .fill))
        if usedBounds != lastBounds || forced {
            
            if lastBounds == nil || forced {
                lastBounds = bounds
            }
            
            let backgroundLine = Array(repeating: "/", count: bounds.width - usedBounds.width).joined()
            
            for row in bounds.row ..< bounds.row + bounds.height {
                screenWriter.moveTo(bounds.column + usedBounds.width, row)
                screenWriter.printLineAtCursor(backgroundLine)
            }
            
            lastBounds = usedBounds
        }
        
        return children.map(\.didDraw).contains(.drew) ? .drew : .skippedDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)
        
        children = children.map { child in
            return child.update(with: cause)
        }
        
        return children.map(\.requiresRedraw).reduce(.no){ prev, curr in prev || curr}
    }
    
    func childrenWithUpdatedDrawBounds(children: [TypeErasedContainerChild], in bounds: GlobalDrawBounds) -> [TypeErasedContainerChild]{
        
        var availableBounds = bounds
        return children.map{ child in
            let drawBounds = child.drawable.getDrawBounds(given: availableBounds, with: Arrange(.alignStart, .fill))
            
            availableBounds = availableBounds.offsetSize(columns: -drawBounds.width, rows: 0)
                .offset(columns: drawBounds.width, rows: 0)
            
            return child.updateDrawBounds(with: drawBounds)
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
