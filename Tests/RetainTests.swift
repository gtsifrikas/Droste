//
// Created by George Tsifrikas on 14/06/2017.
// Copyright (c) 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import RxCache

class RetainTests: QuickSpec {
    override func spec() {
        weak var cache1: CacheFake<String, Int>!
        weak var cache2: CacheFake<String, Int>!
        var composedCache: CompositeCache<String, Int>!

        var scheduler: TestScheduler!
        var composedCacheObserver: TestableObserver<Int?>!

        beforeEach {
            let cache1Local = CacheFake<String, Int>()
            let cache2Local = CacheFake<String, Int>()
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

            context("when retaining the composed cache variable") {
                it("should release the individual caches which composite cache consists of") {
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

                context("when retaining the composed cache variable") {
                    it("should release the individual caches which composite cache consists of") {
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

                context("when retaining the composed cache variable") {
                    it("should release the individual caches which composite cache consists of") {
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
                    expect(cache2.numberOfTimesCalledGet).to(equal(1))
                }

                it("should not do other get on the first cache") {
                    expect(cache1.numberOfTimesCalledGet).to(equal(1))
                }

                context("when retaining the composed cache variable") {
                    it("should release the individual caches which composite cache consists of") {
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

                    context("when retaining the composed cache variable") {
                        it("should release the individual caches which composite cache consists of") {
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

                    context("when retaining the composed cache variable") {
                        it("should release the individual caches which composite cache consists of") {
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
