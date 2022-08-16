import Foundation

class VStack: Drawable {
    
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
        var currentBounds: GlobalDrawBounds = bounds
        var forceRedrawRest = needsRedraw == .yes || cause == .forced
        
        for child in children {
            
            // Stop when we are about to draw out of bounds
            if (currentBounds.height <= 0) {
                break
            }
            
            let usedSpace = child.drawable.draw(cause: forceRedrawRest ? .forced : cause,
                                                in: currentBounds,
                                                with: screenWriter,
                                                horizontally: .fill,
                                                vertically: .alignStart)
            currentBounds = currentBounds.offset(columns: 0, rows: usedSpace.height).offsetSize(columns: 0, rows: -usedSpace.height)
            
            //TODO: Draw unused space with background
            
            // if the draw does not have the same size as last time (or we have no last time)
            // we need to force redraw the rest
            //TODO: This type of caching does not work since child.needsReadraw is always .no
            // since we didn'set if after drawing and for that we need the size to compare with
            if child.needsRedraw != .no(cachedSize: usedSpace) {
                child.needsRedraw = .no(cachedSize: usedSpace)
                forceRedrawRest = true
            }
            

        }
        
        let background = Array(repeating: " ", count: Int(currentBounds.width))
            .joined()
            .backgroundColor(.ansi(.brightBlack))
            .escapedString()
        
        while currentBounds.height > 0 {
            screenWriter.moveTo(currentBounds.column,currentBounds.row)
            screenWriter.printRaw(background)
            currentBounds = currentBounds.offset(columns: 0, rows: 1).offsetSize(columns: 0, rows: -1)
        }
        //TODO: Here we could set the color mode and draw all the background and then set it back
        
        let drawnSize = DrawSize(width: bounds.width, height: bounds.height)
        needsRedraw = .no(cachedSize: drawnSize)
        return drawnSize
    }
    
    func getMinimumSize() -> DrawSize {
        let sizes = children.map{$0.drawable}.map{$0.getMinimumSize()}
        let height = sizes.map{$0.height}.reduce(0,+)
        let width = sizes.map{$0.width}.max() ?? 0
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
