import Foundation

extension TimeInterval {
    static func todayWithTime(hour: Int, minute: Int ) -> TimeInterval {
        let components = Calendar.current.dateComponents(in: Calendar.current.timeZone, from: Date())
        
        return DateComponents(calendar: components.calendar,
                       timeZone: components.timeZone,
                       era: components.era,
                       year: components.year,
                       month: components.month,
                       day: components.day,
                       hour: hour,
                       minute: minute,
                       second: 0,
                              nanosecond: 0).date!.timeIntervalSince1970
        
    }
}

extension TimeInterval {
    static func todayWithRange( start: (hour: Int, minute: Int), end: (hour: Int, minute: Int)) -> ClosedRange<TimeInterval> {
        return todayWithTime(hour: start.hour, minute: start.minute)...todayWithTime(hour: end.hour, minute: end.minute)
    }
}


extension ClosedRange where Bound == TimeInterval {
    var duration: TimeInterval {
        return self.upperBound - self.lowerBound
    }
}

extension ClosedRange {
    func intersection(with other: ClosedRange<Bound>) -> ClosedRange<Bound>? {
        let lowerBoundMax = Swift.max(self.lowerBound, other.lowerBound)
        let upperBoundMin = Swift.min(self.upperBound, other.upperBound)
        
        let lowerBeforeUpper = lowerBoundMax <= self.upperBound && lowerBoundMax <= other.upperBound
        let upperBeforeLower = upperBoundMin >= self.lowerBound && upperBoundMin >= other.lowerBound
        
        if lowerBeforeUpper && upperBeforeLower {
            return lowerBoundMax...upperBoundMin
        }
        
        return nil
    }
    
    func intersects(with other: ClosedRange<Bound>) -> Bool {
        self.overlaps(other)
    }
    
}

extension ClosedRange {
    public func contains(_ other: ClosedRange<Bound>) -> Bool {
        return self.contains(other.lowerBound) && self.contains(other.upperBound)
    }
}
