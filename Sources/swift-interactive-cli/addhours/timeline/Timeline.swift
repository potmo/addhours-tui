import Foundation

struct Timeslot {
    let id: UUID
    let interval: DateInterval
    let task: Task
}

struct Task {
    let id: UUID
    let name: String
    let color: Color
}

extension Double {
    func string(maxFrac: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = maxFrac
        return formatter.string(from: NSNumber(value: self))!
    }
}

class Timeline: Drawable {
    
    var visibleInterval = DateInterval(start: d("2022-01-01T09:00:00Z"), end: d("2022-01-1T18:00:00Z"))
    
    
    fileprivate static func d(_ string: String) -> Date {
        return ISO8601DateFormatter().date(from: string)!
    }
    
    fileprivate static func d(_ from: String, _ to: String) -> DateInterval {
        return DateInterval(start: d(from), end: d(to))
    }
    
    fileprivate static let task1 = Task(id: UUID(), name: "One", color: .ansi(.red))
    fileprivate static let task2 = Task(id: UUID(), name: "Two", color: .ansi(.blue))
    fileprivate static let task3 = Task(id: UUID(), name: "Three", color: .ansi(.green))
    fileprivate static let task4 = Task(id: UUID(), name: "Four", color: .ansi(.magenta))
    fileprivate static let task5 = Task(id: UUID(), name: "Five", color: .ansi(.cyan))
    
    var timeslots: [Timeslot] = [
        Timeslot(id: UUID(), interval: d("2022-01-01T09:00:00Z", "2022-01-01T09:30:00Z"), task: task1),
        Timeslot(id: UUID(), interval: d("2022-01-01T09:30:00Z", "2022-01-01T10:00:00Z"), task: task2),
        Timeslot(id: UUID(), interval: d("2022-01-01T10:00:00Z", "2022-01-01T11:00:00Z"), task: task3),
        Timeslot(id: UUID(), interval: d("2022-01-01T11:00:00Z", "2022-01-01T12:00:00Z"), task: task4),
        Timeslot(id: UUID(), interval: d("2022-01-01T12:30:00Z", "2022-01-01T13:00:00Z"), task: task5),
        
        Timeslot(id: UUID(), interval: d("2022-01-01T13:30:00Z", "2022-01-01T13:31:00Z"), task: task1),
        Timeslot(id: UUID(), interval: d("2022-01-01T13:31:00Z", "2022-01-01T13:32:00Z"), task: task2),
        
        Timeslot(id: UUID(), interval: d("2022-01-01T14:00:00Z", "2022-01-01T14:01:00Z"), task: task1),
        Timeslot(id: UUID(), interval: d("2022-01-01T14:01:00Z", "2022-01-01T14:12:00Z"), task: task2),
        Timeslot(id: UUID(), interval: d("2022-01-01T14:12:00Z", "2022-01-01T14:13:00Z"), task: task3),
    ]
    
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
            
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let startDateString = dateFormatter.string(from: visibleInterval.start)
        let endDateString = dateFormatter.string(from: visibleInterval.end)
        
        screenWriter.print(startDateString, column: bounds.column, row: bounds.row)
        screenWriter.print(endDateString, column: bounds.column + bounds.width - endDateString.count + 1, row: bounds.row)
        
        let fillSlotLength = visibleInterval.duration / Double(bounds.width)
        
        let fillIntervals = Array(repeating: 0, count: bounds.width)
            .enumerated()
            .map{ cursor in
                return visibleInterval.start.timeIntervalSince1970 + Double(cursor.offset) * fillSlotLength
            }
            .map{
                DateInterval(start: Date(timeIntervalSince1970: $0), duration: fillSlotLength)
            }
        
        var fillIntervalSlots = Array(repeating: Array<FillAmount>(), count: bounds.width)
        
        timeslots.forEach { slot in
            fillIntervals.enumerated().forEach{ cursor in
                let fillInterval = cursor.element
                if fillInterval.contains(slot.interval) {
                    let intersection = fillInterval.intersection(with: slot.interval)!
                    fillIntervalSlots[cursor.offset].append(.partialInside(slot, intersection.duration / fillInterval.duration))
                    return
                }
                
                if slot.interval.contains(fillInterval) {
                    fillIntervalSlots[cursor.offset].append(.all(slot))
                    return
                }
                
                if slot.interval.intersects(fillInterval) {
                    let intersection = fillInterval.intersection(with: slot.interval)!
                    
                    if slot.interval.contains(fillInterval.end) {
                        fillIntervalSlots[cursor.offset].append(.partialEnd(slot, intersection.duration / fillSlotLength))
                        return
                    }
                    else if slot.interval.contains(fillInterval.start) {
                        fillIntervalSlots[cursor.offset].append(.partialStart(slot, 1 - intersection.duration / fillSlotLength))
                        return
                    }else {
                        fatalError("the slot interval doesnt seem to be intersecting after all")
                    }
                }
            }
        }
        
