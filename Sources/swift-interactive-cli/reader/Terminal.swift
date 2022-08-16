import Foundation
import Combine
import Signals

class Terminal {
    fileprivate let standardIn: StandardInReader
    fileprivate let ansiStandardInReader: ANSITerminalReader
    fileprivate let mouseReader: MouseReader
    fileprivate let cursorPositionReader: CursorPositionReader
    fileprivate let brackededReader: CSIReader
    fileprivate let csiuReader: CSIuReader
    fileprivate let escapeReader: EscapeReader
    fileprivate let rawReader: RawReader
    fileprivate let reader: TerminalReader
    
    let commands = Signal<ReadResult>()
    let window: TerminalWindow
    let cursor: TerminalCursor
    let writer: TerminalWriter
    let mouse: TerminalMouse
    let keyboard: TerminalKeyboard
    let screenWriter: ScreenWriter
    
    private func start() {
        window.enterAlternativeScreenMode()
        mouse.startListening()
        writer.enterProgressiveEnhancementKeyMode()
        //writer.enterAllowOtherKeysMode()
        writer.disableWraparound()
    }
    
    func terminate() {
        window.clearScreen()
        mouse.stopListening()
        writer.enableWraparound()
        writer.exitProgressiveEnhancementKeyMode()
        //writer.exitAllowOtherKeysMode()
        window.exitAlternativeScreenMode()
        standardIn.terminate()
        writer.flushBuffer()
        
        
        exit(0)
    }
    
    init() {
        
        standardIn = StandardInReader()
        ansiStandardInReader = ANSITerminalReader(standardIn: standardIn)
        mouseReader = MouseReader()
        cursorPositionReader = CursorPositionReader()
        csiuReader = CSIuReader()
        brackededReader = CSIReader(mouseReader: mouseReader,
                                    cursorPositionReader: cursorPositionReader,
                                    csiuReader: csiuReader)
        escapeReader = EscapeReader(brackededReader: brackededReader)
        rawReader = RawReader(escapeReader: escapeReader)
        reader = TerminalReader()
        writer = TerminalWriter()
        screenWriter = ScreenWriter(writer: writer)
        
        
        window = TerminalWindow(writer: writer)
        cursor = TerminalCursor(writer: writer)
        mouse = TerminalMouse(writer: writer)
        keyboard = TerminalKeyboard()
        
        // Spin up a thread reading from standard in
        DispatchQueue.global(qos: .userInteractive).async {
            while(true){
                let result = self.rawReader.read(standardIn: self.ansiStandardInReader)
                self.commands.fire(result)
                switch result {
                    case .mouse(let mouse):
                        self.mouse.commands.fire(mouse)
                    case .cursor(let cursor):
                        self.cursor.commands.fire(cursor)
                    case .key(let key):
                        self.keyboard.commands.fire(key)
                    case .window(_):
                    //TODO: implement
                        continue
                    case .meta(_):
                        //TODO: implement
                        continue
                }
            }
        }
        
        self.start()
    }
    
    func writeRaw(data: String, flush: Bool = false) {
        writer.printRaw("BEL", flush: flush)
    }

}
