//
//  Playground.playground
//  Droste
//
//  Copyright © 2016 George Tsifirkas. All rights reserved.
//

//: Playground - noun: a place where people can play

import UIKit
import RxSwift
import Droste
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let testCache = RamCache<String, String>()
let key = "Hello"
_ = testCache.set("World", for: key).publish().connect()
_ = testCache.get(key).subscribe(onNext: { (value: String) in
    let result = "\(key) \(value)"
})

DrosteCaches
    .imageCache(expires: .seconds(10))
    .get(URL(string: "https://dars.io/wp-content/uploads/2015/06/1435934506-50d83ee90498b3e4f9578a58ff8b5880.png")!)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: {(image) in
        let exampleImage = image
    })


let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvsection=0&titles=pizza&format=json")!

DrosteCaches
    .sharedJSONCache
    .get(url)
    .subscribe(onNext: { (jsonObject) in
        let object = jsonObject
    })

let date = Date()
let date2 = date.addingTimeInterval(10)

let diff = date2.timeIntervalSince1970 - date.timeIntervalSince1970

