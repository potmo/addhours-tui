import Foundation


extension Button: CustomStringConvertible {
    var description: String {
        return "Button[\(text)]"
    }
}

class Button: Drawable {
    
    fileprivate var state: MouseState = .normal
    fileprivate var needsRedraw: NeedsRedraw = .yes
    
    private var text: String
    
    init(text: String) {
        self.text = text
    }
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        let computedText = text
        
        let textSize = DrawSize(width: computedText.lines.map{$0.count}.max() ?? 0,
                                height: computedText.lines.count)
        
        let drawBounds = bounds.truncateToSize(size: textSize,
                                               horizontally: horizontalDirective,
                                               vertically: verticalDirective)
        let drawSize = DrawSize(width: drawBounds.width, height: drawBounds.height)
        
        
        if state == .normal, case let .mouse(.move(x, y,_,_,_)) = cause {
            if drawBounds.contains(x: x,y: y) {
                state = .hovered
                needsRedraw = .yes
            }
        }
        
        if state == .hovered, case let .mouse(.move(x, y,_,_,_)) = cause {
            if !drawBounds.contains(x: x,y: y) {
                state = .normal
                needsRedraw = .yes
            }
        }
        
        if state == .hovered, case let .mouse(.leftButtonDown(x, y,_,_,_)) = cause {
            if drawBounds.contains(x: x,y: y) {
                state = .pressed
                needsRedraw = .yes
            }
        }
        
        if state == .pressed, case let .mouse(.leftButtonUp(x, y,_,_,_)) = cause {
            if drawBounds.contains(x: x,y: y) {
                state = .hovered
                needsRedraw = .yes
                
                // TODO: Handle click
                
                // since this might have changed the text (and bounds) we will recall draw instead of
                // redoing all of this
                return draw(cause: .forced,
                            in: bounds,
                            with: screenWriter,
                            horizontally: horizontalDirective,
                            vertically: verticalDirective)
                
            } else {
                state = .normal
                needsRedraw = .yes
            }
        }
        
        if  cause != .forced, case let .no(cachedSize) = needsRedraw {
            return cachedSize
        }
        
        let style: TextStyle
        
        switch state {
            case .normal:
                style = TextStyle().backgroundColor(.ansi(.blue))
            case .hovered:
                style = TextStyle().backgroundColor(.ansi(.brightBlue))
            case .pressed:
                style = TextStyle().backgroundColor(.ansi(.brightBlue)).bold()
        }
        
        let print = computedText.horizontalCenterPadFit(with: " ", toFit: drawSize.width, ellipsis: true)
            .verticalCenterPadFit(with: " ", repeated: drawSize.width, toFit: drawSize.height)
            .with(style: style)
            .escapedString()
        
        screenWriter.print(print, column: bounds.column, row: bounds.row)
        
        needsRedraw = .no(cachedSize: drawSize)
        
        return drawSize
        
    }
    
    func mouseMove(column: Int, row: Int) {
        
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: text.lines.map{$0.count}.max() ?? 0, height: text.lines.count)
    }
    
    enum MouseState {
        case hovered
        case pressed
        case normal
    }
    
}
