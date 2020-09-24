//@dynamicMemberLookup
public struct ErrorInformation {
    @usableFromInline
    typealias RawKey = String
    
    @usableFromInline
    var infoDict: Dictionary<RawKey, Any> = [:]

    @inlinable
    public var isEmpty: Bool { infoDict.isEmpty }
    
    public init() {}

    @inlinable
    public init<T>(key: Key<T>, value: T) {
        set(value: value, for: key)
    }
    
    public mutating func set<T>(value: T, for key: Key<T>) {
        infoDict[key.rawKey] = value
    }
    
    public func value<T>(for key: Key<T>) -> T? {
        infoDict[key.rawKey] as? T
    }

    @inlinable
    public subscript<T>(_ key: Key<T>) -> T? {
        value(for: key)
    }

//    @inlinable
//    public subscript<T>(dynamicMember keyPath: KeyPath<Key<T>.Type, Key<T>>) -> T? {
//        value(for: Key.self[keyPath: keyPath])
//    }
}

extension ErrorInformation {
    public struct Key<T>: RawRepresentable, Hashable {
        public typealias RawValue = String
        
        public let rawValue: RawValue
        
        fileprivate var rawKey: ErrorInformation.RawKey {
            // Allow usages of the same `rawValue` but different Types `T`.
            // E.g. `Key<String>(rawValue: "abc")` and `Key<Int>(rawValue: "abc")`
            "\(rawValue).\(T.self)"
        }
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}
