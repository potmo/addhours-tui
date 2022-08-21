import Foundation

class BindableIf: BoundDrawable {
    
    private var needsRedraw: RequiresRedraw = .yes
    private var backingContainer: BindableVStack
    @Binding var on: Bool
    
    init(_ binding: Binding<Bool>, @BoundDrawableBuilder _ content: () -> [BoundDrawable]) {
        backingContainer = BindableVStack(content)
        self._on = binding
        self._on.updatedSignal.subscribe(with: self){ _ in
            self.needsRedraw = .yes
        }
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        defer {
            needsRedraw = .no
        }
        if on {
            return backingContainer.draw(with: screenWriter, in: bounds, force: needsRedraw == .yes || forced)
        } else {
            return .drew
        }
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        if on {
            if backingContainer.update(with: cause, in: bounds) == .yes || needsRedraw == .yes {
                return .yes
            } else {
                return .no
            }
        } else {
            return needsRedraw
        }
    }
    
    func getMinimumSize() -> DrawSize {
        if on {
            return backingContainer.getMinimumSize()
        }else{
            return DrawSize(width: 0, height: 0)
        }
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        if on {
            return backingContainer.getDrawBounds(given: bounds, with: arrangeDirective)
        } else {
            return GlobalDrawBounds(column: bounds.column, row: bounds.row, width: 0, height: 0)
        }
    }
    
    
}
