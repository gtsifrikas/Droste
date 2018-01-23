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
    
    public func clear() {
        storage = [:]
    }
    
    //MARK: - Fetching
    private var storage: [K: Any] = [:]
    
    public func _getData<GenericValueType>(_ key: K) -> Observable<GenericValueType?> {
        return Observable.just(storage[key] as? GenericValueType)
    }
    
    public func _setData<GenericValueType>(_ value: GenericValueType, for key: K) -> Observable<Void> {
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
