import Foundation

class ProjectListView: Drawable, ProjectAddedHandler, ProjectRemovedHandler {
    private let projectStore: ProjectStore
    private let backingList: VStack
    private var projectViews: [Int: ProjectView]
    private let selector: Selector
    
    init(projectStore: ProjectStore, selector: Selector) {
        self.projectStore = projectStore
        self.backingList = VStack{}
        self.projectViews = [:]
        self.selector = selector
        self.projectStore.whenAdded(call: self)
        self.projectStore.whenRemoved(call: self)
    }
    
    func projectAdded(_ project: Project) {
        let projectView = ProjectView(projectStore: projectStore, project: project, selector: selector)
        projectViews[project.id] = projectView
        backingList.addChild(projectView)
    }
    
    func projectRemoved(_ project: Project) {
        guard let projectView = projectViews[project.id] else {
            fatalError("removing project view when the view does not exist for project \(project.id)")
        }

        backingList.removeChild(projectView)
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        return backingList.draw(with: screenWriter, in: bounds, force: forced)
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        let willUpdate = backingList.update(with: cause, in: bounds)
        return willUpdate
    }
    
    func getMinimumSize() -> DrawSize {
        return backingList.getMinimumSize()
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return backingList.getDrawBounds(given: bounds, with: arrangeDirective)
    }
    
}
