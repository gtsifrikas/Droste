//
//  Cache+Salient.swift
//  Droste
//
//  Created by George Tsifrikas on 29/10/2017.
//

import RxSwift

enum CacheFetchError: Error {
    case valueNotFound
}

extension Cache {
    public func get(_ key: Key) -> Observable<Value> {
        return get(key)
            .map({ (value) -> Value in
                if let value = value {
                    return value
                }
                throw CacheFetchError.valueNotFound
            })
    }
}
