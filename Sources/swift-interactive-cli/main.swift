import Foundation
import Backtrace

Backtrace.install()

let terminal = Terminal()

let settings = Settings()
let viewForLog = Log()
let log: Logger = viewForLog
let database = Database()
let dataDispatcher = DataDispatcher()
let projectStore = ProjectStore(database: database, dataDispatcher: dataDispatcher)
let slotStore = TimeSlotStore(database: database,
                              dataDispatcher: dataDispatcher,
                              selectedRange: TimeInterval.todayWithRange(start: (hour: 8, minute: 0), end: (hour: 24, minute: 0)),
                              settings: settings)

let batchedTimer = BatchedTimer()

func fatalError(_ message: String, file: String = #file, line: Int = #line) -> Never {
    terminal.terminate(exit: false)
    print(message)
    print("in: \(file) line: \(line)")
    
    Thread.callStackSymbols.forEach{print($0)}
    exit(1)
}

let selectedProjectView = SelectedProjectView(projectStore: projectStore, timeSlotStore: slotStore, timer: batchedTimer)

let rootView = TerminalRootView(window: terminal.window, writer: terminal.writer) {
    VStack{
        Timeline(timeSlotStore: slotStore, timer: batchedTimer)
        selectedProjectView
        HSplit(ratio: 0.5,
               left: {
            VStack{
                ProjectListView(projectStore: projectStore, selectedProjectView: selectedProjectView)
                Button(text: "add project").onPress{ _ in
                    projectStore.addProject(name: "\(Int.random(in: 1...1000))",
                                            color: .rgb(r: UInt8.random(in: 0..<255), g: UInt8.random(in: 0..<255), b: UInt8.random(in: 0..<255)))
                }
                ScrollList {
                    for i in 1..<10 {
                        Expandable(title: "Number \(i)") {
                            for j in 1..<10 {
                                Text("item \(j)", style: .backgroundColor(.ansi(.white)).color(.black))
                            }
                        }
                    }
                    
                    Expandable(title: "Number extra") {
                        for j in 1..<3 {
                            Expandable(title: "Number extra \(j)") {
                                for k in 1..<4 {
                                    Text("item \(k)", style: .backgroundColor(.ansi(.white)).color(.black))
                                }
                            }
                        }
                    }
                }
                
            }
        },
               right: {
            VStack{
                DataTable(headers: [Text("One"), Text("Two"), Text("Three")],
                          rows: [[Text("1"), Text("2"), Text("3")],
                                 [Text("4"), Text("5"), Text("5")],
                                 [Text("7"), Text("8"), Text("9")],
                                ])
                TextInput(text: Binding(wrappedValue: "hello"))
                Button(text: "Button")
                    .onPress { button in
                        button.text("\(Int.random(in: 1..<1000))")
                    }.set(horizontalAlignment: .center, verticalAlignment: .center)
                viewForLog
            }
            
        })
        
    }
}

terminal.keyboard.commands.subscribe(with: terminal) { key in

    log.log("\(key)")
    
    switch key {
        case .pressKey(code: "c", .ctrl):
            terminal.terminate()
        case .pressKey(code: "p", modifers: .ctrl):
            rootView.paused.toggle()
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
            rootView.update(with: UpdateCause.none, forceDraw: false)
        case .focusOut:
            log.log("window lost focus")
            rootView.update(with: UpdateCause.none, forceDraw: false)
    }
    
}

batchedTimer.commands.subscribe(with: batchedTimer) { _ in
    rootView.update(with: .tick)
}

dataDispatcher.commands.subscribe(with: terminal) {
    rootView.update(with: .data)
}

terminal.window.clearScreen()
rootView.update(with: UpdateCause.none, forceDraw: true)
terminal.writer.flushBuffer()


log.log("Database at: \(FileManager().currentDirectoryPath)")




RunLoop.main.run()
