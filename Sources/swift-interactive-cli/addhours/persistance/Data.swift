import Foundation


struct ProjectTab: Equatable {
    let id: Int
    let name: String
    let projects: [Int]
}

struct Project: Equatable {
    let id: Int
    let name: String
    let color: Color
    let children: [Int]
}


struct TimeSlot: Equatable {
    let id: Int
    let project: Project
    let range: ClosedRange<TimeInterval>
    let tags: [Tag]
}

struct Tag: Equatable {
    let id: Int
    let name: String
}
