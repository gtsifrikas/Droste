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
        let tsDictionary = Protected(resource: [Key: Observable<Value?>]())
        
        return CompositeCache(
            get: { (key) in
                var value: Observable<Value?>?
                
                value = tsDictionary.read()[key]
                
                guard value == nil else { return value! }
                
                value = self.get(key)
                    .do(onNext: { (_) in
                        tsDictionary
                            .mutate { exitingDictionary in
                                var new = exitingDictionary
                                new[key] = nil
                                return new
                        }
                    }, onError: { (_) in
                        tsDictionary
                            .mutate { exitingDictionary in
                                var new = exitingDictionary
                                new[key] = nil
                                return new
                        }
                    }, onCompleted: {
                        tsDictionary
                            .mutate { exitingDictionary in
                                var new = exitingDictionary
                                new[key] = nil
                                return new
                        }
                    }, onDispose: {
                        tsDictionary
                            .mutate { exitingDictionary in
                                var new = exitingDictionary
                                new[key] = nil
                                return new
                        }
                    })
                    .share()
                // all the interested parties for this particular resource will share a single subscription
                
                tsDictionary
                    .mutate { exitingDictionary in
                        var new = exitingDictionary
                        new[key] = value
                        return new
                }
                return value!
        },
            set: set,
            clear: clear
        )
    }
}
