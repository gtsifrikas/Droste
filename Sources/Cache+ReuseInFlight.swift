//
//  Cache+ReuseInFlight.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

extension Cache where Key: Hashable {
    //if u have a slow cache and requesting for a resource is expensive you can use this method to concentrate all requests that are under the same key on a single shared subscription
    public func reuseInFlight() -> CompositeCache<Key, Value> {
        let dict = ConcurrentDictionary<Key, Observable<Value?>>()
        
        return CompositeCache(
            get: { (key) in
                return (dict[key] ?? ({
                    let newObservable: Observable<Value?> = self.get(key)
                        .do(onNext: { (_) in
                            dict[key] = nil
                        }, onError: { (_) in
                            dict[key] = nil
                        }, onCompleted: {
                            dict[key] = nil
                        }, onDispose: {
                            dict[key] = nil
                        })
                        .share()//all the interested parties for this particular resource will share a single subscription
                    dict[key] = newObservable
                    return newObservable
                })())!
        },
            set: set,
            clear: clear
        )
    }
}
