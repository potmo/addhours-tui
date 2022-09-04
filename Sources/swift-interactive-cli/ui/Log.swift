import Foundation

protocol Logger {
    func log(_ text: String)
    func warning(_ text: String)
    func error(_ text: String)
}

class Log: Drawable, Logger {
    
    private let backingView: ScrollList
    
    init() {
        backingView = ScrollList(){}
    }
    
    func log(_ text: String) {
        let text = Text(text, style: .color(.ansi(.black)).backgroundColor(.ansi(.brightBlue)))
        backingView.addChild(text)
    }
    
    func warning(_ text: String) {
        let text = Text(text, style: .color(.ansi(.black)).backgroundColor(.ansi(.brightYellow)))
        backingView.addChild(text)
    }
    
    func error(_ text: String) {
        let text = Text(text, style: .color(.ansi(.black)).backgroundColor(.ansi(.brightRed)))
        backingView.addChild(text)
    }
    
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return backingView.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return backingView.update(with: cause, in: bounds)
    }
    
    func getMinimumSize() -> DrawSize {
        return backingView.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingView.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
