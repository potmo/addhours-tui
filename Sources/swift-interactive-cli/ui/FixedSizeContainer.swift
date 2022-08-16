import Foundation
class FixedSizeContainer: Drawable {
    
    fileprivate var child: Drawable?
    fileprivate let size: DrawSize
    fileprivate let horizontalDirective: ArrangeDirective
    fileprivate let verticalDirective: ArrangeDirective
    fileprivate let backgroundColor: Color
    fileprivate var needsRedraw: NeedsRedraw = .yes
    
    init(size: DrawSize, backgroundColor: Color, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) {
        self.child = nil
        self.size = size
        self.horizontalDirective = horizontalDirective
        self.verticalDirective = verticalDirective
        self.backgroundColor = backgroundColor
    }
    
    @discardableResult
    func set(child: Drawable) -> Self {
        self.child = child
        return self
    }
    
    func draw(cause: DrawCause, in bounds: GlobalDrawBounds, with screenWriter: ScreenWriter, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        let fixedSizeBounds = bounds.truncateToSize(size: size,
                                                    horizontally: horizontalDirective,
                                                    vertically: verticalDirective)
        
        
        //TODO: Down redraw every time
        
        /*
        var background = " ".leftPadFit(with: " ", toFit: Int(size.width))
            .bottomPadFit(with: " ", repeated: Int(size.width), toFit: Int(size.height))
                            
        
        // add border
        background = background.lines.enumerated().map{ line -> String in
            Array(line.element).enumerated().map{ char -> String in
                let width = line.element.count - 1
                let height = background.lines.count - 1
                switch (char.offset, line.offset) {
                    case (0, 0): return "╔"
                    case (width, 0): return "╗"
                    case (0, height): return "╚"
                    case (width, height): return "╝"
                    case (0, _): return "║"
                    case (width, _): return "║"
                    case (_, 0): return "═"
                    case (_, height): return "═"
                    case (_, _): return " "
                }
            }.joined(separator: "")
        }.joined(separator: "\n")
            .backgroundColor(backgroundColor)
            .escapedString()
        
        terminal.writer.print(background, column: fixedSizeBounds.column, row: fixedSizeBounds.row)
        
        */
        
        var childBounds: GlobalDrawBounds? = nil
        
        if let child = child {
            let childSize = child.getMinimumSize()
            childBounds = fixedSizeBounds.truncateToSize(size: childSize,
                                                         horizontally: self.horizontalDirective,
                                                         vertically: self.verticalDirective)
            
            _ = child.draw(cause: cause,
                           in: childBounds!,
                           with: screenWriter,
                           horizontally: .fill, //self.horizontalDirective
                           vertically: .fill) // self.verticalDirective
        }
        
        if cause != .forced, case let .no(cachedSize) = needsRedraw {
            return cachedSize
        }
        
        screenWriter.runWithinStyledBlock(with: TextStyle().color(.ansi(.brightRed))) {
            if let childBounds = childBounds {
                screenWriter.fill(bounds: fixedSizeBounds, with: "░", excluding: childBounds)
            } else {
                screenWriter.fill(bounds: fixedSizeBounds, with: "░")
            }
        }
        
        needsRedraw = .no(cachedSize: size)
        return size
    }
    
    func getMinimumSize() -> DrawSize {
        return size
    }
    
    
}
