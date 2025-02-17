//
//  LCDictionary.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 2/27/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud dictionary type.

 It is a wrapper of `Swift.Dictionary` type, used to store a dictionary value.
 */
@dynamicMemberLookup
public final class LCDictionary: NSObject, LCValue, LCValueExtension, Collection, ExpressibleByDictionaryLiteral {
    public typealias Key   = String
    public typealias Value = LCValue
    public typealias Index = DictionaryIndex<Key, Value>

    public private(set) var value: [Key: Value] = [:]

    var elementDidChange: ((Key, Value?) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(_ value: [Key: Value]) {
        self.init()
        self.value = value
    }

    public convenience init(_ value: [Key: LCValueConvertible]) {
        self.init()
        self.value = value.mapValue { value in value.lcValue }
    }

    /**
     Create copy of dictionary.

     - parameter dictionary: The dictionary to be copied.
     */
    public convenience init(_ dictionary: LCDictionary) {
        self.init()
        self.value = dictionary.value
    }

    public convenience required init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(Dictionary<Key, Value>(elements: elements))
    }

    public convenience init(
        application: LCApplication = LCApplication.default,
        unsafeObject: Any)
        throws
    {
        self.init()

        guard let object = unsafeObject as? [Key: Any] else {
            throw LCError(
                code: .malformedData,
                reason: "Failed to construct LCDictionary with non-dictionary object.")
        }

        value = try object.mapValue { value in
            try ObjectProfiler.shared.object(application: application, jsonValue: value)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        /* Note: We have to make type casting twice here, or it will crash for unknown reason.
                 It seems that it's a bug of Swift. */
        value = (aDecoder.decodeObject(forKey: "value") as? [String: AnyObject] as? [String: LCValue]) ?? [:]
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
    }

    public func copy(with zone: NSZone?) -> Any {
        return LCDictionary(self)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? LCDictionary {
            return object === self || object.value == value
        } else {
            return false
        }
    }

    public func makeIterator() -> DictionaryIterator<Key, Value> {
        return value.makeIterator()
    }

    public var startIndex: DictionaryIndex<Key, Value> {
        return value.startIndex
    }

    public var endIndex: DictionaryIndex<Key, Value> {
        return value.endIndex
    }

    public func index(after i: DictionaryIndex<Key, Value>) -> DictionaryIndex<Key, Value> {
        return value.index(after: i)
    }

    public subscript(position: DictionaryIndex<Key, Value>) -> (key: Key, value: Value) {
        return value[position]
    }

    public subscript(key: Key) -> LCValueConvertible? {
        get {
            return self.value[key]
        }
        set {
            let lcValue = newValue?.lcValue
            self.value[key] = lcValue
            self.elementDidChange?(key, lcValue)
        }
    }

    public subscript(dynamicMember key: String) -> LCValueConvertible? {
        get {
            return self[key]
        }
        set {
            self[key] = newValue
        }
    }

    /**
     Removes the given key and its associated value from dictionary.

     - parameter key: The key to remove along with its associated value.

     - returns: The value that was removed, or `nil` if the key was not found.
     */
    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        return value.removeValue(forKey: key)
    }
    
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        return value.removeAll(keepingCapacity: keepCapacity)
    }

    public func set(_ key: String, _ value: LCValue?) {
        self.value[key] = value
    }

    public var jsonValue: Any {
        return value.compactMapValue { value in value.jsonValue }
    }

    public var rawValue: Any {
        let v: [String: Any] = self.value.mapValue { value in value.rawValue }
        return v
    }

    var lconValue: Any? {
        return value.compactMapValue { value in (value as? LCValueExtension)?.lconValue }
    }
    
    static func instance(application: LCApplication) -> LCValue {
        return self.init([:])
    }

    func forEachChild(_ body: (_ child: LCValue) throws -> Void) rethrows {
        try forEach { (_, element) in try body(element) }
    }

    func add(_ other: LCValue) throws -> LCValue {
        throw LCError(code: .invalidType, reason: "Object cannot be added.")
    }

    func concatenate(_ other: LCValue, unique: Bool) throws -> LCValue {
        throw LCError(code: .invalidType, reason: "Object cannot be concatenated.")
    }

    func differ(_ other: LCValue) throws -> LCValue {
        throw LCError(code: .invalidType, reason: "Object cannot be differed.")
    }
}
