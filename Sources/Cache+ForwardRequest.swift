//
//  Cache+MissOnHit.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

public extension Cache {
    public func forwardRequest() -> CompositeCache<Key, Value> {
        return CompositeCache(
            get: { key in
                return self.get(key).startWith(nil)
        },
            set: set,
            clear: clear
        )
    }
}
