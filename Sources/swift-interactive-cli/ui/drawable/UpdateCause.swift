
import Foundation


enum UpdateCause: Equatable {
    case mouse(_ event: Mouse)
    case keyboard(_ event: Key)
    case tick
    case data
    case none
}
