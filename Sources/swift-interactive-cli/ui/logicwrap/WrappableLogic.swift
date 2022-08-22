import Foundation

protocol BindableLogic {
    @DrawableBuilder var children: [Drawable] {get}
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> Void
}

extension BindableLogic {
    func inVStack() -> any Drawable {
        return DrawableLogicWrapper(with: self)
    }
}
