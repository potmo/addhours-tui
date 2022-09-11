import Foundation

/*
 
 Left ti right-ish lines
 
▕
｜
|
︳
⎹
⎸
▏

*/

class Timeline: Drawable, TimeSlotModifiedHandler {
    
    
    private let timeSlotStore: TimeSlotStore
    private let timer: BatchedTimer
    
    private var slotLine: HorizontalSectionLine<TimeSlot>
    private var unaccountedTimeLine: HorizontalSectionLine<Int?>
    private var unaccountedTimeLabel: ContainerChild<UnacountedTimeLabel>
    private var cursorLine: HorizontalSectionLine<Int?>
    private var timeNotchLine: TimeNotchLine
    private var backingContainer: VStack
    
    

    
    private let updateTick: TimeInterval = 60.0
    
    init(timeSlotStore: TimeSlotStore, timer: BatchedTimer) {
        
        self.timeSlotStore = timeSlotStore
        
        let slotLine = HorizontalSectionLine<TimeSlot>(visibleInterval: timeSlotStore.visibleRange)
        let unaccountedTimeLine = HorizontalSectionLine<Int?>(visibleInterval: timeSlotStore.visibleRange)
        let unaccountedTimeLabel = UnacountedTimeLabel().inContainer()
        let timeNotchLine = TimeNotchLine(range: timeSlotStore.visibleRange)
        let cursorLine = HorizontalSectionLine<Int?>(visibleInterval: timeSlotStore.visibleRange)
        
        self.backingContainer = VStack {
            slotLine
            unaccountedTimeLine
            timeNotchLine
            cursorLine
        }
        
        self.slotLine = slotLine
        self.unaccountedTimeLine = unaccountedTimeLine
        self.unaccountedTimeLabel = unaccountedTimeLabel
        self.timeNotchLine = timeNotchLine
        self.cursorLine = cursorLine
        
        self.timer = timer
        self.timeSlotStore.whenModified(call: self)
        self.timer.requestTick(in: updateTick)
    }
    
    func timeSlotsModified() {

        let sections = timeSlotStore.timeSlots.map { timeSlot in
            return SectionSlot(interval: timeSlot.range, color: timeSlot.project.color, data: timeSlot)
        }
        
        self.slotLine.setSections(sections)
        self.slotLine.setVisibleInterval(timeSlotStore.visibleRange)
        
        let unaccountedTimes = slotStore.allocator.getAllUnaccountedTimeUpToNow()
        self.unaccountedTimeLine.setVisibleInterval(timeSlotStore.visibleRange)
        self.unaccountedTimeLine.setSections(unaccountedTimes.map{
            SectionSlot(interval: $0, color: .brightRed, data: nil)
        })

        if let unaccountedRange = slotStore.allocator.getUnaccountedTimeFromCursorRestrictedToNow() {
            self.unaccountedTimeLabel.drawable.setUnaccountedTime(unaccountedRange)
        } else {
            if let cursor = slotStore.allocator.cursor {
                self.unaccountedTimeLabel.drawable.setUnaccountedTime(cursor)
            }else{
                self.unaccountedTimeLabel.drawable.setUnaccountedTime(0)
            }
        }

        self.timeNotchLine.setVisibleInterval(timeSlotStore.visibleRange)
        self.cursorLine.setVisibleInterval(timeSlotStore.visibleRange)
    }
    

    
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        let listDrew = backingContainer.draw(with: screenWriter, in: bounds, force: forced)
        updateTimeLabelBounds(in: bounds)
        unaccountedTimeLabel = unaccountedTimeLabel.draw(with: screenWriter, force: forced || listDrew == .drew)
        
        return listDrew || unaccountedTimeLabel.didDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
                
        if cause == .tick {
            timer.requestTick(in: updateTick)
        }
        
