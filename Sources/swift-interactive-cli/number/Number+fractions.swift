import Foundation

extension Double {
    func string(maxFrac: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = maxFrac
        return formatter.string(from: NSNumber(value: self))!
    }
}
