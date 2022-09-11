import Foundation

extension Array {
    
    func appending(_ element: Element) -> [Element] {
        return self + [element]
    }
    
    func appending<S>(contentsOf newElements: S) -> [Element] where S: Collection, Element == S.Element {
        return self + newElements
    }
    
    func inserted<S>(contentsOf newElements: S, at i: Int) -> [Element] where S : Collection, Element == S.Element {
        var array = self
        array.insert(contentsOf: newElements, at: i)
        return array
    }
    
    func inserted(_ element: Element, at i: Int) -> [Element] {
        var array = self
        array.insert(element, at: i)
        return array
    }
    
    
}
