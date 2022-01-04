//
// Created by George Tsifrikas on 14/06/2017.
// Copyright (c) 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import DrosteSwift

class ReuseInFlightTests: QuickSpec {
    override func spec() {
        var cache1: CacheFake<String, Int>!
        var cache2: CacheFake<String, Int>!
        var composedCache: CompositeCache<String, Int>!
        
        var scheduler: TestScheduler!
        
        var composedCacheObserver: TestableObserver<Int?>!
        var composedCacheObserver2: TestableObserver<Int?>!
        var composedCacheObserver3: TestableObserver<Int?>!
        
        let key = "testKey"
        let cache1ResponseValue = 1
        beforeEach {
            cache1 = CacheFake<String, Int>()
            cache2 = CacheFake<String, Int>()
            composedCache = cache1.reuseInFlight() + cache2
            
            scheduler = TestScheduler(initialClock: 0)
            
            composedCacheObserver = scheduler.createObserver(Int?.self)
            composedCacheObserver2 = scheduler.createObserver(Int?.self)
            composedCacheObserver3 = scheduler.createObserver(Int?.self)
        }
        
        context("when calling get multiple times from multiple queues") {
            var subscriptionDisposable: Cancelable!
            var subscriptionDisposable2: Cancelable!
            var subscriptionDisposable3: Cancelable!
            
            beforeEach {
                scheduler.scheduleAt(100) {
                    subscriptionDisposable = composedCache.get(key)
                        .subscribe(composedCacheObserver) as? Cancelable
                    
                    let q1 = DispatchQueue(label: "queue1")
                    let q2 = DispatchQueue(label: "queue2")
                    
                    q1.async {
                        subscriptionDisposable2 = composedCache
                            .get(key).subscribe(composedCacheObserver2) as? Cancelable
                    }
                    
                    q2.async {
                        subscriptionDisposable3 = composedCache
                            .get(key).subscribe(composedCacheObserver3) as? Cancelable
                    }
                }
                scheduler.start()
                Thread.sleep(forTimeInterval: 1)//give time for subscriptions to be completed
            }
            
            it("should not emit any event") {
                expect(composedCacheObserver.events).toEventually(haveCount(0))
                expect(composedCacheObserver2.events).toEventually(haveCount(0))
                expect(composedCacheObserver3.events).toEventually(haveCount(0))
            }
            
            it("should not have been disposed") {
                expect(subscriptionDisposable).toNot(beNil())
                expect(subscriptionDisposable2).toNot(beNil())
                expect(subscriptionDisposable3).toNot(beNil())
            }
            
            it("should call get on the first cache") {
                expect(cache1.numberOfTimesCalledGet).toEventually(equal(1))
            }
            
            it("should not call get on the second cache") {
                expect(cache2.numberOfTimesCalledGet).toEventually(equal(0))
            }
            
            context("when the first request succeeds") {
                beforeEach {
                    scheduler.scheduleAt(150) {
                        cache1.request.on(.next(cache1ResponseValue))
                    }
                    scheduler.start()
                }
                
                it("should emit next value to both observers") {
                    expect(composedCacheObserver.events).toEventually(haveCount(1))
                    expect(composedCacheObserver2.events).toEventually(haveCount(1))
                    expect(composedCacheObserver3.events).toEventually(haveCount(1))
                }
                
                it("should pass the right value to all observers") {
                    let nextValueEvent = { () -> Recorded<RxSwift.Event<Int?>>? in
                        return composedCacheObserver.events.first
                    }
                    
                    expect(nextValueEvent()?.value.element).toEventually(equal(cache1ResponseValue))
                    
                    let nextValueEvent2 = {
                        return composedCacheObserver2.events.first
                    }
                    expect(nextValueEvent2()?.value.element).toEventually(equal(cache1ResponseValue))
                    
                    let nextValueEvent3 = {
                        return composedCacheObserver3.events.first
                    }
                    expect(nextValueEvent3()?.value.element).toEventually(equal(cache1ResponseValue))
                }
                
                it("should not emit stop events in none observers") {
                    expect(composedCacheObserver.events).toEventually(haveCount(1))
                    let nextValueEvent = {
                        return composedCacheObserver.events.first
                    }
                    expect(nextValueEvent()?.value.isStopEvent).toEventually(beFalse())
                    
                    expect(composedCacheObserver2.events).toEventually(haveCount(1))
                    let nextValueEvent2 = {
                        return composedCacheObserver.events.first
                    }
                    expect(nextValueEvent2()?.value.isStopEvent).toEventually(beFalse())
                    
                    let nextValueEvent3 = {
                        return composedCacheObserver3.events.first
                    }
                    expect(nextValueEvent3()?.value.isStopEvent).toEventually(beFalse())
                }
                
                it("should not have been disposed any subscription") {
                    expect(subscriptionDisposable.isDisposed).toEventually(beFalse())
                    expect(subscriptionDisposable2.isDisposed).toEventually(beFalse())
                    expect(subscriptionDisposable3.isDisposed).toEventually(beFalse())
                }
                
                it("should not call get on the second cache") {
                    expect(cache2.numberOfTimesCalledGet).to(equal(0))
                }
            }
        }
        
        context("when calling get once") {
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
                expect(cache1.numberOfTimesCalledGet).toEventually(equal(1))
            }
            
            it("should not call get on the second cache") {
                expect(cache2.numberOfTimesCalledGet).toEventually(equal(0))
            }
            
            context("when calling get with same key again") {
                var subscription2Disposable: Cancelable!
                
                beforeEach {
                    scheduler.scheduleAt(150) {
                        subscription2Disposable = composedCache.get(key).subscribe(composedCacheObserver2) as? Cancelable
                    }
                    scheduler.start()
                }
                
                it("should not emit any event") {
                    expect(composedCacheObserver.events).toEventually(haveCount(0))
                }
                
                it("should not have been disposed") {
                    expect(subscriptionDisposable).toNot(beNil())
                }
                
                it("should not call get on the first cache second time") {
                    expect(cache1.numberOfTimesCalledGet).toEventually(equal(1))
                }
                
                it("should not call get on the second cache") {
                    expect(cache2.numberOfTimesCalledGet).toEventually(equal(0))
                }
                
                context("when the first request succeeds") {
                    beforeEach {
                        scheduler.scheduleAt(200) {
                            cache1.request.on(.next(cache1ResponseValue))
                        }
                        scheduler.start()
                    }
                    
                    it("should emit next value to both observers") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                        expect(composedCacheObserver2.events).toEventually(haveCount(1))
                    }
                    
                    it("should pass the right value to both observers") {
                        let nextValueEvent = { () -> Recorded<RxSwift.Event<Int?>>? in
                            return composedCacheObserver.events.first
                        }
                        
                        expect(nextValueEvent()?.value.element!).toEventually(equal(cache1ResponseValue))
                        
                        let nextValueEvent2 = {
                            return composedCacheObserver2.events.first
                        }
                        expect(nextValueEvent2()?.value.element!).toEventually(equal(cache1ResponseValue))
                    }
                    
                    it("should not emit stop events in none observers") {
                        expect(composedCacheObserver.events).toEventually(haveCount(1))
                        let nextValueEvent = {
                            return composedCacheObserver.events.first
                        }
                        expect(nextValueEvent()?.value.isStopEvent).toEventually(beFalse())
                        
                        expect(composedCacheObserver2.events).toEventually(haveCount(1))
                        let nextValueEvent2 = {
                            return composedCacheObserver.events.first
                        }
                        expect(nextValueEvent2()?.value.isStopEvent).toEventually(beFalse())
                    }
                    
                    it("should not have been disposed any subscription") {
                        expect(subscriptionDisposable.isDisposed).toEventually(beFalse())
                        expect(subscription2Disposable.isDisposed).toEventually(beFalse())
                    }
                    
                    it("should not call get on the second cache") {
                        expect(cache2.numberOfTimesCalledGet).to(equal(0))
                    }
                    
                    context("when making the same call again") {
                        beforeEach {
                            scheduler.scheduleAt(250) {
                                subscription2Disposable = composedCache.get(key).subscribe(composedCacheObserver2) as? Cancelable
                            }
                            scheduler.start()
                        }
                        
                        it("should make a new request from the cache") {
                            expect(cache1.numberOfTimesCalledGet).toEventually(equal(2))
                        }
                        
                        it("should use the correct key") {
                            expect(cache1.didCallGetWithKey) == key
                        }
                    }
                }
            }
        }
    }
}
