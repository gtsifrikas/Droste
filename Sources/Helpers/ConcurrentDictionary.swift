//
//  ConcurrentDictionary.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 15/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation

class ConcurrentDictionary<KeyType, ValueType> : NSObject, Sequence, ExpressibleByDictionaryLiteral where KeyType: Hashable {
    // internal dictionary
    private var internalDictionary: [KeyType:ValueType]
    
    // queue modfications using a barrier and allow concurrent read operations
    private let queue = DispatchQueue(label: "custom.dictionary.concurrent", attributes: .concurrent)
    
    // count of key-value pairs in this dictionary
    var count: Int {
        var count = 0
        queue.sync {
            count = self.internalDictionary.count
        }
        return count
    }
    
    // safely get or set a copy of the internal dictionary value
    var dictionary: [KeyType:ValueType] {
        get {
            var dictionaryCopy: [KeyType: ValueType]?
            queue.sync {
                dictionaryCopy = self.dictionary
            }
            return dictionaryCopy!
        }
        
        set {
            let dictionaryCopy = newValue // create a local copy on the current thread
            queue.async {
                self.internalDictionary = dictionaryCopy
            }
        }
    }
    
    // initialize an empty dictionary
    override convenience init() {
        self.init( dictionary: [KeyType: ValueType]() )
    }
    
    // allow a concurrent dictionary to be initialized using a dictionary literal of form: [key1:value1, key2:value2, ...]
    convenience required init(dictionaryLiteral elements: (KeyType, ValueType)...) {
        var dictionary = [KeyType: ValueType]()
        
        for (key, value) in elements {
            dictionary[key] = value
        }
        
        self.init(dictionary: dictionary)
    }
    
    // initialize a concurrent dictionary from a copy of a standard dictionary
    init( dictionary: [KeyType:ValueType] ) {
        self.internalDictionary = dictionary
    }
    
    // provide subscript accessors
    subscript(key: KeyType) -> ValueType? {
        get {
            var value: ValueType?
            queue.sync {
                value = self.internalDictionary[key]
            }
            return value
        }
        
        set {
            setValue(value: newValue, forKey: key)
        }
    }
    
    // assign the specified value to the specified key
    func setValue(value: ValueType?, forKey key: KeyType) {
        // need to synchronize writes for consistent modifications
        queue.async(flags: .barrier) {
            self.internalDictionary[key] = value
        }
    }
    
    // remove the value associated with the specified key and return its value if any
    func removeValueForKey(key: KeyType) -> ValueType? {
        var oldValue: ValueType? = nil
        // need to synchronize removal for consistent modifications
        queue.sync(flags: .barrier) {
            oldValue = self.internalDictionary.removeValue(forKey: key)
        }
        return oldValue
    }
    
    // Iterator of key-value pairs suitable for for-in loops
    func makeIterator() -> DictionaryIterator<KeyType, ValueType> {
        var iterator: DictionaryIterator<KeyType, ValueType>!
        queue.sync {
            iterator = self.internalDictionary.makeIterator()
        }
        return iterator
    }
}
