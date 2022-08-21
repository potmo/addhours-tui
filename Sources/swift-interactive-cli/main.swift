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

let rootView = BindingRootView(window: terminal.window, writer: terminal.writer) {
    HSplit(ratio: 0.5,
           left: {
        BindableVStack{
            BindableStyledText(text: "Other side", style: .color(.ansi(.cyan)).backgroundColor(.ansi(.brightBlack)))
            BindableHStack{
                BindableStyledText(text: "------------------LEFT")
                BoundEscaper()
                BindableStyledText(text: "RIGHT-----------------")
            }
            
            ScrollList {
                for i in 1..<10 {
                    Expandable(title: "Number \(i)") {
                        for j in 1..<10 {
                            BindableStyledText(text: "item \(j)", style: .backgroundColor(.ansi(.white)).color(.black))
                        }
                    }
                }
            }
            
        }
    },
           right: {
        BindableVStack{
            BindableTable(headers: [BindableStyledText(text: "One"), BindableStyledText(text: "Two"), BindableStyledText(text: "Three")],
                          rows: [[BindableStyledText(text:"1"), BindableStyledText(text: "2"), BindableStyledText(text: "3")],
                                 [BindableStyledText(text:"4"), BindableStyledText(text: "5"), BindableStyledText(text: "5")],
                                 [BindableStyledText(text:"7"), BindableStyledText(text: "8"), BindableStyledText(text: "9")],
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
