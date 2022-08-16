import Foundation
import Signals

class TerminalMouse {
    public let commands = Signal<Mouse>()
    fileprivate var listening: Bool = false
    fileprivate let writer: TerminalWriter
    
    init(writer: TerminalWriter) {
        self.writer = writer
    }
    
    func startListening() {
        guard !listening else {
            return
        }
        
        writer.startRequestingMousePosition()
        listening = true
    }
    
    func stopListening() {
        guard listening else {
            return
        }
        
        writer.stopRequestingMousePosition()
        listening = false
    }
    
    func toggleListening() {
        if listening {
            stopListening()
        } else {
            startListening()
        }
    }
    
}
