//
//  RamCache.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

public class RamCache<K, V>: ExpirableCache where K: Hashable {
    
    public typealias Key = K
    public typealias Value = V
    
    public init() {}
    
    public func set(_ value: V, for key: K) -> Observable<Void> {
        return setData(value, for: key)
    }
    
    public func get(_ key: K) -> Observable<V?> {
        return getData(key)
            .map({ (value: V?) -> V? in
                return value
            })
    }
    
    public func _getExpirableDTO(_ key: K) -> Observable<CacheExpirableDTO?> {
        return getData(key)
            .map({ (value: CacheExpirableDTO?) -> CacheExpirableDTO? in
                return value
            })
    }
    
    public func _setExpirableDTO(_ value: CacheExpirableDTO, for key: K) -> Observable<Void> {
        return setData(value, for: key)
    }
    
    public func clear() {
        storage = [:]
    }
    
    //MARK: - Fetching
    private var storage: [K: Any] = [:]
    
    private func getData<ValueType>(_ key: K) -> Observable<ValueType?> {
        return Observable.just(storage[key] as? ValueType)
    }
    
    private func setData(_ value: Any, for key: K) -> Observable<Void> {
        return Observable.just((key, value))
            .flatMap { [weak self] (pair) -> Observable<Void> in
                guard let strongSelf = self else {
                    return Observable.just(())
                }
                strongSelf.storage[pair.0] = pair.1
                return Observable.just(())
        }
    }
}
