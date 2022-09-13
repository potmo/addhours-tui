import Foundation
import Signals

class Selector {
    
    public let commands = Signal<Selection>()
    
    func selectProject(_ project: Project) {
        DispatchQueue.main.async {
            self.commands.fire(.project(project: project))
        }
    }
    
    func selectTimeSlot(_ timeSlot: TimeSlot) {
        DispatchQueue.main.async {
            self.commands.fire(.timeSlot(timeSlot: timeSlot))
        }
    }
}


