import Foundation


enum DidRedraw {
    case skippedDraw
    case drew
    
    static prefix func !(arg: DidRedraw)->DidRedraw {
        switch arg {
            case .drew: return .skippedDraw
            case .skippedDraw: return .drew
        }
    }
    
    static func &&(left: DidRedraw, right: DidRedraw) -> DidRedraw {
        if left == .drew && right == .drew {
            return .drew
        } else {
            return .skippedDraw
        }
    }
    
    static func ||(left: DidRedraw, right: DidRedraw) -> DidRedraw {
        if left == .drew || right == .drew {
            return .drew
        } else {
            return .skippedDraw
        }
    }
}
