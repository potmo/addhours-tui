import Foundation


extension BindableButton: CustomStringConvertible {
    var description: String {
        return "BindableButton[\(text)]"
    }
}

class BindableButton: BoundDrawable {

    fileprivate var state: MouseState
    fileprivate let textDrawable: BindableStyledText
    
    @Binding private var text: String
    @State private var style: TextStyle
    private var pushCallback: (() -> Void)? = nil
    
    init(text: Binding<String>) {
        
        let style = State(wrappedValue: BindableButton.getStyleFrom(state: .normal))
        self.state = .normal
        self.textDrawable = BindableStyledText(text: text, style: style.projectedValue).align(.center, .center)
        self._style = style
        self._text = text
    }
    
    init(text: String) {
        let style = State(wrappedValue: BindableButton.getStyleFrom(state: .normal))
        self._style = style
        let textBind = Binding(wrappedValue: text)
        self._text = textBind
        self.textDrawable = BindableStyledText(text: textBind, style: style.projectedValue)
        self.state = .normal
    }
    
    @discardableResult
    func onPush(_ callback: @escaping ()->Void) -> Self {
        self.pushCallback = callback
        return self
    }
    
    @discardableResult
    func align(_ horizontal: AlignDirective, _ vertical: AlignDirective) -> Self {
        //TODO: This should maybe be some kind of cascading modifier instead
        textDrawable.align(horizontal, vertical)
        return self
    }
    
    func update(with cause: UpdateCause, in drawBounds: GlobalDrawBounds) -> RequiresRedraw {
        
        if state == .normal, case let .mouse(.move(x, y,_,_,_)) = cause {
            if drawBounds.contains(x: x,y: y) {
                state = .hovered
            }
        }
        
        if state == .hovered, case let .mouse(.move(x, y,_,_,_)) = cause {
            if !drawBounds.contains(x: x,y: y) {
                state = .normal
            }
        }
        
        if state == .hovered, case let .mouse(.leftButtonDown(x, y,_,_,_)) = cause {
            if drawBounds.contains(x: x,y: y) {
                state = .pressed
            }
        }
        
        if state == .pressed, case let .mouse(.leftButtonUp(x, y,_,_,_)) = cause {
            if drawBounds.contains(x: x,y: y) {
                state = .hovered
                pushCallback?()
            } else {
                state = .normal
            }
        }
        
        style = BindableButton.getStyleFrom(state: state)
        
        return textDrawable.update(with: cause, in: drawBounds)
    }
    
    func draw(with screenWriter: BoundScreenWriter, in drawBounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return textDrawable.draw(with: screenWriter, in: drawBounds, force: forced)
    }
    
    private static func getStyleFrom(state: MouseState ) -> TextStyle {
        switch state {
            case .normal:
                return TextStyle().backgroundColor(.ansi(.blue))
            case .hovered:
                return TextStyle().backgroundColor(.ansi(.brightBlue))
            case .pressed:
                return TextStyle().backgroundColor(.ansi(.brightBlue)).bold()
        }
    }
    
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return textDrawable.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    func getMinimumSize() -> DrawSize {
        return textDrawable.getMinimumSize()
    }
    
    enum MouseState {
        case hovered
        case pressed
        case normal
    }
    
}
