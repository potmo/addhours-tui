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
    
    private var slotLine: ContainerChild<HorizontalSectionLine<TimeSlot>>
    private var unaccountedTimeLine: ContainerChild<HorizontalSectionLine<Void?>>
    private var unaccountedTimeLabel: ContainerChild<UnacountedTimeLabel>
    private var timeNotchLine: ContainerChild<TimeNotchLine>
    
    init(timeSlotStore: TimeSlotStore, timer: BatchedTimer) {
        
        self.timeSlotStore = timeSlotStore
        
        self.slotLine = HorizontalSectionLine<TimeSlot>(visibleInterval: timeSlotStore.visibleRange).inContainer()
       
        self.unaccountedTimeLine = HorizontalSectionLine<Void?>(visibleInterval: timeSlotStore.visibleRange).inContainer()
        self.unaccountedTimeLabel = UnacountedTimeLabel().inContainer()

        self.timeNotchLine = TimeNotchLine(range: timeSlotStore.visibleRange).inContainer()

        self.timer = timer
        
        self.timeSlotStore.whenModified(call: self)
        
        self.timer.requestTick(in: 1.0)
    }
    
    func timeSlotsModified() {

        let sections = timeSlotStore.timeSlots.map { timeSlot in
            return SectionSlot(interval: timeSlot.range, color: timeSlot.project.color, data: timeSlot)
        }
        
        self.slotLine.drawable.setSections(sections)
        self.slotLine.drawable.setVisibleInterval(timeSlotStore.visibleRange)
        
        self.unaccountedTimeLine.drawable.setVisibleInterval(timeSlotStore.visibleRange)

        self.updateUnaccountedTimeLine()
        
        self.timeNotchLine.drawable.setVisibleInterval(timeSlotStore.visibleRange)
    }
    
    private func updateUnaccountedTimeLine() {
        let unaccountedTime = calculateUnaccountedTime(in: timeSlotStore.visibleRange, with: timeSlotStore.timeSlots)
        self.unaccountedTimeLabel.drawable.setUnaccountedTime(unaccountedTime: unaccountedTime)
        
        
        self.unaccountedTimeLine.drawable.setSections([
            SectionSlot(interval: unaccountedTime, color: .brightRed, data: nil)
        ])
        
    }
    
    func calculateUnaccountedTime(in range: ClosedRange<TimeInterval>, with slots: [TimeSlot]) -> ClosedRange<TimeInterval> {
        
        //TODO: This needs to be working for the current day displayed
        let now = Date().timeIntervalSince1970
        
        //TODO: Make this configurable
        let dayStarts = TimeInterval.todayWithTime(hour: 09, minute: 00)
        //let dayEnds = TimeInterval.todayWithTime(hour: 18, minute: 00)
        
        let lowerBound = min(slots.last?.range.upperBound ?? dayStarts, now)
        let upperBound = max(lowerBound, now)
        
        return lowerBound...upperBound
    }
    
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let startDateString = dateFormatter.string(from: Date(timeIntervalSince1970: timeSlotStore.visibleRange.lowerBound))
        let endDateString = dateFormatter.string(from: Date(timeIntervalSince1970: timeSlotStore.visibleRange.upperBound))
        
        screenWriter.moveTo(bounds.column, bounds.row)
        screenWriter.printLineAtCursor(startDateString)
        screenWriter.printLineAtCursor(Array(repeating: " ", count: bounds.width - startDateString.count - endDateString.count).joined(separator: ""))
        screenWriter.printLineAtCursor(endDateString)
        
        slotLine = slotLine.updateDrawBounds(with: bounds.offset(columns: 0, rows: 1).offsetSize(columns: 0, rows: -2))
                           .draw(with: screenWriter, force: forced)
        
        unaccountedTimeLine = unaccountedTimeLine.updateDrawBounds(with: bounds.offset(columns: 0, rows: 2).offsetSize(columns: 0, rows: -2))
            .draw(with: screenWriter, force: forced)
        
        updateTimeLabelBounds(in: bounds)
        unaccountedTimeLabel = unaccountedTimeLabel.draw(with: screenWriter, force: unaccountedTimeLine.didDraw == .drew || forced)
        
        timeNotchLine = timeNotchLine.draw(with: screenWriter, force: forced)
        
        return slotLine.didDraw || unaccountedTimeLine.didDraw || unaccountedTimeLabel.didDraw || timeNotchLine.didDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
                
        if cause == .tick {
            timer.requestTick(in: 1.0)
        }
        
        self.updateUnaccountedTimeLine()

        slotLine = slotLine.updateDrawBounds(with: bounds.offset(columns: 0, rows: 1))
            .update(with: cause)
        
        unaccountedTimeLine = unaccountedTimeLine.updateDrawBounds(with: bounds.offset(columns: 0, rows: 2))
            .update(with: cause)
        
        updateTimeLabelBounds(in: bounds)
        unaccountedTimeLabel = unaccountedTimeLabel.update(with: cause)
        
        timeNotchLine = timeNotchLine.updateDrawBounds(with: bounds.offset(columns: 0, rows: 3))
            .update(with: cause)
        
        return slotLine.requiresRedraw || unaccountedTimeLine.requiresRedraw || unaccountedTimeLabel.requiresRedraw || timeNotchLine.requiresRedraw
    }
    
    func updateTimeLabelBounds(in bounds: GlobalDrawBounds) {
        
        let size = unaccountedTimeLabel.drawable.getMinimumSize()
        let unaccountedTime = calculateUnaccountedTime(in: timeSlotStore.visibleRange, with: timeSlotStore.timeSlots)
        let startColumn = -1 + self.unaccountedTimeLine.drawable.getColumnFor(time: unaccountedTime.lowerBound, in: unaccountedTimeLine.drawBounds)
        let endColumn = 1 + self.unaccountedTimeLine.drawable.getColumnFor(time: unaccountedTime.upperBound, in: unaccountedTimeLine.drawBounds)
        
        //TODO: Set style of tabel
        if bounds.column + bounds.width - endColumn > size.width {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds(column: endColumn,
                                                                              row: unaccountedTimeLine.drawBounds.row,
                                                                              width: size.width,
                                                                              height: size.height))
        } else if startColumn - bounds.column > size.width {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds(column: startColumn - size.width,
                                                                              row: unaccountedTimeLine.drawBounds.row,
                                                                              width: size.width,
                                                                              height: size.height))
        } else {
            unaccountedTimeLabel = unaccountedTimeLabel.updateDrawBounds(with: GlobalDrawBounds(column: startColumn + 2,
                                                                              row: unaccountedTimeLine.drawBounds.row,
                                                                              width: size.width,
                                                                              height: size.height))
        }
        
        
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: DrawSize(width: bounds.width, height: 4), horizontally: .fill, vertically: .alignStart)
    }
    
    
    func getMinimumSize() -> DrawSize {
        let sizes = [
            slotLine.drawable.getMinimumSize(),
            unaccountedTimeLine.drawable.getMinimumSize(),
            timeNotchLine.drawable.getMinimumSize(),
        ]
        
        return DrawSize(width: sizes.map(\.width).max() ?? 0, height: sizes.map(\.height).reduce(0, +) + 1)
    }
}
