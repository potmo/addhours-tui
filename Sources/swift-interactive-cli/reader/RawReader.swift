import Foundation

class RawReader {
    
    private let escapeReader: EscapeReader
    
    init(escapeReader: EscapeReader){
        self.escapeReader = escapeReader
    }
    
    func read(standardIn: ANSITerminalReader) -> ReadResult {
        
        // TODO: Here is a great list of all escape codes
        // https://docs.google.com/spreadsheets/d/19W-lXWS9jYwqCK-LwgYo31GucPPxYVld_hVEcfpNpXg/edit#gid=433919454
        
        let char = standardIn.read()
        switch char {
            case .escape:
                return escapeReader.read(standardIn: standardIn, previous: [char])
            default:
                return .key(.pressKey(code: char, modifers: []))
                
        }
    }
}
