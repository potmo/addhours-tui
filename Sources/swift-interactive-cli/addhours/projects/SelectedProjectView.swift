import Foundation

class SelectedProjectView: Drawable {
    
    private let projectStore: ProjectStore
    private let timeSlotStore: TimeSlotStore
    private let timer: BatchedTimer
    
    private var backingList: ContainerChild<VStack>
    private var project: Project?
    
    init(projectStore: ProjectStore, timeSlotStore: TimeSlotStore, timer: BatchedTimer) {
        self.projectStore = projectStore
        self.timeSlotStore = timeSlotStore
        self.timer = timer
        self.backingList = VStack({
            Text("Nothing selected")
        }).inContainer()
        
    }
    
    func select(_ project: Project) {
        log.log("selected \(project.name)")
        
        self.project = project
        
        backingList.drawable.setChildren{
            
            HStack{
                Text("█", style: .color(project.color))
                Text("Name:")
                TextInput(text: Binding(wrappedValue: project.name))
            }
            HStack{
                Button(text: "Add 1")
                Button(text: "Add 2")
                Button(text: "Add 3")
                Button(text: "Add 4")
            }
        }
        
        // make sure we update now
        timer.requestTick(in: 0)
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        backingList = backingList.updateDrawBounds(with: bounds).draw(with: screenWriter, force: forced)
        return backingList.didDraw
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        backingList = backingList.updateDrawBounds(with: bounds).update(with: cause)
        return backingList.requiresRedraw
    }
    
    func getMinimumSize() -> DrawSize {
        return backingList.drawable.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingList.drawable.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
    
}
