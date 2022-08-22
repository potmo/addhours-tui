import Foundation


enum DrawCause: Equatable {
    case forced
    case none
    case mouse(event: Mouse)
    case keyboard(event: Key)
}
