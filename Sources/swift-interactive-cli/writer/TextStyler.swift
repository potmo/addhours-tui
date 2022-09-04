import Foundation

extension StyledString: ExpressibleByStringLiteral {
    
    init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }
}
protocol ANSIEscapedString {
    func unescapedCount() -> Int
    func escapedString() -> String
    func truncate(_ maxLength: Int) -> Self
    func leftpad(upTo: Int, with: String) -> ANSIEscapedString
}

extension String: ANSIEscapedString {
    func leftpad(upTo: Int, with: String) -> ANSIEscapedString {
        if upTo <= 0 {
            return self
        }
        
        let times = (upTo - self.count) / with.count
        let padding = Array(repeating: with, count: times).joined()
        return padding + self
    }
    
    func unescapedCount() -> Int {
        return self.count
    }
    func escapedString() -> String {
        return self
    }
    
    func truncate(_ maxLength: Int) -> String {
        let result:String = String(prefix(max(0,maxLength)))
        return result
    }
}

extension String {
    func bold(_ bold: Bool = true) -> StyledString {
        return StyledString(string: self).bold(bold)
    }
    func faint(_ faint: Bool = true) -> StyledString {
        return StyledString(string: self).faint(faint)
    }
    
    func italic(_ italic: Bool = true) -> StyledString {
        return StyledString(string: self).italic(italic)
    }
    
    func underline(_ underline: Bool = true) -> StyledString {
        return StyledString(string: self).underline(underline)
    }
    
    func blinking(_ blinking: Bool = true) -> StyledString {
        return StyledString(string: self).blinking(blinking)
    }
    
    func strikethrough(_ strikethrough: Bool = true) -> StyledString {
        return StyledString(string: self).strikethrough(strikethrough)
    }
    
    func color(_ color: Color) -> StyledString {
        return StyledString(string: self).color(color)
    }
    
    func backgroundColor(_ backgroundColor: Color) -> StyledString {
        return StyledString(string: self).backgroundColor(backgroundColor)
    }
    
    func with(style: TextStyle) -> StyledString {
        return StyledString(string: self, style: style)
    }
}

struct StyledStringCollection: ANSIEscapedString {
  
    fileprivate let strings: [StyledString]
    
    static func + (left: StyledStringCollection, right: String) -> StyledStringCollection {
        return StyledStringCollection(strings: left.strings + [StyledString(string: right)])
    }
    
    static func + (left: String, right: StyledStringCollection) -> StyledStringCollection {
        return StyledStringCollection(strings: [StyledString(string: left)] + right.strings)
    }
    
    static func + (left: StyledStringCollection, right: StyledString) -> StyledStringCollection {
        return StyledStringCollection(strings: left.strings + [right])
    }
    
    static func + (left: StyledString, right: StyledStringCollection) -> StyledStringCollection {
        return StyledStringCollection(strings: [left] + right.strings)
    }
    
    static func + (left: StyledStringCollection, right: StyledStringCollection) -> StyledStringCollection {
        return StyledStringCollection(strings: left.strings + right.strings)
    }
    
    func unescapedCount() -> Int {
        return strings.reduce(0) { $0 + $1.unescapedCount() }
    }
    
    func escapedString() -> String {
        return strings.reduce("") { $0 + $1.escapedString() }
    }
    
    func truncate(_ maxLength: Int) -> StyledStringCollection {
        if self.unescapedCount() <= maxLength {
            return self
        }

        let overflow = self.strings.enumerated().reduce((0, Optional<Int>.none)){
            let total = $0.0
            if let stoppedIndex = $0.1 {
                return (total, stoppedIndex)
            }
            
            let current = total + $1.element.unescapedCount()
            if current > maxLength {
                return (current, $1.offset)
            } else {
                return (current, nil)
            }
        }
        
        guard let overflowIndex = overflow.1 else {
            fatalError("it should have overflowed but cannot find where")
        }
        
        let charsInOtherStrings = strings[0..<overflowIndex].reduce(0){ previous, current in
            return previous + current.unescapedCount()
        }
        
        let charsToSpare = maxLength - charsInOtherStrings
        let truncated = strings[overflowIndex].truncate(charsToSpare)
        
        return StyledStringCollection(strings: Array(strings[0..<overflowIndex]) + [truncated])
    }
    

