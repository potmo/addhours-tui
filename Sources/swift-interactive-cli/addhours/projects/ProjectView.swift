import Foundation

class ProjectView: Drawable, ProjectModifiedHandler {
   
    private let projectStore: ProjectStore
    private let backingText: Text
    private var project: Project
    private let selector: Selector
    
    init(projectStore: ProjectStore, project: Project, selector: Selector) {
        self.projectStore = projectStore
        self.project = project
        self.backingText = Text(project.name, style: .backgroundColor(project.color))
        self.selector = selector
        
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
                selector.selectProject(self.project)
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
