import Foundation

class TextInput: Drawable {
    
    private var boundText: String
    private var cursor: String.Index
    private var focused: Bool = false {
        didSet {
            if !focused {
                self.textChanged(text)
            }
        }
    }
    private var state: MouseState = .normal
    private let textChanged: (_ text: String) -> Void

    // add a space in the end to account for the cursor sitting to the right of the text
    var text: String {
        get {
            return boundText + " "
        }
        
        set {
            boundText = String(newValue.prefix(newValue.count-1))
        }
        
    }
    
    init(text: String, changedCallback: @escaping (_ text: String) -> Void) {
        self.boundText = text
        cursor = text.startIndex
        self.textChanged = changedCallback
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        let padding = Array(repeating: " ", count: bounds.width - text.count).joined(separator: "")
        
        if focused {
            
            let preCursorString = String(text[text.startIndex..<cursor])
            
            let cursorString = String(text[cursor])
            
            let postCursorIndex = min(text.index(after: cursor),  text.endIndex)
            
            let postCursorString = String(text[postCursorIndex..<text.endIndex])
            
            screenWriter.moveTo(bounds.column, bounds.row)
            screenWriter.runWithinStyledBlock(with: .color(.black).backgroundColor(.white)) {
                screenWriter.printLineAtCursor(preCursorString)
            }
            screenWriter.runWithinStyledBlock(with: .color(.white).backgroundColor(.red)) {
                screenWriter.printLineAtCursor(cursorString)
            }
            screenWriter.runWithinStyledBlock(with: .color(.black).backgroundColor(.white)) {
                screenWriter.printLineAtCursor(postCursorString + padding)
            }
            
        } else {
            screenWriter.print(text + padding, with: .color(.black).backgroundColor(.brightBlack), column: bounds.column, row: bounds.row)
        }
        
        
        
        return .drew
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        switch cause {
            case .mouse(let event):
                return updateStateFrom(mouse: event, in: bounds)
            case .keyboard(let event):
                return updateStateFrom(key: event, in: bounds)
            default:
                return .no
        }
    }
    func updateStateFrom(key: Key, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        guard focused else {
            return .no
        }
        
        switch key {
            case .pressKey(code: .leftArrow, _):
                cursor = text.index(cursor, offsetBy: -1, limitedBy: text.startIndex) ?? cursor
                return .yes
            case .pressKey(code: .rightArrow,_):
                cursor = text.index(cursor, offsetBy: 1, limitedBy: text.index(before: text.endIndex)) ?? cursor
                return .yes
            case .pressKey(code: .space, modifers: _):
                insertStringAtCursor(string: " ")
                return .yes
            case .pressKey(code: .enter, modifers: _):
                focused = false
                return .yes
            case .pressKey(code: .backspace, modifers: _):
                fallthrough
            case .pressKey(code: .delete, modifers: _):
                removeCharactersAtCursor()
                return .yes
            case .pressKey(code: let code, modifers: []):
                switch code {
                    case .code(let scalar):
                        let string = String(Character(UnicodeScalar(scalar)!))
                        let ascii = string.filter(\.isASCII)
                        guard !ascii.isEmpty else {
                            return .no
                        }
                        insertStringAtCursor(string: ascii)
                        return .yes
                    case .functionKey:
                        return .no
                }
            default:
                return .no
        }
    }
    
    func insertStringAtCursor(string: String) {
        text = String(text[..<cursor]) + string + String(text[cursor...])
        cursor = text.index(cursor, offsetBy: string.count)
    }
    
    func removeCharactersAtCursor() {
        if cursor == text.startIndex {
            return
        }
        let oneBeforeCursor = text.index(before: cursor)
        text = String(text[..<oneBeforeCursor]) + String(text[cursor...])
        cursor = oneBeforeCursor
    }
    
    func updateStateFrom(mouse: Mouse, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        if state == .normal, case let .move(x, y,_,_,_) = mouse {
            if bounds.contains(x: x,y: y) {
                state = .hovered
                return .yes
            }
        }
        
        if state == .hovered, case let .move(x, y,_,_,_) = mouse {
            if !bounds.contains(x: x,y: y) {
                state = .normal
                return .yes
            }
        }
        
        if focused, state == .normal, case let .leftButtonUp(x, y,_,_,_) = mouse {
            if !bounds.contains(x: x,y: y) {
                focused = false
                return .yes
            }
        }
        
        if state == .hovered, case let .leftButtonDown(x, y,_,_,_) = mouse {
            if bounds.contains(x: x,y: y) {
                state = .pressed
                return .yes
            }else{
                state = .normal
                focused = false
                return .yes
            }
        }
        
        if state == .pressed, case let .leftButtonUp(x, y,_,_,_) = mouse {
            if bounds.contains(x: x,y: y) {
                state = .hovered
                focused = true
                let localPos = max(0,min(x - bounds.column, text.count-1))
                cursor = text.index(text.startIndex, offsetBy: localPos)
            } else {
                focused = false
                state = .normal
            }
            
            return .yes
        }
        
        return .no
    }
    
    func getMinimumSize() -> DrawSize {
        let width = text.prefix(while: {char in !char.isNewline}).count
        return DrawSize(width: width, height: 1)
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: getMinimumSize(), horizontally: arrangeDirective.horizontal, vertically: arrangeDirective.vertical)
    }
    
    enum MouseState {
        case hovered
        case pressed
        case normal
    }
}
