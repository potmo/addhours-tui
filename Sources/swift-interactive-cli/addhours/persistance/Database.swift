import Foundation
import SQLite

class Database {
    
    var path:String {
        FileManager().currentDirectoryPath + "/addhours.sqlite3"
    }
    
    init() {
        
        do {
            let db = try Connection(path)
            
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
            
            
            
            try db.run(projects.insert(name <- "Test 1", color <- 0xFF0000))
            try db.run(projects.insert(name <- "Test 2", color <- 0x00FF00))
            try db.run(projects.insert(name <- "Test 3", color <- 0x0000FF))
            
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
        
    }
}

struct ProjectTab {
    let id: Int
    let name: String
    let projects: [Int]
}

struct Project{
    let id: Int
    let name: String
    let color: Int // Color?
    let parent: Int?
}


struct TimeSlot {
    let id: Int
    let project: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
    let tags: [Tag]
}

struct Tag {
    let id: Int
    let name: String
}
