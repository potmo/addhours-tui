import Foundation

class StyledText: Drawable {
    fileprivate var text: String
    fileprivate var needsRedraw: NeedsRedraw = .yes
    fileprivate let style: TextStyle
    
    init(text: String, style: TextStyle = TextStyle()) {
        self.text = text
        self.style = style
        
    }
    
    func setText(_ text: String) {
        self.text = text
        self.needsRedraw = .yes
    }
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        let textSize = DrawSize(width: text.lines.map{$0.count}.max() ?? 0,
                                height: text.lines.count)
        
        let drawBounds = bounds.truncateToSize(size: textSize,
                                               horizontally: horizontalDirective,
                                               vertically: verticalDirective)
        let drawSize = DrawSize(width: drawBounds.width, height: drawBounds.height)
        
        let appearence = text.rightPadFit(with: " ", toFit: drawSize.width, ellipsis: true)
            .bottomPadFit(with: " ", repeated: drawSize.width, toFit: drawSize.height)
        
        if  cause != .forced, case let .no(cachedSize) = needsRedraw {
            return cachedSize
        }
        
        let print = appearence.with(style: style)
        
        screenWriter.print(print.escapedString(), column: bounds.column, row: bounds.row)
        
        needsRedraw = .no(cachedSize: drawSize)
        
        return drawSize
        
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: text.lines.map{$0.count}.max() ?? 0, height: text.lines.count)
    }
    
}
