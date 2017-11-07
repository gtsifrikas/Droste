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

RxCache is a composable cache library which leverates RxSwift's `Observable` for it's API.


- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [FAQ](#faq)
- [Credits](#credits)
- [License](#license)

<!-- <img src="Example/RxCache.gif" width="300"/> -->

## Example usage

```swift
import RxCache

let aDisposeBag = DisposeBag()

let networkFetcher = NetworkFetcher()
    .mapKeys { (url: URL) -> URLRequest in //map url to urlrequest
        return URLRequest(url: url)
    }
let diskCache = DiskCache<URL, NSData>()
let ramCache = RamCache<URL, NSData>()

let cache = ramCache + (diskCache + networkFetcher).reuseInFlight() 
//.reuseInFlight() concetrates all requests under one request if they have matching keys and the first request hasn't yet finished.

let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvsection=0&titles=pizza&format=json")!

cache.get(url)
.subscribe(onNext: { (data: NSData) in
    //use data
}).disposed(by: aDisposeBag)

```

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
