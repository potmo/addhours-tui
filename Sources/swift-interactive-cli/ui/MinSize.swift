import Foundation

class MinSize: Drawable {
    
    private let childContainter: Drawable
    private let minWidth: Int?
    private let minHeight: Int?
    
    init(minWidth: Int? = nil, minHeight: Int? = nil, content: () -> Drawable) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.childContainter = content()
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return childContainter.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func getMinimumSize() -> DrawSize {
        let childSize = childContainter.getMinimumSize()
        let width = max(childSize.width, minWidth ?? 0)
        let height = max(childSize.height, minHeight ?? 0)
        return DrawSize(width: width, height: height)
    }
    
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        let childBounds = childContainter.getDrawBounds(given: bounds, with: arrangeDirective)
        let width = min(max(childBounds.width, minWidth ?? 0), bounds.width)
        let height = min(max(childBounds.height, minHeight ?? 0), bounds.height)
        return GlobalDrawBounds(column: childBounds.column, row: childBounds.row, width: width, height: height)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        return childContainter.update(with: cause, in: bounds)
    }
}
