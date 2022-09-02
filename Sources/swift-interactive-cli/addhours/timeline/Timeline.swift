import Foundation

struct Timeslot {
    let id: UUID
    let interval: ClosedRange<TimeInterval>
    let task: Task
}

struct Task {
    let id: UUID
    let name: String
    let color: Color
}

/*
 
 Left ti right-ish lines
 
▕
｜
|
︳
⎹
⎸
▏

*/

class Timeline: Drawable {
    
    var visibleInterval = TimeInterval.todayWithTime(hour: 9, minute: 0)...TimeInterval.todayWithTime(hour: 18, minute: 0)
    var needsRedraw: RequiresRedraw = .yes
    
    fileprivate static let task1 = Task(id: UUID(), name: "One", color: .ansi(.red))
    fileprivate static let task2 = Task(id: UUID(), name: "Two", color: .ansi(.blue))
    fileprivate static let task3 = Task(id: UUID(), name: "Three", color: .ansi(.green))
    fileprivate static let task4 = Task(id: UUID(), name: "Four", color: .ansi(.magenta))
    fileprivate static let task5 = Task(id: UUID(), name: "Five", color: .ansi(.cyan))
    
    var timeslots: [Timeslot] = [
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 9, minute: 0)...TimeInterval.todayWithTime(hour: 9, minute: 30), task: task1),
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 9, minute: 30)...TimeInterval.todayWithTime(hour: 10, minute: 0), task: task2),
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 10, minute: 0)...TimeInterval.todayWithTime(hour: 11, minute: 0), task: task3),
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 11, minute: 0)...TimeInterval.todayWithTime(hour: 12, minute: 0), task: task4),
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 12, minute: 30)...TimeInterval.todayWithTime(hour: 13, minute: 0), task: task5),
        
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 13, minute: 30)...TimeInterval.todayWithTime(hour: 13, minute: 31), task: task1),
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 13, minute: 31)...TimeInterval.todayWithTime(hour: 13, minute: 32), task: task2),
        
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 14, minute: 00)...TimeInterval.todayWithTime(hour: 14, minute: 1), task: task1),
        Timeslot(id: UUID(), interval: TimeInterval.todayWithTime(hour: 14, minute: 1)...TimeInterval.todayWithTime(hour: 14, minute: 12), task: task2),
    ]
        
    
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        guard needsRedraw == .yes || forced else {
            return .skippedDraw
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let startDateString = dateFormatter.string(from: Date(timeIntervalSince1970: visibleInterval.lowerBound))
        let endDateString = dateFormatter.string(from: Date(timeIntervalSince1970:visibleInterval.upperBound))
        
        screenWriter.moveTo(bounds.column, bounds.row)
        screenWriter.printLineAtCursor(startDateString)
        screenWriter.printLineAtCursor(Array(repeating: " ", count: bounds.width - startDateString.count - endDateString.count).joined(separator: ""))
        screenWriter.printLineAtCursor(endDateString)
        
        let fillSlotLength = visibleInterval.duration / Double(bounds.width)
        
        let fillIntervals = Array(repeating: 0, count: bounds.width)
            .enumerated()
            .map{ cursor in
                return visibleInterval.lowerBound + Double(cursor.offset) * fillSlotLength
            }
            .map{
                return $0...($0 + fillSlotLength)
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
                
                
                if slot.interval.intersects(with: fillInterval) {
                    let intersection = fillInterval.intersection(with: slot.interval)!
                    
                    if slot.interval.contains(fillInterval.upperBound) {
                        fillIntervalSlots[cursor.offset].append(.partialEnd(slot, intersection.duration / fillSlotLength))
                        return
                    }
                    else if slot.interval.contains(fillInterval.lowerBound) {
                        fillIntervalSlots[cursor.offset].append(.partialStart(slot, intersection.duration / fillSlotLength))
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
                        return left.interval.lowerBound < right.interval.upperBound
                    case (.all(let left), .all(let right)):
                        let leftStart = Date(timeIntervalSince1970: left.interval.lowerBound)
                        let leftEnd = Date(timeIntervalSince1970: left.interval.upperBound)
                        let rightStart = Date(timeIntervalSince1970: right.interval.lowerBound)
                        let rightEnd = Date(timeIntervalSince1970: right.interval.upperBound)
                        fatalError("two slots can not fill the same slot: \n\(leftStart)...\(leftEnd),\n\(rightStart)...\(rightEnd)")
                    default:
                        fatalError("It doesnt make any sense to compare \(lhs) and \(rhs)")
                }
            }
        }
        
        let background = Color.ansi(.brightBlack)
        screenWriter.moveTo(bounds.column, bounds.row + 1)
        for fillSlots in fillIntervalSlots {
            
            guard !fillSlots.isEmpty else {
                //screenWriter.printRaw(" ".backgroundColor(background).escapedString())
                screenWriter.runWithinStyledBlock(with: .backgroundColor(background)) {
                    screenWriter.printLineAtCursor(" ")
                }
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
                        case (.all, .all):
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
                            
                        case (.all(let firstSlot), _):
                            // This might happen when the slot boundry is exactly the same as the task boundry
                            // making one slot start and the other slot end at the same second
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1.0,
                                                          color: firstSlot.task.color,
                                                          background: firstSlot.task.color)
                            
                        case (_, .all(let secondSlot)):
                            // This might happen when the slot boundry is exactly the same as the task boundry
                            // making one slot start and the other slot end at the same second
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1.0,
                                                          color: secondSlot.task.color,
                                                          background: secondSlot.task.color)
                            
                        default:
                            fatalError("cannot handle these types: \(fillSlots)")
                    }
                default:
                    //TODO: Figure out what to do when there are more than two tasks in one slot
                    //screenWriter.printRaw("\(fillSlots.count % 10)")
                    screenWriter.printLineAtCursor("\(fillSlots.count % 10)")
            }
            
        }
        
        screenWriter.moveTo(bounds.column, bounds.row + 2)
        for cursor in fillIntervalSlots.enumerated() {
            if cursor.offset % 2 == 0 {
                screenWriter.printLineAtCursor("▔")
            }else {
                screenWriter.printLineAtCursor(" ")
            }
            
        }
        
        
        //TODO: Implement this
        return .drew
    }
    
    func printFractionalBlockCharacter(using screenWriter: BoundScreenWriter,
                                       fraction: Double,
                                       color: Color,
                                       background: Color) {
        screenWriter.runWithinStyledBlock(with: .color(color).backgroundColor(background)) {
            let char = getFractionalBlockCharacter(fraction: fraction)
            screenWriter.printLineAtCursor(char)
        }
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
    
    enum FillAmount: CustomStringConvertible{
        var description: String {
            switch self {
                case .all: return ".all"
                case .partialStart: return ".partialStart"
                case .partialInside: return ".partialInside"
                case .partialEnd: return ".partialEnd"
            }
        }
        
        case all(_ slot: Timeslot)
        case partialStart(_ slot: Timeslot, _ amount: Double)
        case partialEnd(_ slot: Timeslot, _ amount: Double)
        case partialInside(_ slot: Timeslot,  _ amount: Double)
    }

    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        //TODO: implement this
        return .no
    }

    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: DrawSize(width: bounds.width, height: 3), horizontally: .fill, vertically: .alignStart)
    }
    
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: 1, height: 3)
    }
}
