//
// Created by George Tsifrikas on 14/06/2017.
// Copyright (c) 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class RetainTests: QuickSpec {
    override func spec() {
        weak var cache1: AsyncCacheFake<String, Int>!
        weak var cache2: AsyncCacheFake<String, Int>!
        var composedCache: CompositeCache<String, Int>!

        var scheduler: TestScheduler!
        var composedCacheObserver: TestableObserver<Int?>!

        beforeEach {
            let cache1Local = AsyncCacheFake<String, Int>()
            let cache2Local = AsyncCacheFake<String, Int>()
            cache1 = cache1Local
            cache2 = cache2Local
            composedCache = cache1Local + cache2Local

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
                    subscriptionDisposable = composedCache.get(key).subscribe(composedCacheObserver) as? Cancelable
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

            context("when retaining the composed cache variable") {
                it("should NOT release the individual caches which composite cache consists of") {
                    expect(cache1).toNot(beNil())
                    expect(cache2).toNot(beNil())
                }
            }

            context("when releasing the composed cache variable") {
                beforeEach {
                    scheduler.scheduleAt(150) {
                        composedCache = nil
                    }
                    scheduler.scheduleAt(200) {
                        subscriptionDisposable.dispose()
                    }
                    scheduler.start()
                }

                it("should release the individual caches which composite cache consists of") {
                    expect(composedCache).to(beNil())
                    expect(cache1).to(beNil())
                    expect(cache2).to(beNil())
                }
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
                    expect(composedCacheObserver.events.first?.value.element!).toEventually(equal(cache1ResponseValue))
                }

                it("should not emit stop events") {
                    expect(composedCacheObserver.events).toEventually(haveCount(1))
                    let cacheEvent = composedCacheObserver.events.first
                    expect(cacheEvent?.value.isStopEvent).to(beFalse())
                }

                it("should not have been disposed") {
                    expect(subscriptionDisposable.isDisposed).to(beFalse())
                }

                it("should not call get on the second cache") {
                    expect(cache2.numberOfTimesCalledGet).to(equal(0))
                }

                context("when retaining the composed cache variable") {
                    it("should NOT release the individual caches which composite cache consists of") {
                        expect(cache1).toNot(beNil())
                        expect(cache2).toNot(beNil())
                    }
                }

                context("when releasing the composed cache variable") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            composedCache = nil
                        }
                        scheduler.scheduleAt(200) {
                            subscriptionDisposable.dispose()
                        }
                        scheduler.start()
                    }

                    it("should release the individual caches which composite cache consists of") {
                        expect(composedCache).to(beNil())
                        expect(cache1).to(beNil())
                        expect(cache2).to(beNil())
                    }
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

                context("while retaining the composed cache variable") {
                    it("should NOT release the individual caches which composite cache consists of") {
                        expect(cache1).toNot(beNil())
                        expect(cache2).toNot(beNil())
                    }
                }

                context("when releasing the composed cache variable") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            composedCache = nil
                        }
                        scheduler.scheduleAt(200) {
                            subscriptionDisposable.dispose()
                        }
                        scheduler.start()
                    }

                    it("should release the individual caches which composite cache consists of") {
                        expect(cache1).to(beNil())
                        expect(cache2).to(beNil())
                    }
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
                    expect(cache2.numberOfTimesCalledGet).toEventually(equal(1))
                }

                it("should not do other get on the first cache") {
                    expect(cache1.numberOfTimesCalledGet).to(equal(1))
                }

                context("when retaining the composed cache variable") {
                    it("should NOT release the individual caches which composite cache consists of") {
                        expect(cache1).toNot(beNil())
                        expect(cache2).toNot(beNil())
                    }
                }

                context("when releasing the composed cache variable") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            composedCache = nil
                        }
                        scheduler.scheduleAt(200) {
                            subscriptionDisposable.dispose()
                        }
                        scheduler.start()
                    }

                    it("should release the individual caches which composite cache consists of") {
                        expect(composedCache).to(beNil())
                        expect(cache1).to(beNil())
                        expect(cache2).to(beNil())
                    }
                }

                context("when the second request succeeds") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            
                            DrosteTests.wait(timeout: .seconds(2), pollInterval: 0.1, until: { () -> Bool in
                                cache2.request != nil
                            }, then: {
                                composedCache = nil // This is done to implicitely test instance retaining while a request to the second cache is pending
                                cache2.request.on(.next(cache2ResponseValue))
                            })
                        }
                        scheduler.start()
                    }
                    
                    it("should call set in the lhs cache") {
                        expect(cache1.didCalledSetWithValue).toEventually(equal(cache2ResponseValue))
                    }

                    it("should emit the next value") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                    }

                    it("should pass the right value") {
                        expect(composedCacheObserver.events.first?.value.element ?? -1).toEventually(equal(cache2ResponseValue))
                    }

                    it("should not emit stop events") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                        expect(composedCacheObserver.events.first?.value.isStopEvent).to(beFalse())
                    }

                    it("should not have been disposed") {
                        expect(subscriptionDisposable.isDisposed).to(beFalse())
                    }

                    context("when retaining the composed cache variable") {
                        it("should NOT release the individual caches which composite cache consists of") {
                            expect(cache1).toNot(beNil())
                            expect(cache2).toNot(beNil())
                        }
                    }

                    context("when releasing the composed cache variable") {
                        beforeEach {
                            scheduler.scheduleAt(150) {
                                composedCache = nil
                            }
                            scheduler.scheduleAt(200) {
                                subscriptionDisposable.dispose()
                            }
                            scheduler.start()
                        }

                        it("should release the individual caches which composite cache consists of") {
                            expect(composedCache).to(beNil())
                            expect(cache1).to(beNil())
                            expect(cache2).to(beNil())
                        }
                    }
                }

                context("when the second request fails without error") {
                    beforeEach {
                        scheduler.scheduleAt(150) {
                            DrosteTests.wait(timeout: .seconds(2), pollInterval: 0.1, until: { () -> Bool in
                                cache2.request != nil
                            }, then: {
                                composedCache = nil // This is done to implicitely test instance retaining while a request to the second cache is pending
                                cache2.request.on(.next(nil))
                            })
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
                        let nextValueEvent = composedCacheObserver.events.first
                        expect(nextValueEvent?.value.element!).to(beNil())//the element is of type Optional<Optional<Int>> that's why the force unwrapping
                    }

                    context("when retaining the composed cache variable") {
                        it("should NOT release the individual caches which composite cache consists of") {
                            expect(cache1).toNot(beNil())
                            expect(cache2).toNot(beNil())
                        }
                    }

                    context("when releasing the composed cache variable") {
                        beforeEach {
                            scheduler.scheduleAt(150) {
                                composedCache = nil
                            }
                            scheduler.scheduleAt(200) {
                                subscriptionDisposable.dispose()
                            }
                            scheduler.start()
                        }

                        it("should release the individual caches which composite cache consists of") {
                            expect(composedCache).to(beNil())
                            expect(cache1).to(beNil())
                            expect(cache2).to(beNil())
                        }
                    }
                }
            }
        }
    }
}

func wait(timeout: DispatchTimeInterval = .seconds(2), pollInterval: TimeInterval = 1.0, file: FileString = #file, line: UInt = #line, until: @escaping () -> Bool, then: @escaping () -> Void) {
    let startedAt = Date()
    let backgroundQueue = DispatchQueue(label: "com.app.queue",
                                        qos: .userInitiated,
                                        target: nil)
    
    waitUntil(timeout: timeout, file: file, line: line) { done in
        backgroundQueue.async {
            while !until() {
                Thread.sleep(forTimeInterval: pollInterval)
                if abs(startedAt.timeIntervalSinceNow) > (timeout.toTimeInterval() ?? 0) {
                    done()
                    return
                }
            }
            DispatchQueue.main.async {
                then()
                done()
            }
        }
    }
}
