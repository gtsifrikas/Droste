//
// Created by George Tsifrikas on 13/06/2017.
// Copyright (c) 2017 George Tsifrikas. All rights reserved.
//
import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class CompositionTests: QuickSpec {
    override func spec() {

        var cache1: CacheFake<String, Int>!
        var cache2: CacheFake<String, Int>!
        var composedCache: CompositeCache<String, Int>!

        var scheduler: TestScheduler!
        var composedCacheObserver: TestableObserver<Int?>!

        beforeEach {
            cache1 = CacheFake<String, Int>()
            cache2 = CacheFake<String, Int>()
            composedCache = cache1 + cache2

            scheduler = TestScheduler(initialClock: 0)
            composedCacheObserver = scheduler.createObserver(Int?.self)
        }

        context("when calling get") {
            let key = "testKey"
            let cache1ResponseValue = 1
            let cache2ResponseValue = 2

            var subscriptionDisposable: Cancelable!

            beforeEach {
                scheduler.scheduleAt(100) {
                    subscriptionDisposable = composedCache.get(key).subscribe(composedCacheObserver) as! Cancelable
                }
                scheduler.start()
            }

            it("should not emit any event") {
                expect(composedCacheObserver.events).toEventually(haveCount(0))
            }

            it("should not have been disposed") {
                expect(subscriptionDisposable).toNot(beNil())
            }

            it("should call get on the first cache") {
                expect(cache1.numberOfTimesCalledGet).to(equal(1))
            }

            it("should not call get on the second cache") {
                expect(cache2.numberOfTimesCalledGet).to(equal(0))
            }

            context("when the first request succeeds") {
                beforeEach {
                    scheduler.scheduleAt(150) {
                        cache1.request.on(.next(cache1ResponseValue))
                    }
                    scheduler.start()
                }

                it("should emit next value") {
                    expect(composedCacheObserver.events).toEventually(haveCount(1))
                }

                it("should pass the right value") {
                    let nextValueEvent = composedCacheObserver.events.first!
                    expect(nextValueEvent.value.element ?? -1).to(equal(cache1ResponseValue))
                }

                it("should not emit stop events") {
                    expect(composedCacheObserver.events).toEventually(haveCount(1))
                    let cacheEvent = composedCacheObserver.events.first!
                    expect(cacheEvent.value.isStopEvent).to(beFalse())
                }

                it("should not have been disposed") {
                    expect(subscriptionDisposable.isDisposed).to(beFalse())
                }

                it("should not call get on the second cache") {
                    expect(cache2.numberOfTimesCalledGet).to(equal(0))
                }
            }

            context("when the request is canceled") {
                beforeEach {
                    scheduler.scheduleAt(150) {
                        subscriptionDisposable.dispose()
                    }
                    scheduler.start()
                }

                it("should not call any event") {
                    expect(composedCacheObserver.events).toEventually(haveCount(0))
                }

                it("should not have been disposed") {
                    expect(subscriptionDisposable.isDisposed).to(beTrue())
                }
            }

            context("when the first request fails without error") {
                beforeEach {
                    scheduler.scheduleAt(150) {
                        cache1.request.on(.next(nil))
                    }
                    scheduler.start()
                }

                it("should not emit any value") {
                    expect(composedCacheObserver.events).toEventually(haveCount(0))
                }

                it("should not have been disposed") {
                    expect(subscriptionDisposable.isDisposed).to(beFalse())
                }

                it("should call get on the second cache") {
                    expect(cache2.numberOfTimesCalledGet).to(equal(1))
                }

                it("should not do other get on the first cache") {
                    expect(cache1.numberOfTimesCalledGet).to(equal(1))
                }

                context("when the second request succeeds") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            cache2.request.on(.next(cache2ResponseValue))
                        }
                        scheduler.start()
                    }

                    it("should emit the next value") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                    }

                    it("should pass the right value") {
                        let nextValueEvent = composedCacheObserver.events.first!
                        expect(nextValueEvent.value.element ?? -1).to(equal(cache2ResponseValue))
                    }

                    it("should not emit stop events") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                        let cacheEvent = composedCacheObserver.events.first!
                        expect(cacheEvent.value.isStopEvent).to(beFalse())
                    }

                    it("should not have been disposed") {
                        expect(subscriptionDisposable.isDisposed).to(beFalse())
                    }
                    
                    it("should set the result to the rhs cache") {
                        expect(cache1.didCalledSetWithValue).to(equal(cache2ResponseValue))
                    }
                }

                context("when the second request fails without error") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            cache2.request.on(.next(nil))
                        }
                        scheduler.start()
                    }

                    it("should emit the next value") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                    }

                    it("should not have been disposed") {
                        expect(subscriptionDisposable.isDisposed).to(beFalse())
                    }

                    it("should not do other get calls on the first cache") {
                        expect(cache1.numberOfTimesCalledGet).to(equal(1))
                    }

                    it("should not do other get calls on the second cache") {
                        expect(cache2.numberOfTimesCalledGet).to(equal(1))
                    }

                    it("should pass nil") {
                        let nextValueEvent = composedCacheObserver.events.first!
                        expect(nextValueEvent.value.element!).to(beNil())//the element is of type Optional<Optional<Int>> that's why the force unwrapping
                    }
                }
            }
        }
    }
}
