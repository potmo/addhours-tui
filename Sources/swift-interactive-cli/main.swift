import Foundation
let terminal = Terminal()

let viewForLog = Log()
let log: Logger = viewForLog

func fatalError(_ message: String, file: String = #file, line: Int = #line) -> Never {
    terminal.terminate(exit: false)
    print(message)
    print("in: \(file) line: \(line)")
    
    Thread.callStackSymbols.forEach{print($0)}
    exit(1)
}

let rootView = TerminalRootView(window: terminal.window, writer: terminal.writer) {
    HSplit(ratio: 0.5,
           left: {
        VStack{
            Text(text: "Other side", style: .color(.ansi(.cyan)).backgroundColor(.ansi(.brightBlack)))
            
            HStack{
                Text(text: "------------------LEFT")
                BoundEscaper()
                Text(text: "RIGHT-----------------")
            }
            
            ScrollList {
                for i in 1..<10 {
                    Expandable(title: "Number \(i)") {
                        for j in 1..<10 {
                            Text(text: "item \(j)", style: .backgroundColor(.ansi(.white)).color(.black))
                        }
                    }
                }
                
                Expandable(title: "Number extra") {
                    for j in 1..<3 {
                        Expandable(title: "Number extra \(j)") {
                            for k in 1..<4 {
                                Text(text: "item \(k)", style: .backgroundColor(.ansi(.white)).color(.black))
                            }
                        }
                    }
                }
            }
             
            
        }
    },
           right: {
        VStack{
            Table(headers: [Text(text: "One"), Text(text: "Two"), Text(text: "Three")],
                          rows: [[Text(text:"1"), Text(text: "2"), Text(text: "3")],
                                 [Text(text:"4"), Text(text: "5"), Text(text: "5")],
                                 [Text(text:"7"), Text(text: "8"), Text(text: "9")],
                                ])
            TestDynamicText().inVStack()
            Timeline()
            viewForLog
        }
    }
    )
}

terminal.keyboard.commands.subscribe(with: terminal) { key in

    log.log("\(key)")
    
    switch key {
        case .pressKey(code: "q", _):
            terminal.terminate()
            
        case .pressKey(code: .upArrow, _):
            terminal.cursor.moveUp()
        case .pressKey(code: .downArrow, _):
            terminal.cursor.moveDown()
        case .pressKey(code: .leftArrow, _):
            terminal.cursor.moveLeft()
        case .pressKey(code: .rightArrow, _):
            terminal.cursor.moveRight()
            
        default:
            break
    }
    
    rootView.update(with: .keyboard(key))
}


terminal.mouse.commands.subscribe(with: terminal) { mouse in
    rootView.update(with: .mouse(mouse))
}

terminal.meta.commands.subscribe(with: terminal) { meta in
    switch meta {
        case .invalidEscapeSequence(let keys, let message):
            log.error("Invalid escape sequence.\n\(message)\n\(keys)")
        case .unknownEscapeSequence(let keys):
            log.error("Unknown escape sequence\n\(keys)")
    }
}

terminal.window.commands.subscribe(with: terminal) { window in
    switch window {
        case .sizeChange(let width, let height):
            log.log("window size changed: \(width), \(height)")
            terminal.window.clearScreen()
            rootView.update(with: UpdateCause.none, forceDraw: true)
        case .focusIn:
            log.log("window got focus")
        case .focusOut:
            log.log("window lost focus")
    }
    
}

terminal.window.clearScreen()
rootView.update(with: UpdateCause.none, forceDraw: true)
terminal.writer.flushBuffer()

RunLoop.main.run()
