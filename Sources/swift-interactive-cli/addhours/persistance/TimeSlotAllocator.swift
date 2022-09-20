import Foundation

class TimeSlotAllocator {
    
    private var visibleRange: ClosedRange<TimeInterval>
    private var unaccountedTime: [ClosedRange<TimeInterval>]
    private var unallocatedTime: [ClosedRange<TimeInterval>]
    
    //TODO: Make this variable
    var cursor: TimeInterval? {

        let lastUnaccounted = unaccountedTime.map(\.lowerBound).filter({visibleRange.contains($0)}).last
        let lastUnallocated = unallocatedTime.last?.lowerBound

        if let lastUnaccounted, let lastUnallocated {
            return max(lastUnaccounted, lastUnallocated)
        }

        if let lastUnaccounted {
            return lastUnaccounted
        }

        return lastUnallocated


    }
    
    init() {
        self.unaccountedTime = []
        self.unallocatedTime = []
        self.visibleRange = 0...0
    }
    
    func getAllUnaccountedTimeUpToNow() -> [ClosedRange<TimeInterval>] {
        let now = Date().timeIntervalSince1970
        return unaccountedTime
            .filter{$0.lowerBound < now}
            .map{
                return $0.lowerBound...min($0.upperBound, now)
            }
    }
    
    func getAllUnnacountedTimeAfterNow() -> [ClosedRange<TimeInterval>] {
        let now = Date().timeIntervalSince1970
        return unaccountedTime
            .filter{$0.upperBound > now}
            .map{
                return max(now,$0.lowerBound)...$0.upperBound
            }
    }
    
    
    func getUnaccountedTimeFromCursorRestrictedToNow() -> ClosedRange<TimeInterval>? {
        
        guard let cursor = cursor else {
            return nil
        }

        guard let candidate = unaccountedTime.first(where: { $0.contains(cursor)}) else {
            return nil
        }

        let now = Date().timeIntervalSince1970
        
        if candidate.contains(now) {
            return candidate.lowerBound...now
        }
        
        return candidate
    }
    
    func getUnallocatedTimeFromCursorWith(duration: TimeInterval) -> ClosedRange<TimeInterval>? {
        guard let cursor = cursor else {
            return nil
        }
        
        guard let candidate = unallocatedTime.first(where: { $0.contains(cursor)}) else {
            return nil
        }
        
        if candidate.contains(candidate.lowerBound + duration) {
            return candidate.lowerBound...candidate.lowerBound + duration
        }
        
        return candidate
        
    }
    
    func update(timeSlotStore: TimeSlotStore) {
        unaccountedTime = getAllUnaccountedTime(timeSlots: timeSlotStore.timeSlots,
                                                selectedRange: timeSlotStore.visibleRange,
                                                safeBefore: timeSlotStore.firstOccupiedTimeBeforeVisibleRange,
                                                safeAfter: timeSlotStore.firstOccupiedTimeAfterVisibleRange)
        
        unallocatedTime = getAllUnallocatedTimeInRange(timeSlots: timeSlotStore.timeSlots,
                                                       selectedRange: timeSlotStore.visibleRange,
                                                       safeBefore: timeSlotStore.firstOccupiedTimeBeforeVisibleRange,
                                                       safeAfter: timeSlotStore.firstOccupiedTimeAfterVisibleRange)
        
        visibleRange = timeSlotStore.visibleRange
    }
    
    private func getAllUnallocatedTimeInRange(timeSlots: [TimeSlot],
                                              selectedRange: ClosedRange<TimeInterval>,
                                              safeBefore: TimeInterval?,
                                              safeAfter: TimeInterval?) -> [ClosedRange<TimeInterval>] {

        let start = safeBefore ?? min(timeSlots.first?.range.lowerBound ?? selectedRange.lowerBound, selectedRange.lowerBound)
        let end = safeAfter ?? max(timeSlots.last?.range.upperBound ?? selectedRange.upperBound, selectedRange.upperBound)
        var timeRemaining = start...end
        var result: [ClosedRange<TimeInterval>] = []
        
        let slotTimeRanges = timeSlots.map(\.range).mergeAdjecent()
        
        for timeSlot in slotTimeRanges {
            let range = timeRemaining.lowerBound...timeSlot.lowerBound
            timeRemaining = timeSlot.upperBound...timeRemaining.upperBound
            if range.isEmpty {
             continue
            }
            result.append(range)
        }
        
        if timeRemaining.duration > 0 {
            result.append(timeRemaining)
        }
    
        
        return result
        
    }
    
