import Foundation

class VStack: Drawable {
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
    func setTo(@DrawableBuilder _ content: () -> [Drawable]) -> Self {
        setChildren(to: content())
        return self
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        children = childrenWithUpdatedDrawBounds(children: children, in: bounds)

        children = children.map{ child in
            return child.draw(with: screenWriter.bound(to: child.drawBounds),
                              force: forced)
            
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
            let drawBounds = child.drawable.getDrawBounds(given: availableBounds, with: Arrange(.fill, .alignStart))
                        
            availableBounds = availableBounds.offsetSize(columns: 0, rows: -drawBounds.height)
                .offset(columns: 0, rows: drawBounds.height)
            
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
        let width = sizes.map(\.width).max() ?? 0
        let height = sizes.map(\.height).reduce(0,+)
        
        return DrawSize(width: width, height: height)
    }
    
   
    
    
}
