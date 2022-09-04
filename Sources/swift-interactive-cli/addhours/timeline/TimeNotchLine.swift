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
    
    func getColumnFor(time: TimeInterval, in bounds: GlobalDrawBounds) -> Int {
        let scalar = (time - visibleInterval.lowerBound) / visibleInterval.duration
        return bounds.column + Int(Double(bounds.width) * scalar)
    }
    
    func getNotchLabels(in bounds: GlobalDrawBounds) -> [(Int, String)] {
        
        //TODO: Dynamically change the number and the units depending on what fits the bounds
        return (1...24).map{ hour in
            //TODO: not just today
            return TimeInterval.todayWithTime(hour: hour, minute: 0)
        }.map{ time in
            let text = dateFormatter.string(from: Date(timeIntervalSince1970: time))
            let column = getColumnFor(time: time, in: bounds)
            return (column, text)
        }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        defer {
            needsRedraw = .no
        }
        
        var cursor = bounds.column
        screenWriter.moveTo(cursor, bounds.row)
        
        for (column, text) in getNotchLabels(in: bounds) {
            if !bounds.horizontalRange.partiallyContains(column...column+text.count) {
                continue
            }
            
            let paddingLength = max(0, column - cursor)
            let padding = Array(repeating: " ", count: paddingLength).joined(separator: "")
            screenWriter.printLineAtCursor(padding)
            
            let printText = "|" + text
            screenWriter.printLineAtCursor(printText)
            cursor += paddingLength + printText.count
            
            log.log("padding: \(paddingLength)")
        }
        
        
        //let text = Array(repeating: ":", count: bounds.width).joined(separator: "")
        
        
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
