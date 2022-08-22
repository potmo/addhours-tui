import Foundation

class Margin:Drawable {
    
    private let left: Int
    private let right: Int
    private let top: Int
    private let bottom: Int
    private let backingContainer: VStack
    
    init(left: Int = 0, right: Int = 0, top: Int = 0, bottom: Int = 0, @DrawableBuilder _ content: () -> [Drawable]) {
        self.backingContainer = VStack(content)
        self.left = left
        self.right = right
        self.top = top
        self.bottom = bottom
    }
    
    private func addMargins(to bounds: GlobalDrawBounds) -> GlobalDrawBounds {
        return bounds.offset(columns: left, rows: top)
            .offsetSize(columns: -left, rows: -top)
            .offsetSize(columns: -right, rows: -bottom)
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        let marginBounds = addMargins(to: bounds)
        
        //TODO: This can be optimized a lot
        for row in bounds.row ... bounds.row + bounds.height {
            for column in bounds.column ... bounds.column + bounds.width {
                if !marginBounds.contains(x: column, y: row) {
                    screenWriter.print(" ", column: column, row: row)
                }
            }
        }
        
        return backingContainer.draw(with: screenWriter.bound(to: marginBounds), in: marginBounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        let marginBounds = addMargins(to: bounds)
        return backingContainer.update(with: cause, in: marginBounds)
    }
    
    func getMinimumSize() -> DrawSize {
        return backingContainer.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingContainer.getDrawBounds(given: bounds, with: arrangeDirective)
    }
}
