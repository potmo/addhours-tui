import Foundation

extension Array where Element: Comparable {
    mutating func insertSorted(_ element: Element) {
        let index = self.firstIndex(where: { element < $0 })
        self.insert(element, at: index ?? self.endIndex)
    }
}

extension Array {
    mutating func insert(_ element: Element, whenElementFirstSatisfies comparator: (Element, Element) -> Bool) {
        let index = self.firstIndex(where: { return comparator(element, $0)})
        self.insert(element, at: index ?? self.endIndex)
    }
}
