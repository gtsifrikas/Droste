//
//  Normalize.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation

extension Cache {
    public func normalize() -> CompositeCache<Key, Value> {
        if let normalized = self as? CompositeCache<Key, Value> {
            return normalized
        } else {
            return CompositeCache<Key, Value>(
                get: get,
                set: set,
                clear: clear
            )
        }
    }
}
