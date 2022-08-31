import Foundation
import SQLite

class Database {
    
    private let db: Connection
    let path = FileManager().currentDirectoryPath + "/addhours.sqlite3"
    
    
    init() {
        
        do {
            db = try Connection(path)
        } catch {
            fatalError("Failed creating connection: \(error)")
        }
        
        do {
            try self.setupTables()
        } catch {
            fatalError("Failed creating tables: \(error)")
        }
         
        
        do {
            let projects = Table("projects")
            let name = Expression<String>("name")
            let color = Expression<Int>("color")
            
            try db.run(projects.insert(name <- "Test 1", color <- 0xFF0000))
            try db.run(projects.insert(name <- "Test 2", color <- 0x00FF00))
            try db.run(projects.insert(name <- "Test 3", color <- 0x0000FF))
        } catch {
            fatalError("Failed creating test projects: \(error)")
        }
            
            /*
        do {
            let readProjects = try db.prepare(projects).map { element -> Project in
                let id = element[id]
                let name = element[name]
                let color = element[color]
                let parent = element[parent]
                return Project(id: id, name: name, color: color, parent: parent)
            }
            
            try db.run(tags.insert(name <- "Test Tag 1"))
            try db.run(tags.insert(name <- "Test Tag 2"))
            try db.run(tags.insert(name <- "Test Tag 3"))
            
            try db.run(timeslots.insert(project <- readProjects[0].id, startTime <- 100, endTime <- 200))
            
            let readTimeslots = try db.prepare(timeslots).map { element -> TimeSlot in
                let slotId = element[id]
                let project = element[project]
                let startTime = element[startTime]
                let endTime = element[endTime]
                
                let tagsIds = try db.prepare(timeslotTags.select(tag).filter(id == slotId)).map { element in
                    return element[id]
                }
                
                let tags = try db.prepare(tags.filter(tagsIds.contains(id))).map{ element -> Tag in
                    let id = element[id]
                    let name = element[name]
                    return Tag(id: id, name: name)
                }
                
                return TimeSlot(id: slotId, project: project, startTime: startTime, endTime: endTime, tags: tags)
            }
            
            log.log("loaded projects: \(readProjects)")
            log.log("loaded timeslots: \(readTimeslots)")
            
        } catch {
            fatalError("Failed creating database: \(error)")
        }
        
        */
        
    }
    
    private func setupTables() throws {
        let projects = Table("projects")
        let id = Expression<Int>("id")
        let name = Expression<String>("name")
        let color = Expression<Int>("color")
        let parent = Expression<Int?>("parent")
        try db.run(projects.create(temporary: true, ifNotExists: true){ table in
            table.column(id, primaryKey: .autoincrement)
            table.column(name)
            table.column(color)
            table.column(parent)
            table.foreignKey(parent, references: projects, id)
        })
        
        let timeslots = Table("timeslots")
        let project = Expression<Int>("project")
        let startTime = Expression<TimeInterval>("start_time")
        let endTime = Expression<TimeInterval>("end_time")
        try db.run(timeslots.create(temporary: true, ifNotExists: true){ table in
            table.column(id, primaryKey: .autoincrement)
            table.column(project)
            table.column(startTime)
            table.column(endTime)
        })
        
        let tags = Table("tags")
        try db.run(tags.create(temporary: true, ifNotExists: true){ table in
            table.column(id, primaryKey: .autoincrement)
            table.column(name)
        })
        
        let timeslotTags = Table("timeslot_tags")
        let timeslot = Expression<Int>("timeslot")
        let tag = Expression<Int>("tag")
        try db.run(timeslotTags.create(temporary: true, ifNotExists: true){ table in
            table.column(timeslot)
            table.column(tag)
            table.foreignKey(timeslot, references: timeslots, id)
            table.foreignKey(tag, references: tags, id)
        })
    }
    
    func readProjects() throws -> [Project] {
        let projects = Table("projects")
        let id = Expression<Int>("id")
        let name = Expression<String>("name")
        let color = Expression<Int>("color")
        let parent = Expression<Int?>("parent")
        
        let tempProjects = try db.prepare(projects).map { element -> TempProject in
            let id = element[id]
            let name = element[name]
            let color = element[color]
            let parent = element[parent]
            return TempProject(id: id, name: name, color: color, parent: parent)
        }
        
        /*
        let mappedProjects = tempProjects.filter{$0.parent == nil}
            .map{tempProject -> Project in
                let children = getChildrenOfProject(id: tempProject.id, tempProjects: tempProjects)
                return Project(id: tempProject.id,
                               name: tempProject.name,
                               color: Color.fromRGB(tempProject.color),
                               children: children)
            }*/
        
        let mappedProjects = tempProjects.map{ temp -> Project in
            let children = tempProjects.filter{$0.parent == temp.id}.map(\.id)
            return Project(id: temp.id, name: temp.name, color: Color.fromRGB(temp.color), children: children)
        }
        
        return mappedProjects
        
    }
    /*
    private func getChildrenOfProject(id: Int, tempProjects: [TempProject]) -> [Project] {
        let tempChildren = tempProjects.filter{ $0.parent == id}
        return tempChildren.map { tempProject in
            let children = getChildrenOfProject(id: tempProject.id, tempProjects: tempProjects)
            return Project(id: tempProject.id,
                           name: tempProject.name,
                           color: Color.fromRGB(tempProject.color),
                           children: children)
        }
    }*/
    
    func update(name: String, of project: Project) throws -> Project {    
        let projectsTable = Table("projects")
        let idColumn = Expression<Int>("id")
        let nameColumn = Expression<String>("name")
        
        try db.run(projectsTable.filter(idColumn == project.id).update(nameColumn <- name))
        
        return Project(id: project.id, name: name, color: project.color, children: project.children)
    }
    
    func addProject(name: String, color: Color) throws -> Project {
        let projectsTable = Table("projects")
        let nameColumn = Expression<String>("name")
        let colorColumn = Expression<Int>("color")
        let id = try db.run(projectsTable.insert(nameColumn <- name, colorColumn <- color.toInt()))
        
        return try readProject(id: Int(id))
    }
    
    func readProject(id: Int) throws -> Project {
        let projectsTable = Table("projects")
        let idColumn = Expression<Int>("id")
        let nameColumn = Expression<String>("name")
        let colorColumn = Expression<Int>("color")
        let parentColumn = Expression<Int?>("parent")
        guard let row = try db.pluck(projectsTable.filter(idColumn == id)) else {
            fatalError("tried to read project with id \(id) but it does not exist")
        }
        
        let id = row[idColumn]
        let name = row[nameColumn]
        let color = Color.fromRGB(row[colorColumn])
        
        let children = try db.prepare(projectsTable.select(idColumn).where(parentColumn == id)).map{ element in
            return element[idColumn]
        }
        
        return Project(id: id, name: name, color: color, children: children)
    }
    
    struct TempProject {
        let id: Int
        let name: String
        let color: Int
        let parent: Int?
    }
}

