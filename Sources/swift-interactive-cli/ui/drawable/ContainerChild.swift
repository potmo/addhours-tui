import Foundation

struct ContainerChild {
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
    func requiringRedraw(_ requiresRedraw:RequiresRedraw) -> Self {
        return ContainerChild(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds, didDraw: didDraw)
    }
    
    func didDraw(_ didDraw: DidRedraw) -> Self {
        return ContainerChild(drawable: drawable, requiresRedraw: requiresRedraw, drawBounds: drawBounds, didDraw: didDraw)
    }
    
    func updateDrawBounds(with drawBounds: GlobalDrawBounds) -> Self {
        if self.drawBounds != drawBounds {
            return ContainerChild(drawable: drawable, requiresRedraw: .yes, drawBounds: drawBounds, didDraw: didDraw)
        }else{
            return self
        }
    }
    
    func update(with cause: UpdateCause) -> ContainerChild {
        let requiresRedraw = drawable.update(with: cause, in: drawBounds)
        return self.requiringRedraw(self.requiresRedraw || requiresRedraw)
    }
    
    func draw(with screenWriter: BoundScreenWriter, force forced: Bool) -> ContainerChild {
        guard requiresRedraw == .yes || forced else {
            return self.didDraw(.skippedDraw)
        }
        let didDraw = drawable.draw(with: screenWriter.bound(to: drawBounds), in: drawBounds, force: forced)
        //screenWriter.print("\(Int.random(in: 1...9))", column: drawBounds.column, row: drawBounds.row)
        return ContainerChild(drawable: drawable, requiresRedraw: .no, drawBounds: drawBounds, didDraw: didDraw)
    }
}