    func leftpad(upTo: Int, with: String) -> ANSIEscapedString {
        if upTo <= 0 {
            return self
        }
        
        let times = (upTo - self.unescapedCount()) / with.count
        let padding = Array(repeating: with, count: times).joined()
        return padding + self
    }
}

enum Color: Equatable {
    case ansi(_:ANSIColor)
    case rgb(r: UInt8, g: UInt8, b: UInt8)
    case none
        
    static var black: Color { .ansi(.black)}
    static var red: Color { .ansi(.red)}
    static var green: Color { .ansi(.green)}
    static var yellow: Color { .ansi(.yellow)}
    static var blue: Color { .ansi(.blue)}
    static var magenta: Color { .ansi(.magenta)}
    static var cyan: Color { .ansi(.cyan)}
    static var white: Color { .ansi(.white)}
    static var brightBlack: Color { .ansi(.brightBlack)}
    static var brightRed: Color { .ansi(.brightRed)}
    static var brightGreen: Color { .ansi(.brightGreen)}
    static var brightYellow: Color { .ansi(.brightYellow)}
    static var brightBlue: Color { .ansi(.brightBlue)}
    static var brightMagenta: Color { .ansi(.brightMagenta)}
    static var brightCyan: Color { .ansi(.brightCyan)}
    static var brightWhite: Color { .ansi(.brightWhite)}
    
    static func fromRGB(_ value: Int) -> Color {
        let red = UInt8((value >> 16) & 0xFF)
        let green = UInt8((value >> 8) & 0xFF)
        let blue = UInt8(value & 0xFF)
        return Color.rgb(r: red, g: green, b: blue)
    }
    
    func toInt() -> Int {
        switch self {
            case .none:
                return 0x000000
            case .ansi:
                return 0x000000
            case .rgb(let r, let g, let b):
                return (Int(r) << 16) | (Int(g) << 8) | Int(b);
        }
    }
}

enum ANSIColor: Int, Equatable {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
    case brightBlack = 8
    case brightRed = 9
    case brightGreen = 10
    case brightYellow = 11
    case brightBlue = 12
    case brightMagenta = 13
    case brightCyan = 14
    case brightWhite = 15
}

struct TextStyle: Equatable {
    fileprivate let bold: Bool
    fileprivate let faint: Bool
    fileprivate let italic: Bool
    fileprivate let underline: Bool
    fileprivate let blinking: Bool
    fileprivate let strikethough: Bool
    fileprivate let color: Color
    fileprivate let backgroundColor: Color
    
