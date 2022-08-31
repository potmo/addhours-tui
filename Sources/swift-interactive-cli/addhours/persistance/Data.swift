import Foundation


struct ProjectTab {
    let id: Int
    let name: String
    let projects: [Int]
}

struct Project{
    let id: Int
    let name: String
    let color: Color
    let children: [Int]
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
