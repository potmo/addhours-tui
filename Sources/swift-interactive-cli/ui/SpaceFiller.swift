import Foundation

class SpaceFiller: Drawable {
    
    private let filler: Character
    private let style: TextStyle
    private let maxWidth: Int?
    private let maxHeight: Int?
    init(filler: Character, style: TextStyle, maxWidth: Int? = nil, maxHeight: Int? = nil) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.filler = filler
        self.style = style
    }
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        guard forced else {
            return .skippedDraw
        }
        
        let line = Array(repeating: String(filler), count: bounds.width).joined(separator: "")
        let box = Array(repeating: line, count: bounds.height).joined(separator: "\n")
        screenWriter.print(box, with: style, column: bounds.column, row: bounds.row)
        return .drew
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        //TODO: If the draw bounds changes we need to redraw
        
        return .no
    }
    
    func getMinimumSize() -> DrawSize {
        return DrawSize(width: 0, height: 0)
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        let width: Int = min(bounds.width, maxWidth ?? Int.max)
        let height: Int = min(bounds.height, maxHeight ?? Int.max)
        
        return bounds.truncateToSize(size: DrawSize(width: width, height: height), horizontally: .alignStart, vertically: .alignStart)
    }
    
    
}
