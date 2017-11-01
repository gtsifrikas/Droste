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
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

var str = "Hello, playground"

let testCache = RamCache<String, String>()

let key = "Hello"

_ = testCache.set("World", for: key).publish().connect()

_ = testCache.get(key).subscribe(onNext: { (value: String) in
    print("\(key) \(value)")
})

Caches.sharedImageCache
    .get(URL(string: "https://dars.io/wp-content/uploads/2015/06/1435934506-50d83ee90498b3e4f9578a58ff8b5880.png")!)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: {(image) in
        let exampleImage = image
    })


let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvsection=0&titles=pizza&format=json")!
Caches
    .sharedJSONCache
    .get(url)
    .subscribe(onNext: { print($0 as Any) })

