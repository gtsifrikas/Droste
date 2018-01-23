# Droste

<p align="left">
<a href="https://travis-ci.org/gtsifrikas/Droste"><img src="https://travis-ci.org/gtsifrikas/Droste.svg?branch=master" alt="Build status" /></a>
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift4-compatible-4BC51D.svg?style=flat" alt="Swift 4 compatible" /></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
<a href="https://cocoapods.org/pods/Droste"><img src="https://img.shields.io/cocoapods/v/Droste.svg" alt="CocoaPods compatible" /></a>
<a href="https://raw.githubusercontent.com/gtsifrikas/Droste/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

## Introduction

Droste is a lightweight composable caching library which leverages RxSwift's `Observable` for its API.

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
import Droste

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
import Droste

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
- [x] [Expirable caches](#expirable-caches)
- [x] [Combine caches easily (e.g. ram + disk + network)](#compose-caches)
- [x] [Because `.get` returns a `Cancelable` when you subscribe, you can cancel the request anytime](#cancel-requests)
- [x] [Combine different type of caches by mapping the value of caches using `.mapValues` and the key using `.mapKeys`](#map-values-and-keys)
- [x] When a cache succeds, informs all the higher level caches to set the new value
- [x] [Forward request to a lower level cache even if the value exists by using `.forwardRequest` operator](#forward-request)
- [x] [Create conditional combining of caches in runtime by using the `.switchCache` operator](#switch-cache)
- [x] [If the request is expensive you can consolidate requests that have the same key and the first request is not done yet, using the `.reuseInFlight` operator](#reuse-in-flight)
- [x] [Skip a cache at runtime depending on a condition, using the `.skipWhile` operator](#skip-while)
- [x] [Salient .get if you want the lack of a value to be treated as error](#salient-get)
- [x] Proper error handling through `Observable` chain sequence

### Out of the box
We provide some singletons of caches that are ready for use.
* `Caches.sharedJSONCache` takes URL and returns AnyObject which could either be an Array or a Dictionary depending on the endpoint's response
* `Caches.sharedDataCache` takes URL and returns NSData
* `Caches.sharedImageCache` takes URL and returns UIImage

### Compose caches
You can compose different types of caches, such as a composition of ram cache with a disk cache backed by a network fetcher.
To compose two or more caches, you can use `.compose` or `+` operator.

#### Example
```swift
let ramCache = RamCache<URL, NSData>()
let diskCache = DiskCache<URL, NSData>()

//First hit ram cache and in case of failure, hit the disk cache
let ramDiskCache = ramCache.compose(other: diskCache)

//Same composition example using the the overloaded `+` operator
let ramDiskCache = ramCache + diskCache
```

### Expirable caches
You can set expiry in each cache that supports it. DiskCache and RamCache both have out of the box support!
You can set an expiry in the following ways
```swift
// seconds from now
let ramCache = RamCache<URL, NSData>().expires(at: .seconds(30))

// or by explicitly setting a date 
let diskCache = DiskCache<URL, NSData>().expires(at: .date(Date(timeIntervalSince1970: 1516045540)))
```

Refreshing a resource after 5 minutes in both ram and disk cache.
```swift
let ramCache = RamCache<URL, NSData>().expires(at: .seconds(600))
let diskCache = DiskCache<URL, NSData>().expires(at: .seconds(600))

let dataCache = ramCache + diskCache + networkFetcher
```

### Cancel Requests
The fact that Droste leverages RxSwift's power, gives us some extra free functionality, such as canceling on-going requests.

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
aDisposeBag = DisposeBag() // this line will cancel the on-going request
```

#### Example with `flatMapLatest`
```swift
var aDisposeBag = DisposeBag()

let diskCache = DiskCache<URL, NSData>()
let networkFetcher = NetworkFetcher<URL, NSData>()

let diskNetworkCache = diskCache + networkFetcher

//Each time the user input emits a new value, it cancels the previous request in cache
someUserInput
    .flatMapLatest{ userInput in
        let key = exampleKey(from: userInput)
        return diskNetworkCache.get(key)
    }
    .subscribe(onNext: { response in

    }).disposed(by: aDisposeBag)
```

### Map Values and Keys
Different Caches may know about different types of values and keys. 
For example, you may have a RAM cache which uses a `String` type key and returns a `UIImage` type and a network fetcher (which is a type of cache) that uses URL as a key and responds with NSData.
If you would like to combine those two Caches you could not do it directly because their types do not match. 
You can map the values and key of a cache using `mapValues` and `mapKeys`.

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
More examples [here](https://github.com/gtsifrikas/Droste/blob/master/Sources/Caches.swift) 

### Forward request
In a scenario that you have composed two Caches together and you want the right hand side cache to always hit the network,  regardless if the first cache has succeded or not, you can use the forward request operator. By doing this, you are able to get the value from the first cache (if it exists) and followning the value from the second cache (if it exists). Also, note that the `.forwardRequest` operator, does not provide any guarantees on the order of the emissions to be aligned with the order of the composition.

#### Example
Let's assume that you have a screen which you want to load instantly and present a cached result for a short period of time,  but always update it when the network request succeeds.
```swift 
let screenCache = diskCache.forwardRequest() + networkFetcher

screenCache
    .get("withKey")
    .subscribe(onNext: {  screenViewModel
        self.viewModel = screenViewModel //if disk cache has a value this will be called twice
    })
```

### Switch cache
You can switch between Caches in runtime depending on the key used.

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
When you want to get an expensive resource from a cache/fetcher (e.g. `NetworkFetcher`), you can use `.reuseInFlight` operator to consolidate all requests that have the same key provided, when there is already an in-flight request for the same key. An example of this scenario is, a chat app that presents the same avatar multiple times on the screen and each avatar makes its own request from the cache. Using this operator means that only one request will be made and any subsequent requests will share the response of the first one.

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
* This operator is thread safe, meaning that you can dispatch the same request from multiple queues and it will work without any unexpected behaviors.

### Skip while
With `.skipWhile` operator you can, at runtime, to skip the cache depending on a given condition.

#### Example
```swift

let updateFromNetwork = true
let conditionedDiskCache = diskCache.skipWhile { key in
        let shouldSkip = (key == "a" && updateFromNetwork)
        return Observable(shouldSkip)
    }

let cache = conditionedDiskCache + networkFetcher

cache.get("a")
    .subscribe(onNext: { response in
        
    })
```

### Salient get
We have two `.get` operators which have a slightly different behavior.
* `func get(_ key: Key) -> Observable<Value?>` **Optional return value**

Using this operator, means that, if the cache does not have a value and *has not* thrown an error internally, then it will return a `nil` value. All thrown errors will propagate as expected.

* `func get(_ key: Key) -> Observable<Value>` **Non-optional return value**

Using this operator, means that, if the cache does not have a value, then it will throw a `CacheFetchError.valueNotFound` error. This operator *does not change* the expected behavior of other thrown errors.


## Requirements

* iOS 9.0+
* Xcode 8.0+

## Getting involved

* If you **want to contribute** please feel free to **submit PRs**.
* If you **have a feature request** please **open an issue**.
* If you **found a bug** or **need help** please **check older issues, [FAQ](#faq) and threads on [StackOverflow](http://stackoverflow.com/questions/tagged/Droste) (Tag 'Droste') before submitting an issue**.

Before contributing check the [CONTRIBUTING](https://github.com/gtsifrikas/Droste/blob/master/.github/CONTRIBUTING.md) file for more info.

If you use **Droste** in your app we would love to hear about it! Drop us a line on [Twitter](https://twitter.com/gtsifrikas).

## Examples

Follow these 3 steps to run the example project:

* Clone Droste repository
* Open Example/Example.xcworkspace workspace 
* Run *Example* project

You can also experiment and learn the using the *Droste Playground*, contained in *Example/Example.workspace* under Droste project.

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org/)

To install Droste, simply add the following line to your Podfile:

```ruby
pod 'Droste', '~> 0.1.1'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage)

To install Droste, simply add the following line to your Cartfile:

```ogdl
github "gtsifrikas/Droste" ~> 0.1.1
```

## Tasks for version 1.0
- [ ] 100% coverage
- [ ] Support macOS
- [ ] Support linux
- [ ] Update README to include custom Cache creation.
- [x] Come up with a api for TTL and support it in DiskCache and RamCache.

## Author

* [George Tsifrikas](https://github.com/gtsifrikas) ([@gtsifrikas](https://twitter.com/gtsifrikas))

# Changelog

See [CHANGELOG](CHANGELOG.md).
