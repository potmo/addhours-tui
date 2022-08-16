/*
 import Foundation
import AppKit


let terminal = Terminal()

let cursorPosition = StyledText(text: "?,?", style: .color(.ansi(.black)).backgroundColor(.ansi(.white)))
let windowSizeWindow = StyledText(text: "?x?", style: .color( .ansi(.white)).backgroundColor(.ansi(.cyan)))


let mouseLeftMouseStateWindow = StyledText(text: "-", style: .color(.ansi(.black)).backgroundColor(.ansi(.brightRed)))

let mouseMiddleMouseStateWindow = StyledText(text: "-", style: .color(.ansi(.black)).backgroundColor(.ansi(.brightGreen)))
let mouseRightMouseStateWindow = StyledText(text: "-", style: .color(.ansi(.black)).backgroundColor(.ansi(.brightBlue)))

let mousePositionWindow = StyledText(text: "?,?", style: .color(.ansi(.black)).backgroundColor(.ansi(.brightMagenta)))

let button1 = Button(text: "First button")
let button2 = Button(text: "Second Button")
let button3 = Button(text: "Third Button\nTwo lines")
let text1 = StyledText(text: "Red text", style: .color(.ansi(.red)).backgroundColor(.ansi(.brightRed)))
let text2 = StyledText(text: "Green text",style: .color(.ansi(.green)).backgroundColor(.ansi(.brightGreen)))
let text3 = StyledText(text: "Blue text", style: .color(.ansi(.blue)).backgroundColor(.ansi(.brightBlue)))
let text4 = StyledText(text: "Multi Line\nText with long here\nLines\nAnd a super long line that goes beyond and is", style: .color(.ansi(.magenta)).backgroundColor(.ansi(.brightMagenta)))
let vstack = VStack()
vstack.addChild(child: button1)
vstack.addChild(child: button2)
vstack.addChild(child: text1)
vstack.addChild(child: text2)
vstack.addChild(child: text3)
vstack.addChild(child: text4)
vstack.addChild(child: button3)
vstack.addChild(child: mouseLeftMouseStateWindow)
vstack.addChild(child: mouseMiddleMouseStateWindow)
vstack.addChild(child: mouseRightMouseStateWindow)
vstack.addChild(child: mousePositionWindow)
vstack.addChild(child: cursorPosition)
let hstack = HStack()
hstack.addChild(child: StyledText(text: "one", style: .color(.ansi(.red))))
hstack.addChild(child: StyledText(text: "two", style: .color(.ansi(.green))))
hstack.addChild(child: StyledText(text: "three", style: .color(.ansi(.blue))))
vstack.addChild(child: hstack)
let hstack2 = HStack()
hstack2.addChild(child: StyledText(text: "four", style: .color(.ansi(.red))))
hstack2.addChild(child: StyledText(text: "five", style: .color(.ansi(.green))))
hstack2.addChild(child: StyledText(text: "six", style: .color(.ansi(.blue))))
vstack.addChild(child: hstack2)
let rootView = RootContainer(screenWriter: terminal.screenWriter)
rootView.addChild(child: vstack, bounds: GlobalDrawBounds(column: 0, row: 1, width: 30, height: 20))

let log = List()
rootView.addChild(child: log, bounds: GlobalDrawBounds(column: 32, row: 1, width: 90, height: 20))

let paddingTestContainer = VStack()
rootView.addChild(child: paddingTestContainer, bounds: GlobalDrawBounds(column: 124, row: 1, width: 30, height: 30))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                 backgroundColor: .ansi(.brightYellow),
                                 horizontally: .alignCenter,
                                 vertically: .alignCenter)
            .set(child: Button(text: "Center both")))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                                        backgroundColor: .ansi(.brightYellow),
                                                        horizontally: .alignStart,
                                                        vertically: .alignStart)
    .set(child: Button(text: "Start both")))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                                        backgroundColor: .ansi(.brightYellow),
                                                        horizontally: .alignCenter,
                                                        vertically: .alignStart)
    .set(child: Button(text: "Top centered")))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                                        backgroundColor: .ansi(.brightYellow),
                                                        horizontally: .fill,
                                                        vertically: .fill)
    .set(child: Button(text: "Fill both")))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                                        backgroundColor: .ansi(.brightYellow),
                                                        horizontally: .fill,
                                                        vertically: .alignCenter)
    .set(child: Button(text: "Fill middle")))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                                        backgroundColor: .ansi(.brightYellow),
                                                        horizontally: .alignCenter,
                                                        vertically: .fill)
    .set(child: Button(text: "center fill")))

paddingTestContainer.addChild(child: FixedSizeContainer(size: DrawSize(width: 30, height: 3),
                                                        backgroundColor: .ansi(.brightYellow),
                                                        horizontally: .alignCenter,
                                                        vertically: .alignEnd)
    .set(child: Button(text: "end fill")))


let menuContainer = VStack()
let menu: [MenuItem] = [ .branch(title: "first",
                                 children: [
                                    .branch(title: "in first",
                                            children: [
                                                .branch(title: "in first first",
                                                        children: [],
                                                        open: false,
                                                        state: .normal),
                                                .leaf(drawable: StyledText(text: "here is one thing", style: .color(.ansi(.green)).backgroundColor(.ansi(.brightGreen)))),
                                            ],
                                            open: false,
                                            state: .normal),
                                 ],
                                 open: false,
                                 state: .normal),
                         .branch(title: "second",
                                 children: [],
                                 open: false,
                                 state: .normal),
                         .branch(title: "third",
                                 children: [],
                                 open: false,
                                 state: .normal),
                         .branch(title: "fourth",
                                 children: [],
                                 open: false,
                                 state: .normal),
                         .leaf(drawable: StyledText(text: "wow this works", style: .color(.ansi(.blue)).backgroundColor(.ansi(.brightBlue)))),
                         
]
menuContainer.addChild(child: Menu(children: menu))
rootView.addChild(child: menuContainer, bounds: GlobalDrawBounds(column: 124 + 31, row: 1, width: 30, height: 30))

let tableContainer = FixedSizeContainer(size: DrawSize(width: 60, height: 16), backgroundColor: .ansi(.brightMagenta), horizontally: .alignStart, vertically: .alignStart)

let tableHeaders = ["1", "2", "3", "4", "5"].map{ StyledText(text: $0)}
let tableRows = [
    ["1", "2", "3", "4", "Jaffa Bananer"],
    ["1", "2", "3", "4", "5"],
    ["1", "2", "3", "4", "5"],
    ["Stenade Bilar", "2", "3", "4", "5"],
].map{ row in row.map{ StyledText(text: $0)}}

let table = Table(headers: tableHeaders, rows: tableRows)
tableContainer.set(child: table)
rootView.addChild(child: tableContainer, bounds: GlobalDrawBounds(column: 0, row: 22, width: 60, height: 21))

let bindingView = BindingView()
vstack.addChild(child: bindingView)

let timeline = Timeline()
rootView.addChild(child: timeline, bounds: GlobalDrawBounds(column: 0, row: 43, width: 150, height: 2))

terminal.window.clearScreen()
rootView.draw(cause: .forced)
terminal.writer.flushBuffer()

var timer:Timer?

terminal.keyboard.commands.subscribe(with: terminal) { key in
    
    switch key {
        case .releaseKey(code: "s", modifers: .ctrl):
            log.addLine(text: "release ctrl s", style: TextStyle().backgroundColor(.ansi(.brightGreen)).color(.ansi(.black)))
            
        case .repeatKey(code: "s", modifers: .ctrl):
            log.addLine(text: "repeat ctrl s", style: TextStyle().backgroundColor(.ansi(.brightGreen)).color(.ansi(.black)))
            
        case .pressKey(code: "s", modifers: .ctrl):
            log.addLine(text: "press ctrl s \(key)", style: TextStyle().backgroundColor(.ansi(.brightGreen)).color(.ansi(.black)))
            
        case .pressKey(code: "q", _):
            terminal.terminate()
            
        case .pressKey(code: "c", _):
            terminal.window.clearScreen()
            
        case .pressKey(code: "p", _):
            terminal.cursor.requestPosition()
            
        case .pressKey(code: "r", _):
            bindingView.stateText = "Updated \(Int.random(in: 1..<100))"
        
        case .pressKey(code: "e", _):
            terminal.writer.requestCurrentProgressiveEnhancementKeyMode()
            
        case .pressKey(code: "t", _):
            
            log.addLine(text: "schedule bounce", style: TextStyle().backgroundColor(.ansi(.brightBlue)))
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3) {
                
                DispatchQueue.main.sync {
                    log.addLine(text: "bounce dock", style: TextStyle().backgroundColor(.ansi(.brightBlue)))
                    terminal.writer.bounceDockIndefinetly()
                    rootView.draw(cause: .forced)
                    terminal.writer.flushBuffer()
                }
                
            }
            
        case .pressKey(code: "o", _):
            terminal.cursor.moveTo(column: 0, row: 20)
            let styles: [ANSIEscapedString] =
            [
                "Regular",
                "Bold".bold(),
                "Faint".faint(),
                "Italic".italic(),
                "Underline".underline(),
                "Blinking".blinking(),
                "Strikethrough".strikethrough(),
                "Red".color(.ansi(.red)),
                "Red Bright".color(.ansi(.brightRed)),
                "Red Background".backgroundColor(.ansi(.red)),
                "Bright Red Background".backgroundColor(.ansi(.brightRed)),
                "Colored".color(.rgb(r: 100, g: 100, b: 255)),
                "Background Colored".backgroundColor(.rgb(r: 100, g: 100, b: 255)),
                "Mixed".bold().italic().underline().color(.ansi(.green)).backgroundColor(.ansi(.blue)),
                "Bold".bold() + "Red".color(.ansi(.red)) + "Italic".italic().underline()
            ]
            
            styles.enumerated().forEach{
                terminal.cursor.moveTo(column: 0, row: Int(20 + $0.offset))
                terminal.writer.printRaw($0.element.escapedString(), flush: false)
            }
            
            
        case .pressKey(code: .leftArrow, _):
            terminal.cursor.moveLeft(by: 1)
        case .pressKey(code: .rightArrow, _):
            terminal.cursor.moveRight(by: 1)
        case .pressKey(code: .upArrow, _):
            terminal.cursor.moveUp(by: 1)
        case .pressKey(code: .downArrow, _):
            terminal.cursor.moveDown(by: 1)
        case .pressKey(let code, let modifiers):
            
            let hStack = HStack()
            hStack.addChild(child: StyledText(text: "press \(code)", style: .color(.ansi(.white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.control.rawValue), style: .color(.ansi(modifiers.contains(.ctrl) ? .red  : .white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.shift.rawValue), style: .color(.ansi(modifiers.contains(.shift) ? .red  : .white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.alt.rawValue), style: .color(.ansi(modifiers.contains(.alt) ? .red : .white))))

            log.addLine(line: hStack)
        case .repeatKey(let code, let modifiers):
            let hStack = HStack()
            hStack.addChild(child: StyledText(text: "repeat \(code)", style: .color(.ansi(.white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.control.rawValue), style: .color(.ansi(modifiers.contains(.ctrl) ? .red  : .white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.shift.rawValue), style: .color(.ansi(modifiers.contains(.shift) ? .red  : .white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.alt.rawValue), style: .color(.ansi(modifiers.contains(.alt) ? .red : .white))))
        case .releaseKey(let code, let modifiers):
            let hStack = HStack()
            hStack.addChild(child: StyledText(text: "release \(code)", style: .color(.ansi(.white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.control.rawValue), style: .color(.ansi(modifiers.contains(.ctrl) ? .red  : .white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.shift.rawValue), style: .color(.ansi(modifiers.contains(.shift) ? .red  : .white))))
            hStack.addChild(child: StyledText(text: String(KeyCode.FunctionKey.alt.rawValue), style: .color(.ansi(modifiers.contains(.alt) ? .red : .white))))
    }
    
    rootView.draw(cause: .keyboard(event: key))
}

terminal.commands.subscribe(with: terminal) { command in
    switch command {
        case .meta(.invalidEscapeSequence(let sequence, let message)):
            log.addLine(text: "IES: \(sequence.map{$0.string}.joined(separator: ", ")) message: \(message)",
                        style: TextStyle().backgroundColor(.ansi(.brightRed)).color(.ansi(.black)))
            
            
            rootView.draw(cause: .forced)
            
        case .meta(.unknownEscapeSequence(let sequence)):
            log.addLine(text: "UES: \(sequence.map{$0.string}.joined(separator: ", "))", style: TextStyle().backgroundColor(.ansi(.brightRed)).color(.ansi(.black)))
            
            rootView.draw(cause: .forced)
            
        default:
            break
    }
}

terminal.mouse.commands.subscribe(with: terminal) { command in
    switch command {
        case .leftButtonDown(let column, let row, _,_,_):
            mouseLeftMouseStateWindow.setText("_")
            mousePositionWindow.setText("\(column), \(row)")
            
        case .leftButtonUp(let column, let row, _,_,_):
            mouseLeftMouseStateWindow.setText("-")
            mousePositionWindow.setText("\(column), \(row)")
            
        case .rightButtonDown(let column, let row, _,_,_):
            mouseRightMouseStateWindow.setText("_")
            mousePositionWindow.setText("\(column), \(row)")
            
        case .rightButtonUp(let column, let row, _,_,_):
            mouseRightMouseStateWindow.setText("-")
            mousePositionWindow.setText("\(column), \(row)")
            
        case .move(let column, let row, _,_,_):
            mousePositionWindow.setText("\(column), \(row)")
            
        default:
            break
    }
    
    // mouse here?
    rootView.draw(cause: .mouse(event: command))
}

terminal.cursor.commands.subscribe(with: terminal) { command in
    switch command {
        case .position(column: let column, row: let row):
            cursorPosition.setText("\(column), \(row)")
    }
    rootView.draw(cause: .none)
}

terminal.window.sizeChanges.subscribe(with: terminal) { size in
    windowSizeWindow.setText("\(size.0)x\(size.1)")
    terminal.window.clearScreen()
    rootView.draw(cause: .forced)
}

RunLoop.main.run()
//dispatchMain()

*/
