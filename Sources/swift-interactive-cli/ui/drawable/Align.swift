import Foundation


struct Align: Equatable {
    let horizontal: AlignDirective
    let vertical: AlignDirective
    init(_ horizontal: AlignDirective, _ vertical: AlignDirective) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

enum AlignDirective {
    case start
    case center
    case end
}
