//
//  CompositeCache.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

public class CompositeCache<K, V>: Cache {
    
    public typealias Key = K
    public typealias Value = V
    
    typealias GetClosure = (K) -> Observable<V?>
    typealias SetClosure = (V, K) -> Observable<Void>
    typealias ClearClosure = () -> Void
    
    private var getFunc: GetClosure
    private var setFunc: SetClosure
    private var clearFunc: ClearClosure
    
    init(get: @escaping GetClosure,
         set: @escaping SetClosure,
         clear: @escaping ClearClosure) {
        getFunc = get
        setFunc = set
        clearFunc = clear
    }
    
    public func get(_ key: K) -> Observable<V?> {
        return getFunc(key)
    }
    
    public func set(_ value: V, for key: K) -> Observable<Void> {
        return setFunc(value, key)
    }
    
    public func clear() {
        clearFunc()
    }
}
