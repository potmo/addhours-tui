import Foundation

extension Drawable {
    func inContainer() -> ContainerChild<Self> {
        return ContainerChild(drawable: self)
    }
}

class ContainerChild<DrawableType: Drawable> {
    
    private let backingContainer: TypeErasedContainerChild
    let drawable: DrawableType
    
    var requiresRedraw: RequiresRedraw {
        return backingContainer.requiresRedraw
    }
    
    var drawBounds: GlobalDrawBounds{
        return backingContainer.drawBounds
    }
    
    var didDraw: DidRedraw {
        return backingContainer.didDraw
    }
    
    init(drawable: DrawableType, requiresRedraw: RequiresRedraw, drawBounds: GlobalDrawBounds, didDraw: DidRedraw) {
        self.drawable = drawable
        self.backingContainer = TypeErasedContainerChild(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds, didDraw: didDraw)
    }
    
    init(drawable: DrawableType) {
        self.drawable = drawable
        self.backingContainer = TypeErasedContainerChild(drawable: drawable)
    }
    
    init(drawable: DrawableType, backingContainer: TypeErasedContainerChild) {
        self.drawable = drawable
        self.backingContainer = backingContainer
    }
    
    
    func requiringRedraw(_ requiresRedraw:RequiresRedraw) -> ContainerChild<DrawableType> {
        return ContainerChild<DrawableType>(drawable: drawable, backingContainer: backingContainer.requiringRedraw(requiresRedraw))
    }
    
    func didDraw(_ didDraw: DidRedraw) -> ContainerChild<DrawableType> {
        return ContainerChild<DrawableType>(drawable: drawable, backingContainer: backingContainer.didDraw(didDraw))
    }
    
    func updateDrawBounds(with drawBounds: GlobalDrawBounds) -> ContainerChild<DrawableType> {
        return ContainerChild<DrawableType>(drawable: drawable, backingContainer: backingContainer.updateDrawBounds(with: drawBounds))
    }
    
    func update(with cause: UpdateCause) -> ContainerChild<DrawableType> {
        return ContainerChild<DrawableType>(drawable: drawable, backingContainer: backingContainer.update(with: cause))
    }
    
    func draw(with screenWriter: BoundScreenWriter, force forced: Bool) -> ContainerChild<DrawableType> {
        return ContainerChild<DrawableType>(drawable: drawable, backingContainer: backingContainer.draw(with: screenWriter, force: forced))
    }
}

struct TypeErasedContainerChild {
    let drawable: Drawable
    let requiresRedraw: RequiresRedraw
    let drawBounds: GlobalDrawBounds
    let didDraw: DidRedraw
    
    init(drawable: Drawable, requiresRedraw: RequiresRedraw, drawBounds: GlobalDrawBounds, didDraw: DidRedraw) {
        self.drawable = drawable
        self.requiresRedraw = requiresRedraw
        self.drawBounds = drawBounds
        self.didDraw = didDraw
    }
    
    init(drawable: Drawable) {
        self.drawable = drawable
        self.requiresRedraw = .yes
        self.drawBounds = GlobalDrawBounds()
        self.didDraw = .skippedDraw
    }
    
    func requiringRedraw(_ requiresRedraw:RequiresRedraw) -> Self {
        return TypeErasedContainerChild(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds, didDraw: didDraw)
    }
    
    func didDraw(_ didDraw: DidRedraw) -> Self {
        return TypeErasedContainerChild(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds, didDraw: didDraw)
    }
    
    func updateDrawBounds(with drawBounds: GlobalDrawBounds) -> Self {
        if self.drawBounds != drawBounds {
            return TypeErasedContainerChild(drawable: drawable, requiresRedraw: .yes, drawBounds: drawBounds, didDraw: didDraw)
        }else{
            return self
        }
    }
    
    func update(with cause: UpdateCause) -> TypeErasedContainerChild {
        let requiresRedraw = drawable.update(with: cause, in: drawBounds)
        return self.requiringRedraw(self.requiresRedraw || requiresRedraw)
    }
    
    func draw(with screenWriter: BoundScreenWriter, force forced: Bool) -> TypeErasedContainerChild {
        guard requiresRedraw == .yes || forced else {
            return self.didDraw(.skippedDraw)
        }
        let didDraw = drawable.draw(with: screenWriter.bound(to: drawBounds), in: drawBounds, force: forced)
        //screenWriter.print("\(Int.random(in: 1...9))", column: drawBounds.column, row: drawBounds.row)
        return TypeErasedContainerChild(drawable: drawable, requiresRedraw: .no, drawBounds: drawBounds, didDraw: didDraw)
    }
}