    private func getAllUnaccountedTime(timeSlots: [TimeSlot],
                                       selectedRange: ClosedRange<TimeInterval>,
                                       safeBefore: TimeInterval?,
                                       safeAfter: TimeInterval?) -> [ClosedRange<TimeInterval>] {
        
        var accountedTimeInRange = timeSlots.map(\.range)
        
        // block time before
        if let firstSlotBeforeSelectedRange = safeBefore {
            let range = (firstSlotBeforeSelectedRange-60)...firstSlotBeforeSelectedRange
            accountedTimeInRange.insert(range, at: accountedTimeInRange.startIndex)
        }
        
        // block time after selected range
        if let firstSlotAfterSelectedRange = safeAfter {
            let range = firstSlotAfterSelectedRange...(firstSlotAfterSelectedRange+60)
            accountedTimeInRange.insert(range, at: accountedTimeInRange.endIndex)
        }
        
        accountedTimeInRange = accountedTimeInRange.mergeAdjecent()
        
        
        let fullDaysInRange = selectedRange.fullDaysInRange()
        
        let workTimesInRange = fullDaysInRange.map{ day -> ClosedRange<TimeInterval>? in
            let startOfDay = day.lowerBound
            let endOfDay = day.upperBound
            let center = startOfDay + (endOfDay - startOfDay) / 2
            let workingTime = settings.workingRangeForDayAtTime(center)
            
            return workingTime
            
        }.compactMap{$0}
        
        
        if workTimesInRange.isEmpty {
            return []
        }
        
        let mergedWorkTimesInRange = workTimesInRange.mergeAdjecent()
        
        
        let result = mergedWorkTimesInRange.map{ workTime -> [ClosedRange<TimeInterval>] in
            let accountedTime = accountedTimeInRange.filter{ $0.overlaps(workTime)}
            
            if accountedTime.isEmpty {
                return [workTime]
            }
            
            var solved = Array<ClosedRange<TimeInterval>>()
            var remainingWorkTime = workTime
            
            // this code assumes that the accounted time is only
            // those fully or partially overlapping the work time
            // and that they are sorted
            for accounted in accountedTime {
                
                // fully inside
                if remainingWorkTime.contains(accounted) {
                    // this is fully inside the remaining work time
                    // so the time left of the accounted is unaccounted
                    let unaccounted = remainingWorkTime.lowerBound...accounted.lowerBound
                    remainingWorkTime = accounted.upperBound...remainingWorkTime.upperBound
                    if unaccounted.duration > 0 {
                        solved.append(unaccounted)
                    }
                    continue
                }
                
                // overlaps left
                if accounted.contains(remainingWorkTime.lowerBound) {
                    // this accounted time is partially overlapping the beginning of the
                    // remaining work time so we just move ahead to where it is not overlapping
                    remainingWorkTime = accounted.upperBound...remainingWorkTime.upperBound
                    continue
                }
                
                if accounted.contains(remainingWorkTime.upperBound) {
                    let unaccounted = remainingWorkTime.lowerBound...accounted.lowerBound
                    if unaccounted.duration > 0 {
                        solved.append(unaccounted)
                    }
                    remainingWorkTime = accounted.lowerBound...accounted.lowerBound
                    continue
                }
                
            }
            
            if remainingWorkTime.duration > 0 {
                solved.append(remainingWorkTime)
            }
            
            return solved
            
        }.flatMap{$0}
        
        
        return result
        
    }
    
    

    
}
