# RxCache

<p align="left">
<a href="https://travis-ci.org/gtsifrikas/RxCache"><img src="https://travis-ci.org/gtsifrikas/RxCache.svg?branch=master" alt="Build status" /></a>
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift4-compatible-4BC51D.svg?style=flat" alt="Swift 4 compatible" /></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
<a href="https://cocoapods.org/pods/XLActionController"><img src="https://img.shields.io/cocoapods/v/RxCache.svg" alt="CocoaPods compatible" /></a>
<a href="https://raw.githubusercontent.com/gtsifrikas/RxCache/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

## Introduction

RxCache is a lightweight composable cache library which leverages RxSwift's `Observable` for it's API.

- [Example usage](#example-usage)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [FAQ](#faq)
- [Credits](#credits)
- [License](#license)

## Example usage

### Using out of the box caches
```swift
import RxCache

let aDisposeBag = DisposeBag()
let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvsection=0&titles=pizza&format=json")!

Caches
    .sharedJSONCache
    .get(url)
    .subscribe(onNext: { jsonObject in
        //use jsonObject
    }).disposed(by: aDisposeBag)

```

### Or composing your own cache
```swift
import RxCache

let aDisposeBag = DisposeBag()
let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvsection=0&titles=pizza&format=json")!

let networkFetcher = NetworkFetcher()
    .mapKeys { (url: URL) -> URLRequest in //map url to urlrequest
        return URLRequest(url: url)
    }

let diskCache = DiskCache<URL, NSData>()
let ramCache = RamCache<URL, NSData>()

let dataCache = ramCache + (diskCache + networkFetcher).reuseInFlight() 
let jsonCache = dataCache
            .mapValues(f: { (data) -> AnyObject in
                //convert NSData to json object
                return try JSONSerialization.jsonObject(with: data as Data, options: [.allowFragments]) as AnyObject
            }, fInv: { (object) -> NSData in
                //convert json object to NSData
                return try JSONSerialization.data(withJSONObject: object, options: []) as NSData
            })

jsonCache
    .get(url)
    .subscribe(onNext: { jsonObject in
        //use jsonObject
    }).disposed(by: aDisposeBag)

```

## Features
- [x] [Out of the box support for UIImage, JSON, NSData](#out-of-the-box)
- [x] [Combine caches easily (e.g. ram + disk + network)](#compose-caches)
- [x] [Because `.get` returns a `Cancelable` when you subscribe, you can cancel the request anytime](#cancel-requests)
- [x] [Combine different type of caches by mapping the value of caches using `.mapValues` and the key using `.mapKeys`](#map-values-and-keys)
- [x] When a cache succeds, informs all the higher level caches to set the new value
- [x] [Forward request to a lower level cache even if the value exists by using `.forwardRequest` operator](#forward-request)
- [x] [Create conditional combining of caches in runtime by using the `.switchCache` operator](#switch-cache)
- [x] [If the request is expensive you can consolidate requests that have the same key and the first request is not done yet, using the `.reuseInFlight` operator](#reuse-in-flight)
- [x] [Skip a cache in runtime depending on a condition, using the `.skipWhile` operator](#skip-while)
- [x] [Proper error handling through `Observable` chain](#error-handling)
- [x] [Salient .get if you want the lack of a value to be treated as error](#salient-get)

### Out of the box
We provide some singletons of caches that are ready for use.
* `Caches.sharedJSONCache` takes URL and returns AnyObject which could be either array or dictionary depending of the endpoint's response
* `Caches.sharedDataCache` takes URL and returns NSData
* `Caches.sharedImageCache` takes URL and returns UIImage

### Compose caches
You can compose different type of caches, such as a composition of ram cache with a disk cache backed by a network fetcher.
To compose two caches or more you can use the `.compose` or `+` operator.

#### Example
```swift
let ramCache = RamCache<URL, NSData>()
let diskCache = DiskCache<URL, NSData>()

//First asks the ram cache and if it fails it asks the disk cache
let ramDiskCache = ramCache.compose(other: diskCache)

//The same but using the + operator
let ramDiskCache = ramCache + diskCache
```

### Cancel Requests
The fact that RxCache is written using RxSwift it give us some extra functionality such as canceling requests.

#### Example with `DisposeBag`
```swift
var aDisposeBag = DisposeBag()

let diskCache = DiskCache<URL, NSData>()
let networkFetcher = NetworkFetcher<URL, NSData>()

let diskNetworkCache = diskCache + networkFetcher
diskNetworkCache
    .get("a url")
    .subscribe(onNext: { response in

    }).disposed(by: aDisposeBag)

//...later
aDisposeBag = DisposeBag() // this line will cancel the request
```

#### Example with `flatMapLatest`
```swift
var aDisposeBag = DisposeBag()

let diskCache = DiskCache<URL, NSData>()
let networkFetcher = NetworkFetcher<URL, NSData>()

let diskNetworkCache = diskCache + networkFetcher

//every time the user input gives a new value it cancels the previous request in cache
someUserInput
    .flatMapLatest{ userInput in
        let key = exampleKey(from: userInput)
        return diskNetworkCache.get(key)
    }
    .subscribe(onNext: { response in

    }).disposed(by: aDisposeBag)
```

### Map Values and Keys
Different caches may know about different type of values and keys. 
For example you may have a ram cache that needs a `String` type key and returns a `UIImage` type and a network fetcher (which is a type of cache) which knows about URL as a key and NSData as a response type.
If you want to combine these two caches you couldn't do it directly because their types doesn't much. 
You can map the values and key of a cache using mapValues and mapKeys

#### Example
```swift
let networkFetcher = NetworkFetcher()      //Value = NSData, Key = URLRequest
let ramCache = RamCache<String, UIImage>() //Value = UIImage, Key = String

let imageNetworkFetcher = networkFetcher  //Value = UIImage, Key = String
                            .mapKeys { (urlString: String) -> URLRequest in
                                let url = URL(string: urlString)!
                                return URLRequest(url: url)
                            }
                            .mapValues(
                                f: { (data) -> UIImage in
                                    return UIImage(data: data as Data)!
                                }) { (image) -> NSData in
                                    return UIImagePNGRepresentation(image) as! NSData
                                }

let imageRamNetworkCache = ramCache + imageNetworkFetcher //Value = UIImage, Key = String

imageRamNetworkCache.get("http://an.image.url.png")
    .subscribe(onNext: { image in
        //in a view controller context
        self.imageView.image = image
    }).disposed(by: disposeBag)
```
More examples [here](https://github.com/gtsifrikas/RxCache/blob/feature/README/Sources/Caches.swift) 

### Forward request
In a scenario that you have composed two caches together and you want the right hand side cache to always get request regardless if the first cache has succeded or not you can use the forward request operator. By doing this you will get the value from the first cache (if exists) and the value from the second cache (if exists). Also note that the `.forwardRequest` does not guarantee the timing of the emissions to be aligned with the order of the composition.

#### Example
Let's assume that you have a screen that you want to load instantly in spite showing wrong values for a short period of time but always update it's values from the network.
```swift 
let screenCache = diskCache.forwardRequest() + networkFetcher

screenCache
    .get("withKey")
    .subscribe(onNext: {  screenViewModel
        self.viewModel = screenViewModel //if disk cache has a value this will be called two times
    })
```

### Switch cache
You can switch between caches in runtime depending on the key used.

#### Example
```swift
let cacheA = ...
let cacheB = ...
let cache = switchCache(cacheA: cacheA, cacheB: cacheB) { (key) -> CacheSwitchResult in
    if key == "Hello" {
        return .cacheA
    }
    if key == "World" {
        return .cacheB
    }
}

cache.get("Hello") //this will use cacheA
cache.get("World") //this will use cacheB
```

### Reuse in flight
When you want to get a resource that is expensive from a cache/fetcher, for example NetworkFetcher, you can use `.reuseInFlight` operator to consolidate all requests that have the same key provided that the first request has not yet finished. A example of this scenario is a chat app that has the same avatar multiple times on the screen and each avatar makes it's own request from the cache. Using this operator actually will be only one request for the image which all avatars will share it's response.

#### Example
```swift
let cache = memoryCache + (diskCache + networkFetcher).reuseInFlight()

cache.get("profileImage")
    .subscribe(onNext: { image in
        avatar1.image = image
    })

//a short while after, before the first request finished
cache.get("profileImage")
    .subscribe(onNext: { image in
        avatar2.image = image //this will get the same response as the above without making a second request
    }
```

#### Notes
* Keys must be `Hashable`.
* This operator is thread safe, means that you can do the same request dispatched from multiple queues and it will work without any unexpected behavior.

## Requirements

* iOS 9.0+
* Xcode 8.0+

## Getting involved

* If you **want to contribute** please feel free to **submit pull requests**.
* If you **have a feature request** please **open an issue**.
* If you **found a bug** or **need help** please **check older issues, [FAQ](#faq) and threads on [StackOverflow](http://stackoverflow.com/questions/tagged/RxCache) (Tag 'RxCache') before submitting an issue**.

Before contribute check the [CONTRIBUTING](https://github.com/gtsifrikas/RxCache/blob/master/CONTRIBUTING.md) file for more info.

If you use **RxCache** in your app We would love to hear about it! Drop us a line on [Twitter](https://twitter.com/gtsifrikas).

## Examples

Follow these 3 steps to run Example project: clone RxCache repository, open Example/Example.xcworkspace workspace and run the *Example* project.

You can also experiment and learn with the *RxCache Playground* which is contained in *RxCache.workspace*.

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects.

To install RxCache, simply add the following line to your Podfile:

```ruby
pod 'RxCache', '~> 0.1'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralized dependency manager for Cocoa.

To install RxCache, simply add the following line to your Cartfile:

```ogdl
github "gtsifrikas/RxCache" ~> 1.0
```

## Author

* [George Tsifrikas](https://github.com/gtsifrikas) ([@gtsifrikas](https://twitter.com/gtsifrikas))

## FAQ

### How to .....

You can do it by conforming to .....

# Changelog

See [CHANGELOG](CHANGELOG.md).
