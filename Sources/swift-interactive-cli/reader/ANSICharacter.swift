import Foundation

enum ANSICharacter: Equatable, CustomStringConvertible {
    
    case named(_ name: NamedCharacter)
    case raw(code: Int)
    
    enum NamedCharacter: Int {
        case escape = 0x1B
        case bell = 0x07
        case enter = 10
        case backspace = 127
        case leftBracket = 91
        case rightBracket = 93
        case lessThan = 60
        case period = 46
        case colon = 58
        case semiColon = 59
        case questionMark = 63
        
        case a = 97
        case b = 98
        case c = 99
        case d = 100
        case e = 101
        case f = 102
        case g = 103
        case h = 104
        case i = 105
        case j = 106
        case k = 107
        case l = 108
        case m = 109
        case n = 110
        case o = 111
        case p = 112
        case q = 113
        case r = 114
        case s = 115
        case t = 116
        case u = 117
        case v = 118
        case w = 119
        case x = 120
        case y = 121
        case z = 122
        case å = 229
        case ä = 228
        case ö = 246
        
        case A = 65
        case B = 66
        case C = 67
        case D = 68
        case E = 69
        case F = 70
        case G = 71
        case H = 72
        case I = 73
        case J = 74
        case K = 75
        case L = 76
        case M = 77
        case N = 78
        case O = 79
        case P = 80
        case Q = 81
        case R = 82
        case S = 83
        case T = 84
        case U = 85
        case V = 86
        case W = 87
        case X = 88
        case Y = 89
        case Z = 90
        case Å = 197
        case Ä = 196
        case Ö = 214
    
        case digit_0 = 48
        case digit_1 = 49
        case digit_2 = 50
        case digit_3 = 51
        case digit_4 = 52
        case digit_5 = 53
        case digit_6 = 54
        case digit_7 = 55
        case digit_8 = 56
        case digit_9 = 57
    }
    
    static func from(code: Int) -> ANSICharacter {
        if let name = NamedCharacter(rawValue: code) {
            return ANSICharacter.named(name)
        }
        return ANSICharacter.raw(code: code)
    }
    
    func code() -> Int {
        switch self {
            case .named(let name):
                return name.rawValue
            case .raw(let code):
                return code
        }
    }
    
    func string() -> String {
        let code = self.code()
        let scalar = UnicodeScalar(self.code())
        guard let scalar = scalar else {
            fatalError("not possible to convert \(code) into a unicode scalar")
        }

        return String(scalar)
        //return String(bytes: [UInt8(self.code())], encoding: .utf8)!
    }
    
    public var description: String {
        switch self {
            case .named(let name):
                return "\(name) (\(self.code()))"
            case .raw(let code):
                return "� (\(code))"
        }
    }
    
}

