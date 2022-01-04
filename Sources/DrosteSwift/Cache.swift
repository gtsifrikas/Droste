//
// Created by George Tsifrikas on 08/06/2017.
// Copyright (c) 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift

public protocol Cache {
    associatedtype Key
    associatedtype Value
    
    func get(_ key: Key) -> Observable<Value?>
    func set(_ value: Value, for key: Key) -> Observable<Void>
    func clear()
}
