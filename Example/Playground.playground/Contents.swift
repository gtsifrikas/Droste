//
//  Playground.playground
//  RxCache
//
//  Copyright © 2016 George Tsifirkas. All rights reserved.
//

//: Playground - noun: a place where people can play

import UIKit
import RxSwift
import RxCache

var str = "Hello, playground"

let testCache = RamCache<String, String>()

let key = "Hello"

_ = testCache.set("World", for: key).publish().connect()

_ = testCache.get(key).subscribe(onNext: { (value) in
    print("\(key) \(value!)")
})


