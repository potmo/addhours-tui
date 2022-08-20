import Foundation

class BoundEscaper: BoundDrawable {
    let string = "helloboys"
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        screenWriter.print(string,
                           with: .color(.ansi(.red)).backgroundColor(.ansi(.brightRed)),
                           column: bounds.column,
                           row: bounds.row)
        return .drew
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        .yes
    }
    
    func getMinimumSize() -> DrawSize {
        DrawSize(width: string.count, height: 1)
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return  bounds.truncateToSize(size: getMinimumSize(),
                                      horizontally: arrangeDirective.horizontal,
                                      vertically: arrangeDirective.vertical)
    }
    
    
}
