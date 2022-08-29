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
    
    let commands = Signal<ReadResult>()
    let window: TerminalWindow
    let cursor: TerminalCursor
    let writer: TerminalWriter
    let mouse: TerminalMouse
    let keyboard: TerminalKeyboard
    let meta: TerminalMeta
    let screenWriter: ScreenWriter
    
    
    private func start() {
        window.enterAlternativeScreenMode()
        mouse.startListening()
        writer.enterProgressiveEnhancementKeyMode()
        writer.enterModifyOtherKeysMode()
        writer.disableWraparound()
    }
    
    func terminate(exit terminate: Bool = true) {
        window.clearScreen()
        mouse.stopListening()
        writer.enableWraparound()
        writer.exitProgressiveEnhancementKeyMode()
        writer.exitModifyOtherKeysMode()
        window.exitAlternativeScreenMode()
        standardIn.terminate()
        writer.flushBuffer()
        
        
        if terminate {
            exit(0)
        }
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
        writer = TerminalWriter()
        screenWriter = ScreenWriter(writer: writer)
        
        
        window = TerminalWindow(writer: writer)
        cursor = TerminalCursor(writer: writer)
        mouse = TerminalMouse(writer: writer)
        keyboard = TerminalKeyboard()
        meta = TerminalMeta()

        
        // Spin up a thread reading from standard in
        DispatchQueue.global(qos: .userInteractive).async {
            while(true){
                let result = self.rawReader.read(standardIn: self.ansiStandardInReader)
                DispatchQueue.main.async {
                    self.commands.fire(result)
                    switch result {
                        case .mouse(let mouse):
                            self.mouse.commands.fire(mouse)
                        case .cursor(let cursor):
                            self.cursor.commands.fire(cursor)
                        case .key(let key):
                            self.keyboard.commands.fire(key)
                        case .window(let window):
                            self.window.commands.fire(window)
                        case .meta(let meta):
                            self.meta.commands.fire(meta)
                    }
                }
            }
        }
        
        self.start()
    }

}
