import Foundation

class UnacountedTimeLabel: Drawable {
    
    private var text: Text
    private var durationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.maximumUnitCount = 3
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .default
        
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
    
    init() {
        self.text = Text("")
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return text.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return text.update(with: cause, in: bounds)
    }
    
    func setUnaccountedTime(_ range: ClosedRange<TimeInterval>) {
        let timeString = timeFormatter.string(from: range.lowerBound.date) + " " + (durationFormatter.string(from: range.duration) ?? "?")
        text.set(text: timeString)
    }
    
    func setUnaccountedTime(_ instant: TimeInterval) {
        text.set(text: timeFormatter.string(from: instant.date))
    }
    
    func getMinimumSize() -> DrawSize {
        return text.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return text.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
