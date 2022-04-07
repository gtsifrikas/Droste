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
    
    private let cacheScheduler: SerialDispatchQueueScheduler
    private let cacheQueue: DispatchQueue
    private var storage: [K: Any]
    public init() {
        var generatedQueue: DispatchQueue?
        cacheScheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "com.droste.ram", serialQueueConfiguration: { (queue) in
            generatedQueue = queue// we are using the configuration block of SerialDispatchQueueScheduler to get the internal queue ref, doing so it ensures the timing of the disk operations are executed as intended
        })
        
        if let generatedQueue = generatedQueue {
            cacheQueue = generatedQueue
        } else {
            //fallback if for some reason we don't have a reference on the internal queue
            cacheQueue = DispatchQueue(label: "com.droste.ram", qos: .userInitiated)
        }
        storage = [:]
        cacheQueue.async { [weak self] in
            self?.storage = [:]
        }
    }
    
    public func clear() {
        cacheQueue.async {[weak self] in
            self?.storage = [:]
        }
    }
    
    //MARK: - Fetching
    public func _getData<GenericValueType>(_ key: K) -> Observable<GenericValueType?> {
        return Observable.create({ [weak self] (observer) -> Disposable in
            if let obj = self?.storage[key] as? GenericValueType {
                observer.onNext(obj)
                observer.onCompleted()
            } else {
                observer.onNext(nil)
                observer.onCompleted()
            }
            return Disposables.create()
        })
        .subscribeOn(cacheScheduler)
    }
    
    public func _setData<GenericValueType>(_ value: GenericValueType, for key: K) -> Observable<Void> {
        return Observable.create({ [weak self] (observer) -> Disposable in
            self?.storage[key] = value
            observer.on(.next(()))
            observer.onCompleted()
            return Disposables.create()
        })
        .subscribeOn(cacheScheduler)
    }
}
