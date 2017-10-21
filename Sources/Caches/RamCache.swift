//
//  RamCache.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

public class RamCache<K, V>: Cache where K: Hashable {
    
    public typealias Key = K
    public typealias Value = V
    
    public init() {}
    
    private var storage: [K: V] = [:]
    
    public func get(_ key: K) -> Observable<V?> {
        return Observable.just(storage[key])
    }
    
    public func set(_ value: V, for key: K) -> Observable<Void> {
        return Observable.just((key, value))
            .flatMap { [weak self] (pair) -> Observable<Void> in
                guard let strongSelf = self else {
                    return Observable.just(())
                }
                strongSelf.storage[pair.0] = pair.1
                return Observable.just(())
        }
    }
    
    public func clear() {
        storage = [:]
    }
}
