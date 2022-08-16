import Foundation

class BindingRootView {
    
    private var child: BoundDrawable
    private let window: TerminalWindow
    private let screenWriter: ScreenWriter
    init (window: TerminalWindow, screenWriter: ScreenWriter, rootChildMaker: ()->BoundDrawable) {
        self.child = rootChildMaker()
        self.window = window
        self.screenWriter = screenWriter
    }
    
    func update(with cause: UpdateCause, forceDraw: Bool = false) {
        
        let bounds = GlobalDrawBounds(column: 1, row: 1, width: window.width, height: window.height)
        
        var redraw = child.update(with: cause, in: bounds)
        if forceDraw {
            redraw = .yes
        }
        
        
        switch redraw {
            case .yes:
                let drawBounds = child.getDrawBounds(given: bounds, with: Arrange(.fill, .fill))
                _ = child.draw(with: screenWriter, in: drawBounds, force: forceDraw)
            case .no:
                break
        }
        
        
        screenWriter.print("hello123456789", column: 190, row: 30)
        screenWriter.print("drew: \(redraw)", column: 190, row: 31)
        
        
        screenWriter.flush()
        
    }
    
}