        // if these are sorted it will be a lot easier later
        fillIntervalSlots = fillIntervalSlots.map{ fillSlots in
            return fillSlots.sorted{ lhs, rhs in
                switch (lhs, rhs) {
                    case (.partialStart, _):
                        return true
                    case (.partialEnd, _):
                        return false
                    case ( _, .partialEnd):
                        return true
                    case ( _, .partialStart):
                        return false
                    case (.partialInside(let left, _), .partialInside(let right, _)):
                        return left.interval.start < right.interval.start
                    default:
                        fatalError("It doesnt make any sense to compare \(lhs) and \(rhs)")
                }
            }
        }
        
        let background = Color.ansi(.brightBlack)
        screenWriter.moveTo(bounds.column, bounds.row + 1)
        for fillSlots in fillIntervalSlots {
            
            guard !fillSlots.isEmpty else {
                screenWriter.printRaw(" ".backgroundColor(background).escapedString())
                continue
            }
            
            
            switch fillSlots.count {
                case 1:
                    switch fillSlots[0] {
                        case .all(let slot):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1.0,
                                                          color: slot.task.color,
                                                          background: background)
                        case .partialStart(let slot, let amount):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: amount,
                                                          color: slot.task.color,
                                                          background: background)
                        case .partialEnd(let slot, let amount):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: amount,
                                                          color: background,
                                                          background: slot.task.color)
                        case .partialInside(let slot, let amount):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: amount,
                                                          color: slot.task.color,
                                                          background: background)
                    }
                case 2:
                    switch (fillSlots[0], fillSlots[1]) {
                        case (.all(_), .all(_)):
                            fatalError("it seems two tasks will fill the slot and that is impossible")
                        case (.partialStart(let startSlot, let startAmount),
                              .partialEnd(let endSlot, _)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: startAmount,
                                                          color: startSlot.task.color,
                                                          background: endSlot.task.color)
                            
                        case (.partialEnd(let endSlot, _),
                              .partialStart(let startSlot, let startAmount)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: startAmount,
                                                          color: startSlot.task.color,
                                                          background: endSlot.task.color)
                            
                        case (.partialInside(let firstSlot, let firstFactor),
                              .partialInside(let secondSlot, let secondFactor)):
                            let factor = firstFactor / (firstFactor + secondFactor)
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: factor,
                                                          color: firstSlot.task.color,
                                                          background: secondSlot.task.color)
                        case (.partialInside(let firstSlot, _),
                              .partialEnd(let secondSlot, let secondFactor)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1-secondFactor,
                                                          color: firstSlot.task.color,
                                                          background: secondSlot.task.color)
                        case (.partialStart(let firstSlot, let firstFactor),
                              .partialInside(let secondSlot, _)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: firstFactor,
                                                          color: firstSlot.task.color,
                                                          background: secondSlot.task.color)
                            
                        default:
                            fatalError("cannot handle these types \(fillSlots)")
                    }
                default:
                    screenWriter.printRaw("\(fillSlots.count % 10)")
            }
            
        }
        
        screenWriter.moveTo(bounds.column, bounds.row + 2)
        for cursor in fillIntervalSlots.enumerated() {
            if cursor.offset % 2 == 0 {
                screenWriter.printRaw("▔")
            }else {
                screenWriter.moveRight()
            }
            
        }
        
        
        return DrawSize(width: bounds.width, height: 1)
    }
    
    func printFractionalBlockCharacter(using screenWriter: ScreenWriter,
                                       fraction: Double,
                                       color: Color,
                                       background: Color) {
        let coloredChar = getFractionalBlockCharacter(fraction: fraction)
            .color(color)
            .backgroundColor(background)
            .escapedString()
        screenWriter.printRaw(coloredChar)
    }
    
    func getFractionalBlockCharacter(fraction: Double) -> String {
        switch (fraction*7).rounded(.down) {
            case 0: return "▏"
            case 1: return "▎"
            case 2: return "▍"
            case 3: return "▌"
            case 4: return "▋"
            case 5: return "▊"
            case 6: return "▉"
            default: return "█"
        }
    }
    
    enum FillAmount{
        case all(_ slot: Timeslot)
        case partialStart(_ slot: Timeslot, _ amount: Double)
        case partialEnd(_ slot: Timeslot, _ amount: Double)
        case partialInside(_ slot: Timeslot,  _ amount: Double)
    }
    
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: 100, height: 2)
    }
}