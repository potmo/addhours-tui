import Foundation

protocol Drawable: AnyObject {
    
    func draw(with screenWriter: BoundScreenWriter,
             in bounds: GlobalDrawBounds,
              force forced: Bool) -> DidRedraw
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw
    
    func getMinimumSize() -> DrawSize
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds
    
    //@BoundDrawableBuilder var body: [BoundDrawable] { get }
}

extension Drawable {
    func minSize(minWidth: Int? = nil, minHeight: Int? = nil) -> any Drawable {
        return MinSize(minWidth: minWidth, minHeight: minHeight){
            self
        }
    }
}







