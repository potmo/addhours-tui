import Foundation

class TimeNotchLine: Drawable {
    
    private var needsRedraw: RequiresRedraw
    private var visibleInterval: ClosedRange<TimeInterval>
    private let dateFormatter: DateFormatter
    
    init(range: ClosedRange<TimeInterval>) {
        self.needsRedraw = .yes
        self.visibleInterval = range
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .none
        self.dateFormatter.timeStyle = .short
    }
    
    func setVisibleInterval(_ range: ClosedRange<TimeInterval>) {
        self.visibleInterval = range
        self.needsRedraw = .yes
    }
    
    func getColumnFor(time: TimeInterval, in bounds: GlobalDrawBounds) -> (column: Int, interColumnFactor: Double) {
        let scalar = (time - visibleInterval.lowerBound) / visibleInterval.duration
        
        let trueColumn = Double(bounds.column) + Double(bounds.width) * scalar
        let column = Int(trueColumn.rounded(.down))
        let residue = trueColumn - Double(column)
        return (column, residue)
    }
    
    func getNotchLabels(in bounds: GlobalDrawBounds) -> [(column: Int, timeString: String, marker: String)] {
        
        //TODO: Dynamically change the number and the units depending on what fits the bounds
        return (1...24).map{ hour in
            //TODO: not just today
            return TimeInterval.todayWithTime(hour: hour, minute: 0)
        }.map{ time in
            let text = dateFormatter.string(from: Date(timeIntervalSince1970: time))
            let (column, interColumn) = getColumnFor(time: time, in: bounds)
            let fractionChar = getFractionalBlockCharacter(fraction: interColumn)
            return (column, text, fractionChar)
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
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        defer {
            needsRedraw = .no
        }
        
        var cursor = bounds.column
        screenWriter.moveTo(cursor, bounds.row)
        
        let backgroundColor1 = Color.rgb(r: 50, g: 50, b: 50)
        let backgroundColor2 = Color.rgb(r: 0, g: 0, b: 0)
        let style1 = TextStyle().color(.white).backgroundColor(backgroundColor1)
        let style2 = TextStyle().color(.white).backgroundColor(backgroundColor2)
        let transitionStyle1to2 = TextStyle().color(backgroundColor1).backgroundColor(backgroundColor2)
        let transitionStyle2to1 = TextStyle().color(backgroundColor2).backgroundColor(backgroundColor1)
        
        
        for (index,(column, text, marker)) in getNotchLabels(in: bounds).enumerated() {
            if !bounds.horizontalRange.partiallyContains(column...column+text.count) {
                continue
            }
            
            let previous: TextStyle
            let transition: TextStyle
            let next: TextStyle
            if index.isMultiple(of: 2) {
                previous = style1
                transition = transitionStyle1to2
                next = style2
            } else {
                previous = style2
                transition = transitionStyle2to1
                next = style1
            }
            
            let paddingLength = max(0, column - cursor)
            let padding = Array(repeating: " ", count: paddingLength).joined(separator: "")
            
            screenWriter.runWithinStyledBlock(with: previous){
                screenWriter.printLineAtCursor(padding)
            }
            
            screenWriter.runWithinStyledBlock(with: transition){
                screenWriter.printLineAtCursor(marker)
            }
            
            screenWriter.runWithinStyledBlock(with: next){
                screenWriter.printLineAtCursor(text)
            }
            
            log.log("\(text) is \(index.isMultiple(of: 2))")
            
            cursor += padding.count + marker.count + text.count
        }
        
        return .drew
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return needsRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: 1,height: 1)
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: DrawSize(width: bounds.width, height: 1), horizontally: .fill, vertically: .alignStart)
    }
    
}
