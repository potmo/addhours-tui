import Foundation

class MouseReader {

    
    init(){
        
    }
    
    func read(previous:[KeyCode], command: [KeyCode]) -> ReadResult {
        let charsCommand = command.map{ $0.string }
        
        if charsCommand.first != "<" {
            return .meta(.invalidEscapeSequence(previous, message: "expected CSI mouse event to start with <"))
        }
        let stringCommand = charsCommand[1...].joined(separator: "")
        
        let parameters = stringCommand.split(separator: ";")
        
        if parameters.count != 3 {
            return .meta(.invalidEscapeSequence(previous, message: "expected 3 parameters but got \(parameters.count)"))
        }
        guard let flags = Int(parameters[0]) else {
            return .meta(.invalidEscapeSequence(previous, message: "not possible to parse first parameter"))
        }
        
        guard let column = Int(parameters[1]) else {
            return .meta(.invalidEscapeSequence(previous, message: "not possible to parse second parameter"))
        }
        
        guard let row = Int(parameters[2].prefix(parameters[2].count-1)) else {
            return .meta(.invalidEscapeSequence(previous, message: "not possible to parse third parameter"))
        }
        
        guard let mode = parameters[2].last else {
            return .meta(.invalidEscapeSequence(previous, message: "not possible to parse up down mode"))
        }
        
        let mouseButton = flags & 0b11
        let shiftDown = flags & 4 == 4
        let altDown = flags & 8 == 8
        let controlDown = flags & 16 == 16
        let move = flags & 32 == 32
        let scrollUp = flags & 64 == 64
        let scrollDown = flags & 65 == 65
        let release = mode == "m"
        
        switch true {
            case scrollDown:
                return .mouse(.scrollDown(x: column, y: row))
            case scrollUp:
                return .mouse(.scrollUp(x: column, y: row))
            case move:
                switch mouseButton {
                    case 0:
                        return .mouse(.moveLeftButtonDown(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 1:
                        return .mouse(.moveMiddleButtonDown(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 2:
                        return .mouse(.moveRightButtonDown(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 3:
                        return .mouse(.move(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    default:
                        return .meta(.invalidEscapeSequence(previous, message: "mouse move with invalid button: \(mouseButton)"))
                }
            case release:
                switch mouseButton {
                    case 0:
                        return .mouse(.leftButtonUp(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 1:
                        return .mouse(.middleButtonUp(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 2:
                        return .mouse(.rightButtonUp(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    default:
                        return .meta(.invalidEscapeSequence(previous, message: "mouse release with invalid button: \(mouseButton)"))
                }
            case !release:
                switch mouseButton {
                    case 0:
                        return .mouse(.leftButtonDown(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 1:
                        return .mouse(.middleButtonDown(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    case 2:
                        return .mouse(.rightButtonDown(x: column, y: row, shift: shiftDown, control: controlDown, alt: altDown))
                    default:
                        return .meta(.invalidEscapeSequence(previous, message: "mouse down with invalid button: \(mouseButton)"))
                }
            default:
                return .meta(.invalidEscapeSequence(previous, message: "mouse reader ended up where no mouse events are sent"))
        }

    }

}
     
