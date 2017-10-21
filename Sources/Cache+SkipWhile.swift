//
//  Cache+SkipWhile.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

extension Cache {
    
    public typealias ConditionClosure = (Key) -> Observable<Bool>
    
    public func skipWhile(_ condition: @escaping ConditionClosure) -> CompositeCache<Key, Value> {
            return CompositeCache(get: { key in
                return condition(key).flatMap({ (shouldSkip) -> Observable<Value?> in
                    if shouldSkip {
                        return Observable.just(nil)
                    } else {
                        return self.get(key)
                    }
                })
            },
            set: set,
            clear: clear
        )
    }
    
}
