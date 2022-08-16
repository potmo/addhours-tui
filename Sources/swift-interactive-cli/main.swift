import Foundation
let terminal = Terminal()

let rootView = BindingRootView(window: terminal.window, screenWriter: terminal.screenWriter) {
    HSplit(ratio: 0.5,
           left: {
        BindableVStack{
            BindableStyledText(text: "Other side", style: .color(.ansi(.cyan)).backgroundColor(.ansi(.brightBlack)))
        }
    },
           right: {
        BindableVStack{
            BindableStyledText(text: "First line", style: .color(.ansi(.red)).backgroundColor(.ansi(.brightBlack)))
            BindableStyledText(text: "Second line", style: .color(.ansi(.green)).backgroundColor(.ansi(.brightBlack)))
            BindableStyledText(text: "Third line", style: .color(.ansi(.blue)).backgroundColor(.ansi(.brightBlack)))
            TestDynamicText().inVStack()
            BindableStyledText(text: "Fourth line", style: .color(.ansi(.yellow)).backgroundColor(.ansi(.brightBlack)))
        }
    }
    )
}

terminal.keyboard.commands.subscribe(with: terminal) { key in
    
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

terminal.window.sizeChanges.subscribe(with: terminal) { _ in
    terminal.window.clearScreen()
    rootView.update(with: UpdateCause.none, forceDraw: true)
}

terminal.window.clearScreen()
rootView.update(with: UpdateCause.none, forceDraw: true)
terminal.writer.flushBuffer()

RunLoop.main.run()
