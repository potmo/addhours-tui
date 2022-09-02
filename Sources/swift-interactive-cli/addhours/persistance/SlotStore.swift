import Foundation

class SlotStore {
    private let database: Database
    private let dataDispatcher: DataDispatcher
    
    
    private var range = TimeInterval.todayWithTime(hour: 9, minute: 0)...TimeInterval.todayWithTime(hour: 18, minute: 0)
    
    init(database: Database, dataDispatcher: DataDispatcher) {
        self.database = database
        self.dataDispatcher = dataDispatcher
    }
}
