import Foundation
import Signals

class TimeSlotStore {
    private let database: Database
    private let dataDispatcher: DataDispatcher
    private let settings: Settings
    let allocator: TimeSlotAllocator
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
    
    var firstOccupiedTimeBeforeVisibleRange: TimeInterval? {
        return firstSlotBeforeSelectedRange
    }
    
    var firstOccupiedTimeAfterVisibleRange: TimeInterval? {
        return firstSlotAfterSelectedRange
    }
    
    init(database: Database, dataDispatcher: DataDispatcher, selectedRange: ClosedRange<TimeInterval>, settings: Settings) {
        self.database = database
        self.dataDispatcher = dataDispatcher
        self.selectedRange = selectedRange
        self.settings = settings
        self.cachedTimeSlots = []
        self.firstSlotBeforeSelectedRange = nil
        self.firstSlotAfterSelectedRange = nil
        self.allocator = TimeSlotAllocator()
        
        dataDispatcher.execute(try self.database.readTimeSlots(in: selectedRange), then: self.setTimeSlots)
    }
    
    func moveVisibleRange(by seconds: TimeInterval) {
        let newRange = (selectedRange.lowerBound+seconds)...(selectedRange.upperBound+seconds)
        dataDispatcher.execute(try self.database.readTimeSlots(in: newRange), then: self.setTimeSlots)
    }
    
    func modifyVisibleRange(lowerBoundsBy lowerSeconds: TimeInterval, upperBoundsBy upperSeconds: TimeInterval) {
        let lower = (selectedRange.lowerBound+lowerSeconds)
        let upper = (selectedRange.upperBound+upperSeconds)
        let middle = lower + (upper - lower) / 2
        let constrainedLower = min(lower, middle)
        let constrainedUpper = max(upper, middle)
        let newRange = constrainedLower...constrainedUpper
        if newRange.duration <= 0 {
            log.warning("blocked attempt to set visible range to less or equal to zero")
            return
        }
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
        self.allocator.update(timeSlotStore: self)
        
        modified.fire()
        
    }
    
    private func add(_ range: ClosedRange<TimeInterval>, to project: Project) {
        log.warning("adding \(range.timeString) to \(project.name)")
        dataDispatcher.execute(try self.database.addTimeSlot(in: range, for: project), then: self.addTimeSlot)
    }
    
    func add(_ seconds: TimeInterval, to project: Project) {
        // TODO: figure out how to undo/redo

        let range = allocator.getUnallocatedTimeFromCursorWith(duration: seconds)
        
        guard let range = range else {
            log.warning("can not add \(seconds) to \(project.name) at cursor")
            return 
        }
        
        add(range, to: project)
    }
    
    func addAllUnaccountedTime(to project: Project) {
        
        guard let range = allocator.getUnaccountedTimeFromCursorRestrictedToNow() else {
            log.warning("can not add all unaccounted time up to now to \(project.name) at cursor")
            return
        }
        
        add(range, to: project)
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
        allocator.update(timeSlotStore: self)
        
        modified.fire()
    }
    
    func whenModified(call callback: TimeSlotModifiedHandler) {
        modified.subscribe(with: callback, callback: {callback.timeSlotsModified()})
    }
    
}

protocol TimeSlotModifiedHandler: AnyObject {
    func timeSlotsModified() -> Void
}

