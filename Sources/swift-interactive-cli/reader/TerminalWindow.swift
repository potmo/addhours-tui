import Foundation
import Signals

class TerminalWindow {
    
    let sizeChanges = Signal<(Int, Int)>()
    fileprivate var _width: Int = 0
    fileprivate var _height: Int = 0
    var width: Int {
        return _width
    }
    var height: Int {
        return _height
    }
    fileprivate var observer: NSObjectProtocol!
    fileprivate let writer: TerminalWriter
    
    
    init(writer: TerminalWriter) {
        
        self.writer = writer
        
        // figure out window size
        var size = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0 {
            let windowWidth = Int(size.ws_col)
            let windowHeight = Int(size.ws_row)
            self._width = windowWidth
            self._height = windowHeight
            self.sizeChanges.fire((windowWidth, windowHeight))
        }
        
        
        // trap the SIGWINCH signal. To avoid capturing variables into the closure
        // that for some reason raises an error due to C-interoperability we use the Notification center instead
        let signalReceived: (Notification) -> Void = { notification in
            //NotificationCenter.default.removeObserver(self.observer!)
            
            guard let _ = notification.object as? Int else {
                return
            }
            
            var size = winsize()
            if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0 {
                let windowWidth = Int(size.ws_col)
                let windowHeight = Int(size.ws_row)
                self._width = windowWidth
                self._height = windowHeight
                self.sizeChanges.fire((windowWidth, windowHeight))
            }
        }
        
        self.observer = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SIGNWINCH"), object: nil, queue: OperationQueue.main, using: signalReceived)
        
        signal(SIGWINCH) { signal in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SIGNWINCH"), object: signal)
        }
        

    }
    
    func clearScreen() {
        writer.clearScreen()
    }
    
    
    func clearFromCursorToEndOfScreen() {
        writer.clearFromCursorToEndOfScreen()
    }
    
    func clearFromCursorToBeginningOfScreen() {
        writer.clearFromCursorToBeginningOfScreen()
    }
    
    func clearFromCursorToEndOfLine() {
        writer.clearFromCursorToEndOfLine()
    }
    
    func clearFromCursorToStartOfLine() {
        writer.clearFromCursorToStartOfLine()
    }
    
    func clearEntireLine() {
        writer.clearEntireLine()
    }
    
    
    func enterAlternativeScreenMode() {
        writer.enterAlternativeScreenMode()
    }
    
    func exitAlternativeScreenMode() {
        writer.exitAlternativeScreenMode()
    }

}
