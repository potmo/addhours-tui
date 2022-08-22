import Foundation

class DrawableLogicWrapper: Drawable {
    
    private let logic: BindableLogic
    private let childContainter: Drawable

    init(with logic: BindableLogic) {
        self.logic = logic
        let children = logic.children
        let closure: ()->[Drawable] = {children}
        self.childContainter = VStack(closure)
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return childContainter.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func getMinimumSize() -> DrawSize {
        return childContainter.getMinimumSize()
    }
    
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return childContainter.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        logic.update(with: cause, in: bounds)
        return childContainter.update(with: cause, in: bounds)
    }
}

