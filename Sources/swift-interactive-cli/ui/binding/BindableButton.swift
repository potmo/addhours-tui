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
    
    init(text: Binding<String>) {
        
        let style = State(wrappedValue: BindableButton.getStyleFrom(state: .normal))
        self.state = .normal
        self.textDrawable = BindableStyledText(text: text, style: style.projectedValue).align(.center, .center)
        self._style = style
        self._text = text
    }
    
    init(text: String) {
        let style = BindableButton.getStyleFrom(state: .normal)
        self.state = .normal
        self.style = style
        self.textDrawable = BindableStyledText(text: text, style: style)
        self.text = text
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
                
                text = "\(Int.random(in: 1..<1000))"
                
            } else {
                state = .normal
            }
        }
        
        style = BindableButton.getStyleFrom(state: state)
        
        return textDrawable.update(with: cause, in: drawBounds)
    }
    
    func draw(with screenWriter: ScreenWriter, in drawBounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        //TODO: We need to be able to set the text align for the text for this to work properly
        return textDrawable.draw(with: screenWriter, in: drawBounds, force: forced)
        
        /*
        if  !forced, needsRedraw == .no {
            return .skippedDraw
        }
        
        let style = BindableButton.getStyleFrom(state: state)
        
        let print = text.horizontalCenterPadFit(with: " ", toFit: drawBounds.width, ellipsis: true)
            .verticalCenterPadFit(with: " ", repeated: drawBounds.width, toFit: drawBounds.height)
            .with(style: style)
            .escapedString()
        
        screenWriter.print(print, column: drawBounds.column, row: drawBounds.row)
        
        needsRedraw = .no
        
        return .drew
         */
        
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
