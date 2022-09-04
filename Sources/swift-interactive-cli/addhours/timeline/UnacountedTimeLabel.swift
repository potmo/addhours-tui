import Foundation

class UnacountedTimeLabel: Drawable {
    
    private var text: Text
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 3
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .default
        
        return formatter
    }
    
    init() {
        self.text = Text(text: "")
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return text.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return text.update(with: cause, in: bounds)
    }
    
    func setUnaccountedTime(unaccountedTime: ClosedRange<TimeInterval>) {

        let timeString = timeFormatter.string(from: Date(timeIntervalSince1970: unaccountedTime.lowerBound),
                                              to: Date(timeIntervalSince1970: unaccountedTime.upperBound)) ?? "?"
        text.set(text: timeString)
    }
    
    func getMinimumSize() -> DrawSize {
        return text.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return text.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
