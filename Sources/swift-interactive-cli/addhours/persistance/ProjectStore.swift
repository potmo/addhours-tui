import Foundation
import Signals

class ProjectStore {
    private let database: Database
    private let dataDispatcher: DataDispatcher
    
    private let added = Signal<Project>()
    private let removed = Signal<Project>()
    private let modified = Signal<Project>()
    
    private var projects: [Int: ProjectSignalContainer]
    
    init(database: Database, dataDispatcher: DataDispatcher) {
        self.database = database
        self.dataDispatcher = dataDispatcher
        self.projects = [:]
        dataDispatcher.execute(self.database.readProjects, then: self.setProjects(projects:))
    }
    
    private func setProjects(projects: [Project]) {
        
        log.log("updated with \(projects.count) projects")
        
        self.projects.map(\.value).forEach{ container in
            removed.fire(container.project)
            container.signal.cancelAllSubscriptions()
        }
        
        self.projects = Dictionary(uniqueKeysWithValues: projects.map{ project in
            return (project.id, ProjectSignalContainer(project: project))
        })
        
        self.projects.map(\.value.project).forEach{ project in
            added.fire(project)
        }
    }
    
    func update(name: String, of project: Project) {
        dataDispatcher.execute({try self.database.update(name: name, of: project)}, then: { project in
            guard let container = self.projects[project.id] else {
                fatalError("tried to update project but it has never been seen: \(project.id)")
            }
            container.project = project
            container.signal.fire(project)
        })
    }
    
    
    func whenAdded(call callback: ProjectAddedHandler) {
        added.subscribe(with: callback, callback: callback.projectAdded(_:))
        
        for project in projects.values.map(\.project) {
            callback.projectAdded(project)
        }
    }
    
    func whenRemoved(call callback: ProjectRemovedHandler) {
        removed.subscribe(with: callback, callback: callback.projectRemoved(_:))
    }
    
    func whenModified(project: Project, call callback: ProjectModifiedHandler) {
        guard let container = projects[project.id] else {
            fatalError("the project does not exist")
        }
        container.signal.subscribe(with: callback, callback: callback.projectModified(_:))
    }
    
    class ProjectSignalContainer {
        let signal: Signal<Project>
        var project: Project
        init(project: Project) {
            self.project = project
            self.signal = Signal<Project>()
        }
    }
}

protocol ProjectAddedHandler: AnyObject {
    func projectAdded(_ project: Project) -> Void
}

protocol ProjectRemovedHandler: AnyObject {
    func projectRemoved(_ project: Project) -> Void
}

protocol ProjectModifiedHandler: AnyObject {
    func projectModified(_ project: Project) -> Void
}
