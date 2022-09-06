import Foundation

struct SectionSlot<Data> {
    let interval: ClosedRange<TimeInterval>
    let color: Color
    let data: Data
}


class HorizontalSectionLine<DataType>: Drawable {
    
    private var needsRedraw: RequiresRedraw = .yes
    private var visibleInterval: ClosedRange<TimeInterval>// = TimeInterval.todayWithTime(hour: 9, minute: 0)...TimeInterval.todayWithTime(hour: 18, minute: 0)
    private var timeslots: [SectionSlot<DataType>]
    
    init(visibleInterval: ClosedRange<TimeInterval>) {
        self.visibleInterval = visibleInterval
        self.timeslots = []
    }
    
    func setSections(_ sections: [SectionSlot<DataType>]) {
        timeslots = sections
        self.needsRedraw = .yes
    }
    
    func setVisibleInterval(_ range: ClosedRange<TimeInterval>) {
        self.visibleInterval = range
        self.needsRedraw = .yes
    }
    
    func getColumnFor(time: TimeInterval, in bounds: GlobalDrawBounds) -> Int {
        let scalar = (time - visibleInterval.lowerBound) / visibleInterval.duration
        return bounds.column + Int((Double(bounds.width) * scalar).rounded(.down))
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        guard needsRedraw == .yes || forced else {
            return .skippedDraw
        }
        defer {
            needsRedraw = .no
        }
        
        let fillSlotLength = visibleInterval.duration / Double(bounds.width)
        
        let fillIntervals = Array(repeating: 0, count: bounds.width)
            .enumerated()
            .map{ cursor in
                return visibleInterval.lowerBound + Double(cursor.offset) * fillSlotLength
            }
            .map{
                return $0...($0 + fillSlotLength)
            }
        
        
        //TODO: This shold probably be done in update instead or even when sections are set
        var fillIntervalSlots = Array(repeating: Array<FillAmount>(), count: bounds.width)
        
        timeslots.filter{$0.interval.duration > 0}.forEach { slot in
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
        screenWriter.moveTo(bounds.column, bounds.row)
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
                                                          color: slot.color,
                                                          background: background)
                        case .partialStart(let slot, let amount):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: amount,
                                                          color: slot.color,
                                                          background: background)
                        case .partialEnd(let slot, let amount):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1.0 - amount,
                                                          color: background,
                                                          background: slot.color)
                        case .partialInside(let slot, let amount):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: amount,
                                                          color: slot.color,
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
                                                          color: startSlot.color,
                                                          background: endSlot.color)
                            
                        case (.partialEnd(let endSlot, _),
                              .partialStart(let startSlot, let startAmount)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: startAmount,
                                                          color: startSlot.color,
                                                          background: endSlot.color)
                            
                        case (.partialInside(let firstSlot, let firstFactor),
                              .partialInside(let secondSlot, let secondFactor)):
                            let factor = firstFactor / (firstFactor + secondFactor)
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: factor,
                                                          color: firstSlot.color,
                                                          background: secondSlot.color)
                        case (.partialInside(let firstSlot, _),
                              .partialEnd(let secondSlot, let secondFactor)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1-secondFactor,
                                                          color: firstSlot.color,
                                                          background: secondSlot.color)
                        case (.partialStart(let firstSlot, let firstFactor),
                              .partialInside(let secondSlot, _)):
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: firstFactor,
                                                          color: firstSlot.color,
                                                          background: secondSlot.color)
                            
                        case (.all(let firstSlot), _):
                            // This might happen when the slot boundry is exactly the same as the task boundry
                            // making one slot start and the other slot end at the same second
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1.0,
                                                          color: firstSlot.color,
                                                          background: firstSlot.color)
                            
                        case (_, .all(let secondSlot)):
                            // This might happen when the slot boundry is exactly the same as the task boundry
                            // making one slot start and the other slot end at the same second
                            printFractionalBlockCharacter(using: screenWriter,
                                                          fraction: 1.0,
                                                          color: secondSlot.color,
                                                          background: secondSlot.color)
                            
                        default:
                            fatalError("cannot handle these types: \(fillSlots)")
                    }
                default:
                    //TODO: Figure out what to do when there are more than two tasks in one slot
                    //screenWriter.printRaw("\(fillSlots.count % 10)")
                    screenWriter.printLineAtCursor("\(fillSlots.count % 10)")
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
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return needsRedraw
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: DrawSize(width: bounds.width, height: 1), horizontally: .fill, vertically: .alignStart)
    }
    
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: 1, height: 1)
    }
    
    private enum FillAmount: CustomStringConvertible{
        var description: String {
            switch self {
                case .all: return ".all"
                case .partialStart: return ".partialStart"
                case .partialInside: return ".partialInside"
                case .partialEnd: return ".partialEnd"
            }
        }
        
        case all(_ slot: SectionSlot<DataType>)
        case partialStart(_ slot: SectionSlot<DataType>, _ amount: Double)
        case partialEnd(_ slot: SectionSlot<DataType>, _ amount: Double)
        case partialInside(_ slot: SectionSlot<DataType>,  _ amount: Double)
    }
}
