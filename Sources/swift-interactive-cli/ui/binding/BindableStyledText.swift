import Foundation

import Foundation

class BindableStyledText: BoundDrawable {
    
    fileprivate let text: Binding<String>
    fileprivate var needsRedraw: RequiresRedraw
    fileprivate var style: Binding<TextStyle>
    fileprivate var align: Align
    
    init(text: Binding<String>, style: Binding<TextStyle>, align: Align = Align(.start, .start)) {
        self.text = text
        self.style = style
        self.align = align
        
        self.needsRedraw = .yes
        text.updatedSignal.subscribe(with: self){ _ in
            self.needsRedraw = .yes
        }
        style.updatedSignal.subscribe(with: self) { _ in
            self.needsRedraw = .yes
        }
        
    }
    
    init(text: Binding<String>, style: TextStyle = TextStyle(), align: Align = Align(.start, .start)) {
        self.text = text
        self.style = Binding(wrappedValue: style)
        self.align = align
        self.needsRedraw = .yes
        text.updatedSignal.subscribe(with: self){ _ in
            self.needsRedraw = .yes
        }
    }
    
    init(text: String, style: TextStyle = TextStyle(), align: Align = Align(.start, .start)) {
        self.text = Binding(wrappedValue: text)
        self.style = Binding(wrappedValue: style)
        self.needsRedraw = .yes
        self.align = align
    }
    
    func align(_ horizontal: AlignDirective, _ vertical: AlignDirective) -> Self {
        self.align = Align(horizontal, vertical)
        self.needsRedraw = .yes
        return self
    }

    
    func draw(with screenWriter: ScreenWriter, in drawBounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        if case (.no, false) = (needsRedraw, forced) {
            return .skippedDraw
        }
        
        var appearence = text.projectedValue
            
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
            
        appearence = appearence.with(style: style.projectedValue).escapedString()
        
        screenWriter.print(appearence, column: drawBounds.column, row: drawBounds.row)
        
        needsRedraw = .no
        
        return .drew
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        let textSize = DrawSize(width: text.projectedValue.lines.map{$0.count}.max() ?? 0,
                                height: text.projectedValue.lines.count)
        
        return bounds.truncateToSize(size: textSize,
                                     horizontally: arrangeDirective.horizontal,
                                     vertically: arrangeDirective.vertical)
    }
    
    func update(with cause: UpdateCause, in drawBounds: GlobalDrawBounds) -> RequiresRedraw {
        return needsRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: text.projectedValue.lines.map{$0.count}.max() ?? 0,
                        height: text.projectedValue.lines.count)
    }
    
}

