import Foundation
import Signals
import CoreImage
protocol Drawable {
    func draw(cause: DrawCause,
              in bounds: GlobalDrawBounds,
              with screenWriter: ScreenWriter,
              horizontally horizontalDirective: ArrangeDirective,
              vertically verticalDirective: ArrangeDirective) -> DrawSize
    func getMinimumSize() -> DrawSize
}

enum NeedsRedraw: Equatable {
    case no(cachedSize: DrawSize)
    case yes
}





