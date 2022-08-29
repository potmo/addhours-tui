import Foundation

class UnnacountedTime: Drawable {
    
    private var unaccountedTimeFrom: TimeInterval
    private var text: Text
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .default
        
        return formatter
    }
    
    init(unaccountedTimeFrom: TimeInterval) {
        self.unaccountedTimeFrom = unaccountedTimeFrom
        self.text = Text(text: "")
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return text.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        if cause == .tick {
            let distance = Date(timeIntervalSince1970: unaccountedTimeFrom).distance(to: Date())
            let timeString = timeFormatter.string(from: distance) ?? "?"
            text.set(text: timeString)
        }
        return text.update(with: cause, in: bounds)
    }
    
    func getMinimumSize() -> DrawSize {
        return text.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return text.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
