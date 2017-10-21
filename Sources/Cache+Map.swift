//
//  Cache+Map.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

extension Cache {
    
    //this method allows to map the values from on cache using a transformer and allows to compose to virtually unrelated caches to a new cache, for example make a disk cache to know about jpeg images
    public func mapValues<V2>(f: @escaping (Value) throws -> V2, fInv: @escaping (V2) throws -> Value)
        -> CompositeCache<Key, V2> {
            return CompositeCache(
                get: { (key) -> Observable<V2?> in
                    return self.get(key).map { (originalValue: Value?) -> V2? in
                        if originalValue == nil {
                            return nil
                        } else {
                            return try f(originalValue!)
                        }
                    }
            },
                set: {value, key in
                    return  Observable.just(value).map { try fInv($0) }.flatMap { self.set($0, for: key) }
            },
                clear: clear
            )
    }
    //this method allows to map the keys from on cache using a transformer and allows to compose to virtually unrelated caches to a new cache, for example transform NSURLRequest to String
    public func mapKeys<K2>(fInv: @escaping (K2) throws -> Key)
        -> CompositeCache<K2, Value> {
            return CompositeCache(
                get: { key in
                    return Observable.just(key).map { try fInv($0) }.flatMap { self.get($0) }
            },
                set: {value, key in
                    return Observable.just(key).map { try fInv($0) }.flatMap { self.set(value, for: $0) }
            },
                clear: clear
            )
    }
}
