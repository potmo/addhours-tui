import Foundation

class ANSITerminalReader {
    
    let standardIn: StandardInReader
    init(standardIn: StandardInReader) {
        self.standardIn = standardIn
    }

    func read() -> KeyCode {
        let char = standardIn.readUnicodeScalar()
        // TODO: We also got modifiers here that we might want to look into
        return KeyCode.from(code: char).0
    }
}

