//
//  Fetcher.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 12/06/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

public protocol Fetcher: Cache {}

extension Fetcher {
    public func set(_ value: Value, for key: Key) -> Observable<Void> {
        return Observable.just(())
    }
    
    public func clear() {}
}