    init(bold: Bool = false,
         faint: Bool = false,
         italic: Bool = false,
         underline: Bool = false,
         blinking: Bool = false,
         strikethough: Bool = false,
         color: Color = Color.none,
         backgroundColor: Color = .none) {
        self.bold = bold
        self.faint = faint
        self.italic = italic
        self.underline = underline
        self.blinking = blinking
        self.strikethough = strikethough
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    var openingEscapeSequence: String {
        var parameters: [String] = []
        bold ? parameters.append("1") : ()
        faint ? parameters.append("2") : ()
        italic ? parameters.append("3") : ()
        underline ? parameters.append("4") : ()
        blinking ? parameters.append("5") : ()
        strikethough ? parameters.append("9") : ()
        // 10 is default so it maybe should be set if all above is false
        switch color {
            case .ansi(let c):
                parameters.append("38")
                parameters.append("5")
                parameters.append("\(c.rawValue)")
            case .rgb(let r, let g, let b):
                parameters.append("38")
                parameters.append("2")
                parameters.append("\(r)")
                parameters.append("\(g)")
                parameters.append("\(b)")
            case .none:
                break
        }
        
        switch backgroundColor {
            case .ansi(let c):
                parameters.append("48")
                parameters.append("5")
                parameters.append("\(c.rawValue)")
            case .rgb(let r, let g, let b):
                parameters.append("48")
                parameters.append("2")
                parameters.append("\(r)")
                parameters.append("\(g)")
                parameters.append("\(b)")
            case .none:
                break
        }
        
        return "\u{001B}[" + parameters.joined(separator: ";") + "m"
    }
    
    var closingEscapeSequence: String {
        return "\u{001B}[0m"
    }
    
    func bold(_ bold: Bool = true) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func faint( _ faint: Bool = true) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func italic( _ italic: Bool = true) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func underline(_ underline: Bool = true) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func blinking( _ blinking: Bool = true) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func strikethrough( _ strikethough: Bool = true) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func color( _ color: Color) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    func backgroundColor(_ backgroundColor: Color) -> TextStyle {
        return TextStyle(bold: bold,
                         faint: faint,
                         italic: italic,
                         underline: underline,
                         blinking: blinking,
                         strikethough: strikethough,
                         color: color,
                         backgroundColor: backgroundColor)
    }
    
    static func color( _ color: Color) -> TextStyle {
        return TextStyle().color(color)
    }
    
    static func backgroundColor( _ backgroundColor: Color) -> TextStyle {
        return TextStyle().backgroundColor(backgroundColor)
    }
    
    static func bold(_ bold: Bool = true) -> TextStyle {
        return TextStyle().bold(bold)
    }
    
    static func underline(_ underline: Bool = true) -> TextStyle {
        return TextStyle().underline(underline)
    }
}

struct StyledString: ANSIEscapedString {
    
    fileprivate let string: String
    fileprivate let style: TextStyle
    
    init(string: String) {
        self.string = string
        self.style = TextStyle()
    }
    
    init(string: String,
         style: TextStyle) {
        self.string = string
        self.style = style
    }
    
    func string(_ string: String) -> StyledString {
        return StyledString(string: string,
                            style: style)
    }
    
    func truncate(_ maxLength: Int) -> StyledString {
        return StyledString(string: String(string.prefix(max(0,maxLength))),
                            style: style)
    }
    
    func bold(_ bold: Bool = true) -> StyledString {
        return StyledString(string: string,
                            style: style.bold(bold))
    }
    
    func faint( _ faint: Bool = true) -> StyledString {
        return StyledString(string: string,
                            style: style.faint(faint))
    }
    
    func italic( _ italic: Bool = true) -> StyledString {
        return StyledString(string: string,
                            style: style.italic(italic))
    }
    
    func underline(_ underline: Bool = true) -> StyledString {
        return StyledString(string: string,
                            style: style.underline(underline))
    }
    
    func blinking( _ blinking: Bool = true) -> StyledString {
        return StyledString(string: string,
                            style: style.blinking(blinking))
    }
    
    func strikethrough( _ strikethough: Bool = true) -> StyledString {
        return StyledString(string: string,
                            style: style.strikethrough(strikethough))
    }
    
    func color( _ color: Color) -> StyledString {
        return StyledString(string: string,
                            style: style.color(color))
    }
    
    func backgroundColor(_ backgroundColor: Color) -> StyledString {
        return StyledString(string: string,
                            style: style.backgroundColor(backgroundColor))
    }
    
    func escapedString() -> String {
        return style.openingEscapeSequence + string + style.closingEscapeSequence
        
    }
    
    static func + (left: StyledString, right: String) -> StyledStringCollection {
        return StyledStringCollection(strings: [left, StyledString(string: right)])
    }
    
    static func + (left: StyledString, right: StyledString) -> StyledStringCollection {
        return StyledStringCollection(strings: [left, right])
    }
    
    static func + (left: String, right: StyledString) -> StyledStringCollection {
        return StyledStringCollection(strings: [StyledString(string: left), right])
    }
    
    func unescapedCount() -> Int {
        self.string.count
    }
    
    
    func leftpad(upTo: Int, with: String) -> ANSIEscapedString {
        if upTo <= 0 {
            return self
        }
        
        let times = (upTo - self.unescapedCount()) / with.count
        let padding = Array(repeating: with, count: times).joined()
        return padding + self
    } 
}
