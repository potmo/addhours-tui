import Foundation
import Signals

class TimeSlotStore {
    private let database: Database
    private let dataDispatcher: DataDispatcher
    
    private let modified = Signal<Void>()
    private var selectedRange: ClosedRange<TimeInterval>
    private var cachedTimeSlots: [TimeSlot]
    private var firstSlotBeforeSelectedRange: TimeInterval?
    private var firstSlotAfterSelectedRange: TimeInterval?
    
    var visibleRange: ClosedRange<TimeInterval> {
        return selectedRange
    }
    
    var timeSlots: [TimeSlot] {
        return cachedTimeSlots
    }
    
    var currentUnaccountedTime: ClosedRange<TimeInterval> {
        
        //TODO: This needs to be working for the current day displayed
        let now = Date().timeIntervalSince1970
        
        //TODO: Make this configurable
        let dayStarts = TimeInterval.todayWithTime(hour: 09, minute: 00)
        //let dayEnds = TimeInterval.todayWithTime(hour: 18, minute: 00)
        
        let lowerBound: TimeInterval
        if let lastSlot = cachedTimeSlots.last {
            lowerBound = lastSlot.range.upperBound
        } else {
            lowerBound = min(dayStarts, now)
        }
         
        let upperBound = max(lowerBound, now)
        
        //TODO: the current unaccounted time could very logically go outside the
        // visible range. Now this business logic is here to prevent overlaps
        // when adding timeSlots might exist in database outside the visible range
        
        switch (firstSlotBeforeSelectedRange, firstSlotAfterSelectedRange) {
            case (.some(let before), .some(let after)):
                return (before...after).clamped(to: before...after)
            case (.none, .some(let after)):
                return (lowerBound...upperBound).clamped(to: ...after)
            case (.some(let before), .none):
                return (lowerBound...upperBound).clamped(to: before...)
            case (.none, .none):
                return lowerBound...upperBound
        }
    }
    
    init(database: Database, dataDispatcher: DataDispatcher, selectedRange: ClosedRange<TimeInterval>) {
        self.database = database
        self.dataDispatcher = dataDispatcher
        self.selectedRange = selectedRange
        self.cachedTimeSlots = []
        self.firstSlotBeforeSelectedRange = nil
        self.firstSlotAfterSelectedRange = nil
        
        dataDispatcher.execute(try self.database.readTimeSlots(in: selectedRange), then: self.setTimeSlots)
    }
    
    func moveVisibleRange(by seconds: TimeInterval) {
        let newRange = (selectedRange.lowerBound+seconds)...(selectedRange.upperBound+seconds)
        dataDispatcher.execute(try self.database.readTimeSlots(in: newRange), then: self.setTimeSlots)
    }
    
    private func setTimeSlots(timeSlots: [TimeSlot],
                              in range: ClosedRange<TimeInterval>,
                              safeRangeBefore: TimeInterval?,
                              safeRangeAfter: TimeInterval?) {
        
        log.log("updated with \(timeSlots.count) timeslots in  range: \(range)")
        self.selectedRange = range
        self.cachedTimeSlots = timeSlots
        self.firstSlotAfterSelectedRange = safeRangeBefore
        self.firstSlotAfterSelectedRange = safeRangeAfter
        modified.fire()
        
    }
    
    func add(_ seconds: TimeInterval, to project: Project) {
        // TODO: first we need to check if we have the entire range loaded so
        // we safely can add it

        
        //TOOD: Then we need to make sure nothing overlaps
        
        //TODO: We need to check what the unaccounted time really is
        
        //TODO:  we should probably try to figure out where the text (if any) slot is
        //before adding slots so we know what the upper bounds are
        // we need to go look in the database for that though
        
        //TODO:  we can also do the check to see if there will be any overlaps and adjust accordingly
        // in the database query but I'm not sure if that is easier
        
        //TODO: If a timeslot is touching the lower bound of the insertion range then we can modify that timeslot
        //TODO: If a timeslot is touching the upper bound of the insertion range then we can delete that and extend the inserted slot to its upper bound
        //TODO: marging is only valid if there are no tags or anything
        
        // TODO: figure out how to undo/redo
        
        let range = (currentUnaccountedTime.lowerBound...currentUnaccountedTime.lowerBound+seconds)
        dataDispatcher.execute(try self.database.addTimeSlot(in: range, for: project), then: self.addTimeSlot)
        
    }
    
    func addAllUnaccountedTime(to project: Project) {
        add(currentUnaccountedTime.duration, to: project)
    }
    
    func addTimeSlot(timeSlot: TimeSlot) {
        // add it in sorted
        
        if timeSlot.range.upperBound < visibleRange.lowerBound {
            if let firstSlotBeforeSelectedRange = firstSlotBeforeSelectedRange {
                self.firstSlotAfterSelectedRange = max(firstSlotBeforeSelectedRange, timeSlot.range.upperBound)
            }else{
                self.firstSlotAfterSelectedRange = timeSlot.range.upperBound
            }
        }
        
        if timeSlot.range.lowerBound > visibleRange.upperBound {
            if let firstSlotAfterSelectedRange = firstSlotAfterSelectedRange {
                self.firstSlotAfterSelectedRange = min(firstSlotAfterSelectedRange, timeSlot.range.lowerBound)
            } else {
                self.firstSlotAfterSelectedRange = timeSlot.range.lowerBound
            }
        }
        
        cachedTimeSlots.insert(timeSlot, whenElementFirstSatisfies: {$0.range.lowerBound < $1.range.lowerBound})
            
        modified.fire()
    }
    
    func whenModified(call callback: TimeSlotModifiedHandler) {
        modified.subscribe(with: callback, callback: {callback.timeSlotsModified()})
    }
    
}

protocol TimeSlotModifiedHandler: AnyObject {
    func timeSlotsModified() -> Void
}
