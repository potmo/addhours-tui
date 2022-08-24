import Foundation

enum RequiresRedraw: Equatable {
    case no
    case yes
    
    static prefix func !(arg: RequiresRedraw)->RequiresRedraw {
        switch arg {
            case .yes: return .no
            case .no: return .yes
        }
    }
    
    static func &&(left: RequiresRedraw, right: RequiresRedraw) -> RequiresRedraw {
        if left == .yes && right == .yes {
            return .yes
        } else {
            return .no
        }
    }
    
    static func ||(left: RequiresRedraw, right: RequiresRedraw) -> RequiresRedraw {
        if left == .yes || right == .yes {
            return .yes
        } else {
            return .no
        }
    }
}

