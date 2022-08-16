import Foundation

class BindableBase: BoundDrawable {
    
    private let logic: BindableLogic
    private let childContainter: BoundDrawable

    init(with logic: BindableLogic) {
        self.logic = logic
        let children = logic.children
        let closure: ()->[BoundDrawable] = {children}
        self.childContainter = BindableVStack(closure)
    }
    
    func draw(with screenWriter: ScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
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

protocol BindableLogic {
    @BoundDrawableBuilder var children: [BoundDrawable] {get}
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> Void
}

extension BindableLogic {
    func inVStack() -> any BoundDrawable {
        return BindableBase(with: self)
    }
}
