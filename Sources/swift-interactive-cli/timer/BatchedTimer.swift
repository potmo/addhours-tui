import Foundation
import Signals


class BatchedTimer {
    private let batchLength: TimeInterval = 0.1
    private var scheduledTimes: [TimeInterval]
    private var timer: Timer?
    
    let commands: Signal<TimeInterval>
    
    init() {
        self.scheduledTimes = []
        self.commands = Signal()
    }
    
    func requestTick(at time: TimeInterval) -> Void {
        
        //log.log("request tick at      \(time)")
        // insert sorted
        let index = scheduledTimes.firstIndex(where: { time < $0 })
        scheduledTimes.insert(time, at: index ?? scheduledTimes.endIndex)
        
        // if no timer exist then schedule the timer for the first event
        if timer == nil || scheduledTimes.count == 1 {
            scheduleTimerAtFirstScheduledEvent()
            return
        }
        
        if let oldFireTime = scheduledTimes.first, oldFireTime < time {
            //log.log("timer already set before at: \(oldFireTime)")
            return
        }
        
        scheduleTimerAtFirstScheduledEvent()
    }
    
    func requestTick(in seconds: TimeInterval) {
        //log.log("request tick in: \(seconds)")
        self.requestTick(at: Date().timeIntervalSince1970 + seconds)
    }
    
    private func scheduleTimerAtFirstScheduledEvent() {
        
        if let timer = self.timer {
            //log.log("cancel timer")
            timer.invalidate()
            self.timer = nil
        }
        
        guard let firstEvent = scheduledTimes.first else {
            //log.log("no new scheduled times")
            return
        }
        
    
        //log.log("scheduling timer at: \(firstEvent) (\(firstEvent - Date().timeIntervalSince1970) from now")

        
        self.timer = Timer(fire: Date(timeIntervalSince1970: firstEvent),
                           interval: batchLength,
                           repeats: false) { timer in
            DispatchQueue.main.async {
                self.invokeTimer(timer: timer)
            }
        }
        
        RunLoop.main.add(self.timer!, forMode: .default)
        
    }
    
    private func invokeTimer(timer: Timer) -> Void {
        
        let firstTime = scheduledTimes.first!
        //log.log("fire timer at:       \(firstTime)")
        scheduledTimes.removeAll(where: {$0 < firstTime + batchLength})
        //log.log("\(scheduledTimes.count) events scheduled left")
        
        self.timer?.invalidate()
        self.timer = nil
        scheduleTimerAtFirstScheduledEvent()
        
        commands.fire(firstTime)
    }
    

}
