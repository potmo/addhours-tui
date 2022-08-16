import Foundation
import Signals

class TerminalCursor {
    
    public let commands = Signal<Cursor>()
    
    fileprivate let writer: TerminalWriter
    
    init(writer: TerminalWriter) {
        self.writer = writer
    }
    
    func moveUp(by value: Int = 1) {
        writer.moveCursorUp(by: value)
    }
    
    func moveDown(by value: Int = 1) {
        writer.moveCursorDown(by: value)
    }
    
    func moveLeft(by value: Int = 1) {
        writer.moveCursorLeft(by: value)
    }
    
    func moveRight(by value: Int = 1) {
        writer.moveCursorRight(by: value)
    }
    
    func moveToHome() {
        writer.moveCursorToHome()
    }
    
    func moveTo(column: Int, row: Int) {
        writer.moveCursorTo(column: column, row: row)
    }
    
    func requestPosition() {
        writer.requestCursorPosition()
    }
    
    func savePosition() {
        writer.saveCursorPosition()
    }
    
    func hide() {
        writer.hideCursor()
    }
    
    func show() {
        writer.showCursor()
    }
    
    func restorePosition() {
        writer.restoreCursorPosition()
    }
    
}
