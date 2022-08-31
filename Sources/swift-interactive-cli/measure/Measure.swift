import Foundation

func measure(_ block: ()->Void) -> TimeInterval {
    
    let start = ProcessInfo.processInfo.systemUptime
    block()
    let end = ProcessInfo.processInfo.systemUptime
    let diff = end - start
    return diff
}
