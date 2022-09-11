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
         
       
        let project1:Project
        let project2:Project
        let project3:Project
        
        do {
            project1 = try addProject(name: "Test1", color: Color.rgb(r: 255, g: 0, b: 0))
            project2 = try addProject(name: "Test2", color: Color.rgb(r: 0, g: 255, b: 0))
            project3 = try addProject(name: "Test3", color: Color.rgb(r: 0, g: 0, b: 255))
        }catch {
            fatalError("Failed creating test projects: \(error)")
        }
        
        
        do {
            let range1 = TimeInterval.todayWithRange(start: (hour: 9, minute: 0), end: (hour: 9, minute: 30))
            let range2 = TimeInterval.todayWithRange(start: (hour: 9, minute: 30), end: (hour: 10, minute: 0))
            let range3 = TimeInterval.todayWithRange(start: (hour: 10, minute: 0), end: (hour: 11, minute: 0))
            //let range4 = TimeInterval.todayWithRange(start: (hour: 11, minute: 30), end: (hour: 17, minute: 20))
            
            _ = try addTimeSlot(in: range1, for: project1)
            _ = try addTimeSlot(in: range2, for: project2)
            _ = try addTimeSlot(in: range3, for: project3)
            //_ = try addTimeSlot(in: range4, for: project1)
        } catch {
            fatalError("Failed creating test timeslots: \(error)")
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
            table.column(id, primaryKey: true)
            table.column(project)
            table.column(startTime)
            table.column(endTime)
        })
        
        try db.run(timeslots.createIndex(project, ifNotExists: true))
        try db.run(timeslots.createIndex(startTime, ifNotExists: true))
        try db.run(timeslots.createIndex(endTime, ifNotExists: true))
        
        
        let tags = Table("tags")
        try db.run(tags.create(temporary: true, ifNotExists: true){ table in
            table.column(id, primaryKey: true)
            table.column(name)
        })
        
        let timeslotTags = Table("timeslot_tags")
        let timeslot = Expression<Int>("timeslot")
        let tag = Expression<Int>("tag")
        try db.run(timeslotTags.create(temporary: true, ifNotExists: true){ table in
            //TODO: Add indexes on tag and timeslot
            table.column(timeslot)
            table.column(tag)
            table.foreignKey(timeslot, references: timeslots, id)
            table.foreignKey(tag, references: tags, id)
        })
        
        try db.run(timeslotTags.createIndex(timeslot, ifNotExists: true))
        try db.run(timeslotTags.createIndex(tag, ifNotExists: true))
    }
    
    func readProjects() throws -> [Project] {
        let projects = Table("projects")
        let id = Expression<Int>("id")
        let name = Expression<String>("name")
        let color = Expression<Int>("color")
        let parent = Expression<Int?>("parent")
        
        let tempProjects = try db.prepare(projects.order(id, name)).map { element -> TempProject in
            let id = element[id]
            let name = element[name]
            let color = element[color]
            let parent = element[parent]
            return TempProject(id: id, name: name, color: color, parent: parent)
        }
        
        let mappedProjects = tempProjects.map{ temp -> Project in
            let children = tempProjects.filter{$0.parent == temp.id}.map(\.id)
            return Project(id: temp.id, name: temp.name, color: Color.fromRGB(temp.color), children: children)
        }
        
        return mappedProjects
        
    }
    
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
    
    func addTimeSlot(in range: ClosedRange<TimeInterval>, for project: Project) throws -> TimeSlot {
        let timeSlotsTable = Table("timeslots")
        let projectColumn = Expression<Int>("project")
        let startTimeColumn = Expression<TimeInterval>("start_time")
        let endTimeColumn = Expression<TimeInterval>("end_time")
        
        let id = try db.run(timeSlotsTable.insert(projectColumn <- project.id, startTimeColumn <- range.lowerBound, endTimeColumn <- range.upperBound))
        
        //TODO: Create set here??
        return TimeSlot(id: Int(id), project: project, range: range, tags: [])
        
    }
    
    func readTimeSlots(in range: ClosedRange<TimeInterval>) throws -> (timeSlots: [TimeSlot],
                                                                       range: ClosedRange<TimeInterval>,
                                                                       safeSpaceBefore: TimeInterval?,
                                                                       safeSpaceAfter: TimeInterval?) {
        let timeSlotsTable = Table("timeslots")
        let projectColumn = Expression<Int>("project")
        let startTimeColumn = Expression<TimeInterval>("start_time")
        let endTimeColumn = Expression<TimeInterval>("end_time")
        let idColumn = Expression<Int>("id")
        
        let query = timeSlotsTable.where(endTimeColumn >= range.lowerBound && startTimeColumn <= range.upperBound)
                                  .order(startTimeColumn)
        let rows = try db.prepareRowIterator(query)
        let timeSlots = try rows.map{ row -> TimeSlot in
            
            //TODO: It is probably possible to select the project as well right here
            // or maybe have it cached?
            let project = try readProject(id: row[projectColumn])
            
            //TODO: handle tags here
            return TimeSlot(id: row[idColumn],
                            project: project,
                            range: row[startTimeColumn]...row[endTimeColumn],
                            tags: [])
        }
        
        let safeSpace = try readSafeSpace(outside: range)
        
        return (timeSlots: timeSlots, range: range, safeSpaceBefore: safeSpace.before, safeSpaceAfter: safeSpace.after)
    }
    
    func readSafeSpace(outside range: ClosedRange<TimeInterval>) throws -> (before: TimeInterval?, after: TimeInterval?) {
        let timeSlotsTable = Table("timeslots")
        let startTimeColumn = Expression<TimeInterval>("start_time")
        let endTimeColumn = Expression<TimeInterval>("end_time")
        
        let firstBefore = try db.scalar(timeSlotsTable.select(endTimeColumn.max).where(endTimeColumn < range.lowerBound))
        let firstAfter = try db.scalar(timeSlotsTable.select(startTimeColumn.min).where(startTimeColumn > range.upperBound))
        
        return (before: firstBefore, after: firstAfter)
    }
    
    struct TempProject {
        let id: Int
        let name: String
        let color: Int
        let parent: Int?
    }
}

