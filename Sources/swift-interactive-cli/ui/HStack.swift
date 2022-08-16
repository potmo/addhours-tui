import Foundation

class HStack: Drawable {
    
    fileprivate var children: [Child]
    fileprivate var needsRedraw: NeedsRedraw
    
    init() {
        self.children = []
        self.needsRedraw = .yes
    }
    
    func addChild(child: Drawable) {
        self.children.append(Child(drawable: child, needsRedraw: .yes))
        needsRedraw = .yes
    }
    
    func addChild(child: Drawable, at index: Int) {
        children.insert(Child(drawable: child, needsRedraw: .yes), at: index)
        children = children[index..<children.count].map{ child in
            child.needsRedraw = .yes
            return child
        }
        needsRedraw = .yes
    }
    
    func removeChild(at index: Int) {
        children.remove(at: index)
        children = children[index..<children.count].map{ child in
            child.needsRedraw = .yes
            return child
        }
        needsRedraw = .yes
    }
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        // we dont care about the directives really. Just draw
        var currentBounds: GlobalDrawBounds = GlobalDrawBounds(column: bounds.column,
                                                               row: bounds.row,
                                                               width: bounds.width,
                                                               height: getMinimumSize().height)
        
        let usedBounds = currentBounds
        
        var forceRedrawRest = needsRedraw == .yes || cause == .forced
        
        for (index, child) in children.enumerated() {
            
            let usedSpace = child.drawable.draw(cause: forceRedrawRest ? .forced : cause,
                                                in: currentBounds,
                                                with: screenWriter,
                                                horizontally: index == children.count - 1 ? .fill : .alignStart,
                                                vertically: .fill)
            currentBounds = currentBounds.offset(columns: usedSpace.width, rows: 0)
                                         .offsetSize(columns: -usedSpace.width, rows: 0)
            
            // if the draw does not have the same size as last time (or we have no last time)
            // we need to force redraw the rest
            if child.needsRedraw != .no(cachedSize: usedSpace) {
                child.needsRedraw = .no(cachedSize: usedSpace)
                forceRedrawRest = true
            }
            
            // Stop when we are about to draw out of bounds
            if (currentBounds.width <= 0) {
                break
            }
        }
        
        let drawnSize = DrawSize(width: bounds.width, height: usedBounds.height)
        needsRedraw = .no(cachedSize: drawnSize)
        return drawnSize
    }
    
    func getMinimumSize() -> DrawSize {
        let sizes = children.map{$0.drawable}.map{$0.getMinimumSize()}
        let height = sizes.map{$0.height}.max() ?? 0
        let width = sizes.map{$0.width}.reduce(0,+)
        return DrawSize(width: width, height: height)
    }
    
    class Child {
        let drawable: Drawable
        var needsRedraw: NeedsRedraw
        
        init(drawable: Drawable, needsRedraw: NeedsRedraw) {
            self.drawable = drawable
            self.needsRedraw = needsRedraw
        }
    }
}
