import Foundation

class CSIuReader {
    func read(previous: [KeyCode], command: [KeyCode]) -> ReadResult {
        // drop last since that is the "u"
        let charsCommand = command.map{ $0.string }.dropLast()
        
        //TODO: handle reported u-mode flags
        if charsCommand[safe: 0] == "?" {
            return .meta(.invalidEscapeSequence(previous, message: "got the u-flags but we don't care right now"))
        }
        
        let command = charsCommand.joined(separator: "")
        let parameters = command.split(separator: ";").map{String($0)}
        
        // the fill pattern looks like this:
        // CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
        // https://sw.kovidgoyal.net/kitty/keyboard-protocol/
        
        guard let unicodeKeyCode = parameters[safe: 0] else {
            return .meta(.invalidEscapeSequence(previous, message: "a key code field is mandatory in csi u sequence but was missing"))
        }
        let modifiers = parameters[safe: 1]
        /*
            TODO: This can be implemented
            let textAsCodepoints = parameters[safe: 2]
         */
        
        let keycodeSubFields = unicodeKeyCode.split(separator: ":").map(String.init)
      
        guard let field1 = keycodeSubFields[safe: 0] else {
            return .meta(.invalidEscapeSequence(previous, message: "not possible to get first sub parameter from unicode key code"))
        }
        
        // this value will always be the lowercase version
        guard let unicodeKeyCode = Int(field1) else {
            return .meta(.invalidEscapeSequence(previous, message: "not possible to parse the unicode keycode"))
        }
        
        /*
            TODO: This can be implemented
            let alternateKeyCode: Int? // if `alternate key reporting` is on. Contains the shifted version
            if let field2 = keycodeSubFields[safe: 1] {
                alternateKeyCode = Int(field2)
            }
         */
        
        
        /*
            TODO: This can be implemented
            let baseLayoutKey: Int? // if `alternate key reporting` is on. Contains the corresponding to the physical key in the standard PC-101 key layout
            if let field3 = keycodeSubFields[safe: 2] {
                baseLayoutKey = Int(field3)
            }
         */
        
        
        var keyModifiers: Modifiers = []
        var eventType: String = "1" // default to 1
        
        if let modifiersSubFields = modifiers?.split(separator: ":").map(String.init) {
            if let modifierFlags = modifiersSubFields[safe: 0], let parsedFlags = Int(modifierFlags) {
                // the modifiers are shifted + 1 so shift it back
                let flags = parsedFlags - 1
                keyModifiers = Modifiers(rawValue: flags)
            }
        
            // 1 == press
            // 2 == repeat
            // 3 == release
            eventType = modifiersSubFields[safe: 1] ?? "1" // deafult to 1
        }
        
        guard let intEventType = Int(eventType), let castEventType = KeyEvent(rawValue: intEventType) else {
            return .meta(.invalidEscapeSequence(previous, message: "event type needs to be one of [1,2,3] but was \(eventType)"))
        }
        
        /*
            TODO: This can be implemented
            let unicodeCodepoints = textAsCodepoints?.split(separator: ":").map(String.init).map(Int.init)
         */
        let (keyCode, _) = KeyCode.from(code: unicodeKeyCode)
       
        switch castEventType {
            case .press:
                return .key(.pressKey(code: keyCode, modifers: keyModifiers))
            case .repeat:
                return .key(.repeatKey(code: keyCode, modifers: keyModifiers))
            case .release:
                return .key(.releaseKey(code: keyCode, modifers: keyModifiers))
        }
        
    }
}
