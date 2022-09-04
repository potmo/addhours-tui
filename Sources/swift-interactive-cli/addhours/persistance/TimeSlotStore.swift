import Foundation
import Signals

class TimeSlotStore {
    private let database: Database
    private let dataDispatcher: DataDispatcher
    
    private let modified = Signal<([TimeSlot], ClosedRange<TimeInterval>)>()
    private var selectedRange: ClosedRange<TimeInterval>
    
    init(database: Database, dataDispatcher: DataDispatcher, selectedRange: ClosedRange<TimeInterval>) {
        self.database = database
        self.dataDispatcher = dataDispatcher
        self.selectedRange = selectedRange
        
        dataDispatcher.execute(try self.database.readTimeSlots(in: selectedRange), then: self.setTimeSlots)
    }
    
    private func setTimeSlots(timeSlots: [TimeSlot], in range: ClosedRange<TimeInterval>) {
        
        log.log("updated with \(timeSlots.count) timeslots in  range: \(range)")
        
        modified.fire((timeSlots, range))
        
    }
    
    func whenModified(call callback: TimeSlotModifiedHandler) {
        modified.subscribe(with: callback, callback: {callback.timeSlotsModified($0.0, in: $0.1)})
    }
    
}

protocol TimeSlotModifiedHandler: AnyObject {
    func timeSlotsModified(_ timeSlots: [TimeSlot], in range: ClosedRange<TimeInterval>) -> Void
}
