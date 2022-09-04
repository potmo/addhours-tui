import Foundation

class Button: Drawable {

    private var state: MouseState
    private let textDrawable: Text
    private var pushCallback: ((Button) -> Void)? = nil
        
    init(text: String) {
        let style = Button.getStyleFrom(state: .normal)
        self.textDrawable = Text(text, style: style)
        self.state = .normal
    }
    
    @discardableResult
    func onPress(_ pushCallback: @escaping (_ button: Button)->Void) -> Self {
        self.pushCallback = pushCallback
        return self
    }
    
    @discardableResult
    func set(horizontalAlignment: AlignDirective, verticalAlignment: AlignDirective) -> Self {
        textDrawable.set(horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
        return self
    }
    
    @discardableResult
    func text(_ text: String) -> Self {
        self.textDrawable.set(text: text)
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
                pushCallback?(self)
            } else {
                state = .normal
            }
        }
        
        let style = Button.getStyleFrom(state: state)
        textDrawable.set(style: style)
        
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
