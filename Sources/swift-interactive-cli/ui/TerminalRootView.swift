import Foundation

class TerminalRootView {
    
    private var child: Drawable
    private let window: TerminalWindow
    private let writer: TerminalWriter
    
    init (window: TerminalWindow, writer: TerminalWriter, rootChildMaker: ()->Drawable) {
        self.child = rootChildMaker()
        self.window = window
        self.writer = writer
    }
    
    func update(with cause: UpdateCause, forceDraw: Bool = false) {
        
        let bounds = GlobalDrawBounds(column: 1, row: 1, width: window.width, height: window.height)
        
        var redraw = child.update(with: cause, in: bounds)
        if forceDraw {
            redraw = .yes
        }
        
        switch redraw {
            case .yes:
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
            case .no:
                break
        }
        
       
        
    }
    
}
