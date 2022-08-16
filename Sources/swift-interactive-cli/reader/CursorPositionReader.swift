import Foundation

class CursorPositionReader {
    
    func read(previous: [KeyCode], command: [KeyCode]) -> ReadResult {
        // drop last since that is the "R"
        let charsCommand = command.map{ $0.string }.dropLast()
        
        let command = charsCommand.joined(separator: "")
        let parameters = command.split(separator: ";")
        
        guard parameters.count == 2 else {
            return .meta(.invalidEscapeSequence(previous, message: "expected cursor position command to have two parameters"))
        }
        
        guard let column = Int(parameters[0]) else {
            return .meta(.invalidEscapeSequence(previous, message: "could not parse the column parameter of cursor position"))
        }
        
        guard let row = Int(parameters[1]) else {
            return .meta(.invalidEscapeSequence(previous, message: "could not parse the row parameter of cursor position"))
        }
        
        return .cursor(.position(column: column, row: row))
    }
    
}
