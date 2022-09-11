import Foundation

extension Calendar {
    public func startOfNextDay(for date: Date) -> Date {
        let start = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: .day, value: 1, to: start)!
    }
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day!
    }
    
    func numberOfHoursBetween(_ from: Date, and to: Date) -> Int {

        let numberOfDays = dateComponents([.hour], from: from, to: to)
        
        return numberOfDays.hour!
    }
}

extension Calendar {
    func nextFullHour(after date: Date) -> Date {
        let components = dateComponents([.hour, .minute], from: date)
        
        if components.minute != 0 {
            let fullHour = self.date(byAdding: .minute, value: -components.minute!, to: date)!
            let nextFullHour = self.date(byAdding: .hour, value: 1, to: fullHour)!
            return nextFullHour
        }
        
        return date
    }
}


extension TimeInterval{
    private static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    var timeString: String {
        return TimeInterval.timeFormatter.string(from: Date(timeIntervalSince1970: self))
    }
}

extension ClosedRange where Bound == TimeInterval {
    var timeString: String {
        return lowerBound.timeString + "..." + upperBound.timeString
    }
}

extension Array where Element == ClosedRange<TimeInterval> {
    func mergeAdjecent() -> [ClosedRange<TimeInterval>] {
        return self.reduce(Array<ClosedRange<TimeInterval>>()){ accumulated, current in
            guard let last = accumulated.last else {
                return [current]
            }
            if last.upperBound == current.lowerBound {
                let new = last.lowerBound...current.upperBound
                return accumulated.dropLast().appending(new)
            }
            return accumulated.appending(current)
        }
    }
}

extension ClosedRange where Bound == TimeInterval {
    func fullDaysInRange() -> [ClosedRange<TimeInterval>] {
        let numberOfDays = Calendar.current.numberOfDaysBetween(self.lowerBound.date, and: self.upperBound.date)
        let startDate = Calendar.current.startOfDay(for: self.lowerBound.date)
        return stride(from: 0, through: numberOfDays, by: 1).map{ i in
            let startOfDay = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
            let endOfDay = Calendar.current.startOfNextDay(for: startOfDay)
            return startOfDay.timeIntervalSince1970...endOfDay.timeIntervalSince1970
        }
        
    }
}

extension TimeInterval {
    var date: Date {
        return Date(timeIntervalSince1970: self)
    }
}

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

extension ClosedRange {
    public func partiallyContains(_ other: ClosedRange<Bound>) -> Bool {
        return self.contains(other.lowerBound) || self.contains(other.upperBound)
    }
}
