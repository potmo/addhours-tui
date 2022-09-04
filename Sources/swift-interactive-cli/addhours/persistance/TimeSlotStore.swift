import Foundation
import Signals

class TimeSlotStore {
    private let database: Database
    private let dataDispatcher: DataDispatcher
    
    private let modified = Signal<Void>()
    private var selectedRange: ClosedRange<TimeInterval>
    private var cachedTimeSlots: [TimeSlot]
    
    var visibleRange: ClosedRange<TimeInterval> {
        return selectedRange
    }
    
    var timeSlots: [TimeSlot] {
        return cachedTimeSlots
    }
    
    init(database: Database, dataDispatcher: DataDispatcher, selectedRange: ClosedRange<TimeInterval>) {
        self.database = database
        self.dataDispatcher = dataDispatcher
        self.selectedRange = selectedRange
        self.cachedTimeSlots = []
        
        dataDispatcher.execute(try self.database.readTimeSlots(in: selectedRange), then: self.setTimeSlots)
    }
    
    private func setTimeSlots(timeSlots: [TimeSlot], in range: ClosedRange<TimeInterval>) {
        
        log.log("updated with \(timeSlots.count) timeslots in  range: \(range)")
        self.selectedRange = range
        self.cachedTimeSlots = timeSlots
        modified.fire()
        
    }
    
    func whenModified(call callback: TimeSlotModifiedHandler) {
        modified.subscribe(with: callback, callback: {callback.timeSlotsModified()})
    }
    
}

protocol TimeSlotModifiedHandler: AnyObject {
    func timeSlotsModified() -> Void
}