        switch cause {
            case .keyboard(.pressKey(code: "q", modifers: .ctrl)):
                slotStore.moveVisibleRange(by: -60*10)
                log.log("Moving timeline left")
            case .keyboard(.pressKey(code: "w", modifers: .ctrl)):
                slotStore.moveVisibleRange(by: 60*10)
                log.log("Moving timeline right")
            case .keyboard(.pressKey(code: "a", modifers: .ctrl)):
                slotStore.modifyVisibleRange(lowerBoundsBy: -60*60, upperBoundsBy: 60*60)
                log.log("zoom out timeline ")
            case .keyboard(.pressKey(code: "s", modifers: .ctrl)):
                slotStore.modifyVisibleRange(lowerBoundsBy: 60*60, upperBoundsBy: -60*60)
                log.log("zoom in timeline ")
            default:
                break
        }

        if let unaccountedRange = slotStore.allocator.getUnaccountedTimeFromCursorRestrictedToNow() {
            self.unaccountedTimeLabel.drawable.setUnaccountedTime(unaccountedRange)
        } else {
            if let cursor = slotStore.allocator.cursor {
                self.unaccountedTimeLabel.drawable.setUnaccountedTime(cursor)
            }else{
                self.unaccountedTimeLabel.drawable.setUnaccountedTime(0)
            }
            
        }
        
        let unaccountedTimes = slotStore.allocator.getAllUnaccountedTimeUpToNow()
        self.unaccountedTimeLine.setSections(unaccountedTimes.map{
            SectionSlot(interval: $0, color: .brightRed, data: nil)
        })
        
        if let cursor = slotStore.allocator.cursor {
            let cursorRange = slotStore.visibleRange.lowerBound...cursor
            self.cursorLine.setSections([SectionSlot(interval: cursorRange, color: .rgb(r: 0, g: 0, b: 200), data: nil)])
        }else{
            let cursorRange = slotStore.visibleRange
            self.cursorLine.setSections([SectionSlot(interval: cursorRange, color: .rgb(r: 200, g: 0, b: 0), data: nil)])
        }

        if let unaccountedRange = slotStore.allocator.getUnaccountedTimeFromCursorRestrictedToNow() {
            self.unaccountedTimeLabel.drawable.setUnaccountedTime(unaccountedRange)
        } else {
            if let cursor = slotStore.allocator.cursor {
                self.unaccountedTimeLabel.drawable.setUnaccountedTime(cursor)
            }else{
                self.unaccountedTimeLabel.drawable.setUnaccountedTime(0)
            }
        }
        
        updateTimeLabelBounds(in: bounds)
        let listUpdated = backingContainer.update(with: cause, in: bounds)
        
        return listUpdated || unaccountedTimeLabel.requiresRedraw
    }
    
    func updateTimeLabelBounds(in bounds: GlobalDrawBounds) {
        
        let size = unaccountedTimeLabel.drawable.getMinimumSize()
        
        //TODO: Figure this out with cursor
        let labelRange: ClosedRange<TimeInterval>
        if let unaccountedRange = slotStore.allocator.getUnaccountedTimeFromCursorRestrictedToNow() {
            labelRange = unaccountedRange
        } else if let cursor = slotStore.allocator.cursor {
            labelRange = cursor...cursor
        }else {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds())
            return
        }
        
        let labelContainerBounds = bounds.offset(columns: 0, rows: 1)
        
        let startColumn = -1 + self.unaccountedTimeLine.getColumnFor(time: labelRange.lowerBound, in: labelContainerBounds)
        let endColumn = 1 + self.unaccountedTimeLine.getColumnFor(time: labelRange.upperBound, in: labelContainerBounds)
        
        //TODO: Set style of tabel
        if bounds.column + bounds.width - endColumn > size.width {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds(column: endColumn,
                                                                              row: labelContainerBounds.row,
                                                                              width: size.width,
                                                                              height: size.height))
        } else if startColumn - bounds.column > size.width {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds(column: startColumn - size.width,
                                                                              row: labelContainerBounds.row,
                                                                              width: size.width,
                                                                              height: size.height))
        } else {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds(column: startColumn + 2,
                                                                              row: labelContainerBounds.row,
                                                                              width: size.width,
                                                                              height: size.height))
        }
        
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingContainer.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
    func getMinimumSize() -> DrawSize {
        return backingContainer.getMinimumSize()
    }
}
