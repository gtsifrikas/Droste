//
//  Cache+Switch.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation

public enum CacheSwitchResult {
    /// The first Cache of the switch
    case cacheA
    /// The second Cache of the switch
    case cacheB
}

public func switchCache<A: Cache, B: Cache>(cacheA: A,
                                             cacheB: B,
                                             switchClosure: @escaping (_ key: A.Key) -> CacheSwitchResult)
    -> CompositeCache<A.Key, A.Value> where A.Key == B.Key, A.Value == B.Value {
    return CompositeCache(
        get: { key in
            switch switchClosure(key) {
            case .cacheA:
                return cacheA.get(key)
            case .cacheB:
                return cacheB.get(key)
            }
        },
        set: { (value, key) in
            switch switchClosure(key) {
            case .cacheA:
                return cacheA.set(value, for: key)
            case .cacheB:
                return cacheB.set(value, for: key)
            }
        },
        clear: {
            cacheA.clear()
            cacheB.clear()
        }
    )
}
