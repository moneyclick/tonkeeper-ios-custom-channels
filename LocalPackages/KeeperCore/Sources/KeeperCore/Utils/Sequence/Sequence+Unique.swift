import Foundation

public extension Sequence {
    func unique<Value: Hashable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        var seen = Set<Value>()
        return filter { element in
            seen.insert(element[keyPath: keyPath]).inserted
        }
    }
}
