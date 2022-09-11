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
        
        //TODO: This needs a handle to the project store to know if the name or anything updated
        
        self.project = project
        
        backingList.drawable.setTo{
            
            HStack{
                Text("█", style: .color(project.color))
                Text("Name:")
                //TODO: Figure out changes here
                TextInput(text: Binding(wrappedValue: project.name))
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
