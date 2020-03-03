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
    .get(URL(string: "https://cdn.mos.cms.futurecdn.net/QaLNmZ8hSnJ8zUgGdPifTj.jpg")!)
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

