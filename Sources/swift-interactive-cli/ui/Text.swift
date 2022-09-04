import Foundation

class Text: Drawable, CustomStringConvertible {
    
    private var text: String
    private var needsRedraw: RequiresRedraw
    private var style: TextStyle
    private var align: Align
    
    init(_ text: String, style: TextStyle = TextStyle(), align: Align = Align(.start, .start)) {
        self.text = text
        self.style = style
        self.needsRedraw = .yes
        self.align = align
    }
    
    @discardableResult
    func set(horizontalAlignment: AlignDirective, verticalAlignment: AlignDirective) -> Self {
        let align = Align(horizontalAlignment, verticalAlignment)
        guard self.align != align else {
            return self
        }
        self.align = align
        self.needsRedraw = .yes
        return self
    }
    
    @discardableResult
    func set(text: String) -> Self {
        guard self.text != text else {
            return self
        }
        self.text = text
        self.needsRedraw = .yes
        return self
    }
    
    @discardableResult
    func set(style: TextStyle) -> Self {
        guard self.style != style else {
            return self
        }
        self.style = style
        self.needsRedraw = .yes
        return self
    }

    
    func draw(with screenWriter: BoundScreenWriter, in drawBounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        var appearence = text
            
        switch align.horizontal {
            case .start:
                appearence = appearence.rightPadFit(with: " ", toFit: drawBounds.width, ellipsis: true)
            case .center:
                appearence = appearence.horizontalCenterPadFit(with: " ", toFit: drawBounds.width, ellipsis: true)
            case .end:
                appearence = appearence.leftPadFit(with: " ", toFit: drawBounds.width, ellipsis: true)
        }
        
        switch align.vertical {
            case .start:
                appearence = appearence.bottomPadFit(with: " ", repeated: drawBounds.width, toFit: drawBounds.height)
            case .center:
                appearence = appearence.verticalCenterPadFit(with: " ", repeated: drawBounds.width, toFit: drawBounds.height)
            case .end:
                appearence = appearence.topPadFit(with: " ", repeated: drawBounds.width, toFit: drawBounds.height)
        }
            
        screenWriter.print(appearence,
                           with: style,
                           column: drawBounds.column,
                           row: drawBounds.row)
        
        needsRedraw = .no
        
        return .drew
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        let textSize = DrawSize(width: text.lines.map{$0.count}.max() ?? 0,
                                height: text.lines.count)
        
        return bounds.truncateToSize(size: textSize,
                                     horizontally: arrangeDirective.horizontal,
                                     vertically: arrangeDirective.vertical)
    }
    
    func update(with cause: UpdateCause, in drawBounds: GlobalDrawBounds) -> RequiresRedraw {
        return needsRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: text.lines.map{$0.count}.max() ?? 0,
                        height: text.lines.count)
    }
    
    var description: String {
        return "Text[\(text)]"
    }
    
}

