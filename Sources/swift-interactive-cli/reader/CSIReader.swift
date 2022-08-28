import Foundation

class CSIReader {
    
    private let mouseReader: MouseReader
    private let cursorPositionReader: CursorPositionReader
    private let csiuReader: CSIuReader
    
    init(mouseReader: MouseReader, cursorPositionReader: CursorPositionReader, csiuReader: CSIuReader) {
        self.mouseReader = mouseReader
        self.cursorPositionReader = cursorPositionReader
        self.csiuReader = csiuReader
    }
    
    func read(standardIn: ANSITerminalReader, previous: [KeyCode]) -> ReadResult {
        var sequence = previous
        // to know what command we need to read until one of the stop chars appear
    
        var SCIsequence:[KeyCode] = []
        while true {
            
            let char = standardIn.read()
            sequence += [char]
            SCIsequence += [char]
            
            switch char {
                    //TODO: We should read the modifier buttons as well
                    // this can be done by this: https://www.leonerd.org.uk/hacks/fixterms/
                case "A":
                    return .key(.pressKey(code: .functionKey(.upArrow), modifers: []))
                case "B":
                    return .key(.pressKey(code: .functionKey(.downArrow), modifers: []))
                case "C":
                    return .key(.pressKey(code: .functionKey(.rightArrow), modifers: []))
                case "D":
                    return .key(.pressKey(code: .functionKey(.leftArrow), modifers: []))
                    // case F: END
                    //case H: Home
                    //case P,Q,R,S: F1, F2, F3, F4
                case "M": // mouse up
                    fallthrough
                case "m": // mouse down
                    return mouseReader.read(previous: sequence, command: SCIsequence)
                case "O":
                    return .window(.focusOut)
                case "I":
                    return .window(.focusIn)
                case "R":
                    return cursorPositionReader.read(previous: sequence, command: SCIsequence)
                case "Z":
                    return .key(.pressKey(code: .functionKey(.space), modifers: [.shift]))
                case "u":
                    return csiuReader.read(previous: sequence, command: SCIsequence)
                case // let some characters that we know will be part of the parameters pass but nothing else
                    // otherwise we might end up in a never ending loop here (or that a valid SCI comes
                    // after but is interpreted as invalid due to the previous garbage left begind in the input
                        ";",
                        ":",
                        "]",
                        "[",
                        "<",
                        "?",
                        "0",
                        "1",
                        "2",
                        "3",
                        "4",
                        "5",
                        "6",
                        "7",
                        "8",
                        "9":
                    continue
                default:
                    return .meta(.unknownEscapeSequence(sequence))
            }
            
        }
    }
}
