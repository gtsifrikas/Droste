//
//  Cache+Compose.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

extension Cache {
    // this method allows to composite any number caches that conform to `Cache` protocol
    public func compose<B: Cache>(other: B)
        -> CompositeCache<Key, Value> where Key == B.Key, Value == B.Value {
            return CompositeCache(
                get: { (key) in
                    self.get(key)
                        .flatMap { (value) -> Observable<Value?> in
                            if value != nil {
                                return Observable.just(value)// if our "first" - lhs cache has the resource just return it
                            }
                            return other.get(key).flatMap({ (valueFromOther) -> Observable<Value?> in// the lhs didn't have the resource so ask the rhs
                                if let valueFromOther = valueFromOther {
                                    _ = self.set(valueFromOther, for: key).take(1).publish().connect()// set the value to the lhs cache so the next time to have the resource, using take(1) becacuse we want the disposable to be disposed after 1 emition, we do not chain it to the rest "get" observable to ensure that the cache will return the value as fast possible
                                }
                                return Observable.just(valueFromOther)
                            })
                    }
            },
                set: {value, key in
                    return Observable.zip(self.set(value, for: key), other.set(value, for: key)) { _ in }// set the value to both caches and wait for both to finish the operation
            }, clear: {
                self.clear()
                other.clear()
            }
            )
    }
}

public func +<A: Cache, B: Cache>(lhs: A, rhs: B) -> CompositeCache<A.Key, A.Value> where A.Key == B.Key, A.Value == B.Value {
    return lhs.compose(other: rhs)
}
