import Foundation

class HSplit: BoundDrawable {
    
    private let leftChild: BindableVStack
    private let rightChild: BindableVStack
    private let leftRatio: Double

    
    init(ratio: Double,
         @BoundDrawableBuilder left leftContent: () -> [BoundDrawable],
         @BoundDrawableBuilder right rightContent: () -> [BoundDrawable]) {

        leftChild = BindableVStack(leftContent)
        rightChild = BindableVStack(rightContent)
        leftRatio = ratio
    }
    
    func draw(with screenWriter: ScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        let (leftBounds, rightBounds) = getChildDrawBounds(given: bounds)
        
        let leftDrew = leftChild.draw(with: screenWriter, in: leftBounds, force: forced)
        let rightDrew = rightChild.draw(with: screenWriter, in: rightBounds, force: forced)
        
        if leftDrew == .drew || rightDrew == .drew {
            return .drew
        } else {
            return .skippedDraw
        }
        
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        let (leftBounds, rightBounds) = getChildDrawBounds(given: bounds)
        
        let leftNeedsRedraw = leftChild.update(with: cause, in: leftBounds) == .yes
        let rightNeedsRedraw = rightChild.update(with: cause, in: rightBounds) == .yes
        
        
        if leftNeedsRedraw || rightNeedsRedraw {
            return .yes
        } else {
            return .no
        }
    }
        
    func getChildDrawBounds(given bounds: GlobalDrawBounds) -> (GlobalDrawBounds, GlobalDrawBounds) {
        let leftWidth = Int((Double(bounds.width) * leftRatio).rounded(.awayFromZero))
        let rightWidth = bounds.width - leftWidth
        let leftBounds = GlobalDrawBounds(column: bounds.column,
                                          row: bounds.row,
                                          width: leftWidth,
                                          height: bounds.height)
        
        let rightBounds = GlobalDrawBounds(column: bounds.column + leftWidth,
                                           row: bounds.row,
                                           width: rightWidth,
                                           height: bounds.height)
        
        return (leftBounds, rightBounds)
    }
    
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: getMinimumSize(),
                                     horizontally: .fill,
                                     vertically: .fill)
        
    }
    
    func getMinimumSize() -> DrawSize {
        
        let leftSize = leftChild.getMinimumSize()
        let rightSize = rightChild.getMinimumSize()
        let width = leftSize.width + rightSize.width
        let height = max(leftSize.height, rightSize.height)
        
        return DrawSize(width: width, height: height)
    }
    
    
    
    
}
