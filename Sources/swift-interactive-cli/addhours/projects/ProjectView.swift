import Foundation

class ProjectView: Drawable, ProjectModifiedHandler {
   
    private let projectStore: ProjectStore
    private let backingText: Text
    private var project: Project
    
    init(projectStore: ProjectStore, project: Project) {
        self.projectStore = projectStore
        self.project = project
        self.backingText = Text(text: project.name, style: .backgroundColor(project.color))
        
        projectStore.whenModified(project: project, call: self)
    }
    
    func projectModified(_ project: Project) {
        self.project = project
        self.backingText.set(text: project.name).set(style: .backgroundColor(project.color))
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return backingText.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        if case let .mouse(.leftButtonUp(x, y,_,_,_)) = cause {
            if bounds.contains(x: x,y: y) {
                projectStore.update(name: "\(Int.random(in: 1..<1000))", of: project)
                self.backingText.set(style: .backgroundColor(.brightGreen)) // Temporary color
            }
        }
        
        return backingText.update(with: cause, in: bounds)
    }
    
    func getMinimumSize() -> DrawSize {
        return backingText.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingText.getDrawBounds(given: bounds, with: arrangeDirective)
    }
}
