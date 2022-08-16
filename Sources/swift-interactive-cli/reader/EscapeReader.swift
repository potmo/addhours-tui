import Foundation

class EscapeReader {
    
    private let brackededReader: CSIReader
    init( brackededReader: CSIReader) {
        self.brackededReader = brackededReader
    }
    
    func read(standardIn: ANSITerminalReader, previous: [KeyCode]) -> ReadResult {
        
        let char = standardIn.read()
        let sequence = previous + [char]
        switch char {
            case "[":
                return brackededReader.read(standardIn: standardIn, previous: sequence)
            default:
                return .meta(.unknownEscapeSequence(sequence))
        }
    }
}
