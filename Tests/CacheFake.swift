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

class CacheFake<K, V>: Cache {

    typealias Key = K
    typealias Value = V

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
