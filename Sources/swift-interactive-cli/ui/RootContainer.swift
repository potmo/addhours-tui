import Foundation


class RootContainer {
    
    fileprivate var drawableChildren: [DrawableChildren]
    fileprivate let screenWriter: ScreenWriter
    
    init(screenWriter: ScreenWriter) {
        self.screenWriter = screenWriter
        self.drawableChildren = []
        terminal.mouse.commands.subscribe(with: self, callback: self.mouseUpdate)
    }
    
    fileprivate func mouseUpdate(mouse: Mouse) {
        // draw everything so that we have accurate bounds
        self.draw(cause: .mouse(event: mouse))
    }
    
    //TODO: This should be local bounds
    func addChild(child: Drawable, bounds: GlobalDrawBounds) {
        drawableChildren.append(DrawableChildren(drawable: child, bounds: bounds))
    }
    
    func draw(cause: DrawCause) {
        
        terminal.cursor.savePosition()
        terminal.cursor.hide()
        // TODO: offset local bounds to global. Now we are expecting this view to be top left fullscreen
        // no layout so we skip the stuff here
        for child in drawableChildren {
            _ = child.drawable.draw(cause: cause, in: child.bounds, with: screenWriter, horizontally: .fill, vertically: .fill)
        }
        terminal.cursor.show()
        terminal.cursor.restorePosition()
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: Int(terminal.window.width), height: Int(terminal.window.height))
    }
    
    struct DrawableChildren {
        let drawable: Drawable
        let bounds: GlobalDrawBounds
    }
}

