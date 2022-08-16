import Foundation

enum ReadResult {
    case key(_: Key)
    case cursor(_ : Cursor)
    case mouse(_ : Mouse)
    case window(_ : Window)
    case meta(_: Meta)
}

enum KeyEvent: Int {
    case press = 1
    case `repeat` = 2
    case release = 3
}

enum Cursor:Equatable {
    case position(column: Int, row: Int)
}

enum Mouse: Equatable {
    case leftButtonUp(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case leftButtonDown(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case rightButtonUp(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case rightButtonDown(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case middleButtonUp(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case middleButtonDown(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    
    case moveLeftButtonDown(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case moveMiddleButtonDown(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case moveRightButtonDown(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    case move(x: Int, y: Int, shift: Bool, control: Bool, alt: Bool)
    
    case scrollUp(x: Int, y: Int)
    case scrollDown(x: Int, y: Int)
}

enum Window: Equatable {
    case focusIn
    case focusOut
}

enum Meta:Equatable {
    case unknownEscapeSequence(_: [KeyCode])
    case invalidEscapeSequence(_: [KeyCode], message: String)
}

enum KeyCode: Equatable, CustomStringConvertible {
    
    enum FunctionKey: Character {
        case leftArrow = "←"
        case rightArrow = "→"
        case upArrow = "↑"
        case downArrow = "↓"
        case pageUp = "⇞"
        case pageDown = "⇟"
        case home = "↖"
        case end = "↘"
        case clear = "⌧"
        case backspace = "⌫"
        case enter = "↵"
        case bell = "⍾"
        case escape = "⎋"
        case tab = "⇥"
        case backTab = "⇤"
        case space = "␣"
        case delete = "␥"
        
        case command = "⌘"
        case control = "⌃"
        case alt = "⌥"
        case shift = "⇧"
        case capsLock = "⇪"
        case eject = "⏏"
    }
    
    case code(_ unicodeScalar: Int)
    case functionKey(_:FunctionKey)
    
    static func from(code: Int) -> (KeyCode, Modifiers) {
        switch code {
            case 0x1B: return (.functionKey(.escape), [])
            case 0x07: return (.functionKey(.bell), [])
            case 10: return (.functionKey(.enter), [])
            case 0x8: return (.functionKey(.backspace), [])
            case 0x7f: return (.functionKey(.delete), [])
            case 0x9: return (.functionKey(.tab), [])
            case 0x20: return (.functionKey(.space), [])
            default: return (.code(code), []) // TODO: Figure out shift modifiers?
        }
    }
    
    var string: String {
        switch self {
            case .functionKey(let key):
                return String(key.rawValue)
            case .code(let code):
                return String(Character(UnicodeScalar(code)!))
        }
    }
    
    public var description: String {
        return string
    }
    
    
    static func ~= (pattern: Int, value: KeyCode) -> Bool {
        
        switch value {
            case .code(let unicodeScalar):
                return unicodeScalar == pattern
            case .functionKey:
                return false
        }
    }
    
    static func ~= (pattern: Character, value: KeyCode) -> Bool {
        guard let unicodeScalar = pattern.unicodeScalars.first?.value else {
            return false
        }
        
        switch value {
            case .code(let code):
                return code == unicodeScalar
            case .functionKey:
                return false
        }
    }
    
    static func ~= (pattern: FunctionKey, value: KeyCode) -> Bool {
        switch value {
            case .code:
                return false
            case .functionKey(let key):
                return key == pattern
        }
    }
    
}

struct Modifiers: OptionSet, Equatable {
    let rawValue: Int
    
    static let shift = Modifiers(rawValue: 1 << 0)
    static let alt = Modifiers(rawValue: 1 << 1)
    static let ctrl = Modifiers(rawValue: 1 << 2)
    static let `super` = Modifiers(rawValue: 1 << 3)
    static let hyper = Modifiers(rawValue: 1 << 4)
    static let meta = Modifiers(rawValue: 1 << 5)
    static let capsLock = Modifiers(rawValue: 1 << 6)
    static let numLock = Modifiers(rawValue: 1 << 7)
}

enum Key: Equatable {
    case pressKey(code: KeyCode, modifers: Modifiers = [])
    case repeatKey(code: KeyCode, modifers: Modifiers = [])
    case releaseKey(code: KeyCode, modifers: Modifiers = [])
}



