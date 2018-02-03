//
//  CacheFake.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 13/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift
import Droste


class CacheFake<K, V>: Cache, ExpirableCache {
    
    typealias Key = K
    typealias Value = V

    var genericDataRequest: PublishSubject<Any?>!
    var numberOfTimesCalledGenericDataGet = 0//CacheDTO
    var didCallGenericDataGetWithKey: K?
    
    func _getData<GenericValueType>(_ key: K) -> Observable<GenericValueType?> {
        numberOfTimesCalledGenericDataGet += 1
        genericDataRequest = PublishSubject()
        queueUsedForTheLastCall = currentQueueSpecific()
        didCallGenericDataGetWithKey = key
        return genericDataRequest.map({ $0 as? GenericValueType })
    }

    
    var numberOfTimesCalledGenericDataSet = 0
    var didCalledGenericDataSetWithKey: K?
    var didCalledGenericDataSetWithValue: Any?
    
    func _setData<GenericValueType>(_ value: GenericValueType, for key: K) -> Observable<Void> {
        numberOfTimesCalledGenericDataSet += 1
        didCalledGenericDataSetWithKey = key
        didCalledGenericDataSetWithValue = value
        queueUsedForTheLastCall = currentQueueSpecific()
        return Observable.just(())
    }
    
    var queueUsedForTheLastCall: UnsafeMutableRawPointer!

    var request: PublishSubject<V?>!
    var numberOfTimesCalledGet = 0
    var numberOfTimesCalledSet = 0
    var numberOfTimesCalledClear = 0

    var didCalledSetWithKey: K?
    var didCalledSetWithValue: V?

    var didCallGetWithKey: K?

    func get(_ key: K) -> Observable<V?> {
        numberOfTimesCalledGet += 1
        request = PublishSubject<V?>()
        queueUsedForTheLastCall = currentQueueSpecific()
        didCallGetWithKey = key
        return request.asObservable()
    }

    func set(_ value: V, for key: K) -> Observable<Void> {
        numberOfTimesCalledSet += 1
        didCalledSetWithKey = key
        didCalledSetWithValue = value
        queueUsedForTheLastCall = currentQueueSpecific()
        return Observable.just(())
    }

    func clear() {
        numberOfTimesCalledClear += 1
        queueUsedForTheLastCall = currentQueueSpecific()
    }
}
var kCurrentQueue = DispatchSpecificKey<UnsafeMutableRawPointer>()
func currentQueueSpecific() -> UnsafeMutableRawPointer! {
    return DispatchQueue.getSpecific(key: kCurrentQueue)
}
