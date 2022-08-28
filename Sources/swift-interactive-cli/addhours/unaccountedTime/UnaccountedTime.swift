import Foundation

class UnnacountedTime: Drawable {
    
    @Binding private var unaccountedTime: TimeInterval
    @State private var unaccountedTimeText: String
    
    private let text: Text
    
    init(unaccountedTime: Binding<TimeInterval>) {
        self._unaccountedTime = unaccountedTime
        
        let formatter = RelativeDateTimeFormatter()
        let time = formatter.localizedString(fromTimeInterval: _unaccountedTime.wrappedValue)
        self._unaccountedTimeText = State(wrappedValue: time)
        self.text = Text(text: _unaccountedTimeText.projectedValue)
        
        unaccountedTime.updatedSignal.subscribe(with: self) { newValue in
            let time = formatter.localizedString(fromTimeInterval: newValue)
            self.unaccountedTimeText = time
        }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return text.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return text.update(with: cause, in: bounds)
    }
    
    func getMinimumSize() -> DrawSize {
        return text.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return text.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
