import Foundation

infix operator °: MultiplicationPrecedence

func °(lhs: Int, rhs: Int) -> TimeInterval {
    return TimeInterval(lhs*60*60+rhs*60)
}

class Settings {
    var workingRangeForWeekdays: [Int:ClosedRange<TimeInterval>?] {
        return [
            1: 08°00...19°00, // sunday
            2: 08°00...19°00,
            3: 08°00...19°00,
            4: 08°00...19°00,
            5: 08°00...19°00,
            6: 08°00...19°00,
            7: 08°00...19°00,
        ]
    }
    
    func workingRangeForDayAtTime(_ time: TimeInterval) -> ClosedRange<TimeInterval>? {
        let date = time.date
        let weekDay = Calendar.current.component(.weekday, from: date)
        let secondsFromStartOfDay = workingRangeForWeekdays[weekDay] ?? nil
        
        guard let secondsFromStartOfDay = secondsFromStartOfDay else {
            return nil
        }
        let startTime = Calendar.current
            .startOfDay(for: date)
            .addingTimeInterval(secondsFromStartOfDay.lowerBound)
            .timeIntervalSince1970
        
        let endTime = Calendar.current
            .startOfDay(for: date)
            .addingTimeInterval(secondsFromStartOfDay.upperBound)
            .timeIntervalSince1970
        
        return startTime...endTime
    }
}
