import Foundation

struct Arrange {
    let horizontal: ArrangeDirective
    let vertical: ArrangeDirective
    init(_ horizontal: ArrangeDirective, _ vertical: ArrangeDirective) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

enum ArrangeDirective {
    case fill
    case alignStart
    case alignEnd
    case alignCenter
}

