import Foundation

extension ClosedRange where Bound: Comparable {
 
    func clamped(to range: PartialRangeFrom<Bound>) -> ClosedRange<Bound> {
        return Swift.max(self.lowerBound, range.lowerBound)...self.upperBound
    }
    
    func clamped(to range: PartialRangeThrough<Bound>) -> ClosedRange<Bound> {
        return self.lowerBound...Swift.min(self.upperBound, range.upperBound)
    }
}
