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
        guard self.visibleInterval != range else {
            return
        }
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
    
    func getNotchLabels(in bounds: GlobalDrawBounds) -> [(column: Int, timeString: String, marker: String, index: Int)] {
        
        //TODO: Dynamically change between months/days/hours/minutes/seconds ect to fit all the labels
        let start = Calendar.current.nextFullHour(after: visibleInterval.lowerBound.date)
        let numberOfHours = Calendar.current.numberOfHoursBetween(visibleInterval.lowerBound.date, and: visibleInterval.upperBound.date)
        
        log.log("Number of hours: \(numberOfHours)")
        let labels = stride(from: 0, through: numberOfHours, by: 1)
            .map{ hours in
                return Calendar.current.date(byAdding: .hour, value: hours, to: start)!.timeIntervalSince1970
            }
            .map{ time -> (Int, String, String, Int) in
                let text = dateFormatter.string(from: time.date)
                let (column, interColumn) = getColumnFor(time: time, in: bounds)
                let fractionChar = getFractionalBlockCharacter(fraction: interColumn)
                let hour = Calendar.current.component(.hour, from: time.date)
                return (column, text, fractionChar, hour)
            }
        
        return labels
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
        
        
        
        let backgroundColor1 = Color.rgb(r: 50, g: 50, b: 50)
        let backgroundColor2 = Color.rgb(r: 0, g: 0, b: 0)
        let style1 = TextStyle().color(.white).backgroundColor(backgroundColor1)
        let style2 = TextStyle().color(.white).backgroundColor(backgroundColor2)
        let transitionStyle1to2 = TextStyle().color(backgroundColor1).backgroundColor(backgroundColor2)
        let transitionStyle2to1 = TextStyle().color(backgroundColor2).backgroundColor(backgroundColor1)
        
        var cursor = bounds.column
        screenWriter.moveTo(cursor, bounds.row)
        
        for (column, text, marker, index) in getNotchLabels(in: bounds) {

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
            
            let paddingLength = max(column - cursor, 0)
            let padding = Array(repeating: " ", count: paddingLength).joined(separator: "")
            
            
            screenWriter.runWithinStyledBlock(with: previous){
                screenWriter.printLineAtCursor(padding)
            }
            
            cursor = column
            screenWriter.moveTo(cursor, bounds.row)
            
            
            screenWriter.runWithinStyledBlock(with: transition){
                screenWriter.printLineAtCursor(marker)
            }
            
            screenWriter.runWithinStyledBlock(with: next){
                screenWriter.printLineAtCursor(text)
            }
            
            cursor += marker.count + text.count
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
