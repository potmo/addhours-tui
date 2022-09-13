import Foundation

class SelectedProjectView: Drawable, ProjectModifiedHandler, TimeSlotModifiedHandler {
    
    private let projectStore: ProjectStore
    private let timeSlotStore: TimeSlotStore
    private var requiresRedraw: RequiresRedraw
    
    private var backingList: ContainerChild<VStack>
    private var project: Project?
    private var timeSlot: TimeSlot?
    
    
    init(projectStore: ProjectStore, timeSlotStore: TimeSlotStore) {
        self.projectStore = projectStore
        self.timeSlotStore = timeSlotStore
        self.requiresRedraw = .yes
        self.backingList = VStack({
            Text("Nothing selected")
        }).inContainer()
        
        timeSlotStore.whenModified(call: self)
    }
    
    private func select(_ timeSlot: TimeSlot) {
        deselectProject()
        deselectTimeSlot()
        
        backingList.drawable.setTo{
            HStack{
                Text("█", style: .color(timeSlot.project.color))
                Text(timeSlot.project.name)
                Text(timeSlot.range.timeString)
            }
        }
    }
    
    private func deselectTimeSlot() {
        if let timeSlot = timeSlot {
            self.timeSlot = nil
            log.log("deselected \(timeSlot.id)")
        }
    }
    
    func timeSlotsModified() {
        guard let timeSlot = self.timeSlot else {
            return
        }
        
        if let updatedTimeslot = timeSlotStore.timeSlots.first(where: {$0.id == timeSlot.id}) {
            select(updatedTimeslot)
        }else {
            deselectTimeSlot()
        }
        
    }
   
    private func select(_ project: Project) {
        
        deselectProject()
        deselectTimeSlot()
        
        log.log("selected \(project.name)")
        self.project = project
        
        projectStore.whenModified(project: project, call: self)
        
        backingList.drawable.setTo{
            
            HStack{
                Text("█", style: .color(project.color))
                Text("Name:")
                //TODO: Figure out changes here
                TextInput(text: project.name) { newText in
                    self.projectStore.update(name: newText, of: project)
                }
            }
            HStack{
                //TODO: Maybe not these spacings
                Button(text: "+10 min").onPress{ _ in
                    slotStore.add(10 * 60, to: project)
                }
                Text(" ")
                Button(text: "+30 min").onPress{ _ in
                    slotStore.add(30 * 60, to: project)
                }
                Text(" ")
                Button(text: "+1 hour").onPress{ _ in
                    slotStore.add(60 * 60, to: project)
                }
                Text(" ")
                Button(text: "+ALL").onPress{ _ in
                    slotStore.addAllUnaccountedTime(to: project)
                }
            }
        }
    }
    
    private func deselectProject() {
        if let project = self.project {
            self.projectStore.clearWhenModifiedFor(project: project, callback: self)
            self.project = nil
            log.log("deselected \(project.name)")
        }
    }
    
    func projectModified(_ project: Project) {
        select(project)
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        defer{
            requiresRedraw = .no
        }
        backingList = backingList.updateDrawBounds(with: bounds).draw(with: screenWriter, force: forced)
        return backingList.didDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        if case let .selection(.project(project)) = cause {
            select(project)
        } else if case let .selection(.timeSlot(timeslot)) = cause {
            select(timeslot)
        }
        
        backingList = backingList.updateDrawBounds(with: bounds).update(with: cause)
        return backingList.requiresRedraw || requiresRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        return backingList.drawable.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingList.drawable.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
