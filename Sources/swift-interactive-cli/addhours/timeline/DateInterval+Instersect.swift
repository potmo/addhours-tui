import Foundation

extension DateInterval {
    func contains(_ dateInterval: DateInterval)-> Bool {
        return self.contains(dateInterval.start) && self.contains(dateInterval.end)
    }
}
