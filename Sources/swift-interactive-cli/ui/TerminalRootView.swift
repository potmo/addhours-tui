import Foundation

class TerminalRootView {
    
    private var child: Drawable
    private let window: TerminalWindow
    private let writer: TerminalWriter
    
    var paused: Bool = false
    
    
    init (window: TerminalWindow, writer: TerminalWriter, rootChildMaker: ()->Drawable) {
        self.child = rootChildMaker()
        self.window = window
        self.writer = writer
    }
    
    func update(with cause: UpdateCause, forceDraw: Bool = false) {
        
        if paused {
            return
        }
        
        let bounds = GlobalDrawBounds(column: 1, row: 1, width: window.width, height: window.height)
        
        var redraw = child.update(with: cause, in: bounds)
        
        if forceDraw {
            redraw = .yes
        }
        
        //TODO: Here we should probably not redraw every time
        // we could see when we redrew last time and dequeue it so that it doesnt readraw on each key press
        if redraw == .yes {
            writer.beginSynchronizedOutput()
            writer.saveCursorPosition()
            writer.hideCursor()
            writer.moveCursorTo(column: 1, row: 1)
            let virtualCursor = VirtualCursor(column: 1, row: 1)
            let boundsScreenWriter = BoundScreenWriter(writer: writer,
                                                       writeBounds: bounds,
                                                       cursor: virtualCursor)
            
            let drawBounds = child.getDrawBounds(given: bounds, with: Arrange(.fill, .fill))
            _ = child.draw(with: boundsScreenWriter, in: drawBounds, force: forceDraw)
            
            writer.showCursor()
            writer.restoreCursorPosition()
            writer.endSynchronizedOutput()
            writer.flushBuffer()
        }
    
       
        
    }
    
}
