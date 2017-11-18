//
//  SwitchTests.swift
//  DrosteTests
//
//  Created by George Tsifrikas on 30/10/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class SwitchTests: QuickSpec {
    override func spec() {
        describe("The switch operator") {
            var cache1: CacheFake<String, Int>!
            var cache2: CacheFake<String, Int>!
            var finalCache: CompositeCache<String, Int>!
            
            var scheduler: TestScheduler!
            var finalCacheObserver: TestableObserver<Int?>!
            
            var choosenCache: CacheSwitchResult!
            
            var key = "testKey"
            beforeEach {
                scheduler = TestScheduler(initialClock: 0)
                
                finalCacheObserver = scheduler.createObserver(Int?.self)
                
                cache1 = CacheFake<String, Int>()
                cache2 = CacheFake<String, Int>()
                
                finalCache = switchCache(cacheA: cache1, cacheB: cache2, switchClosure: { _ in choosenCache })
            }
            
            context("when calling clear") {
                beforeEach {
                    finalCache.clear()
                }
                
                it("should call clear in both caches") {
                    expect(cache1.numberOfTimesCalledClear) == 1
                    expect(cache2.numberOfTimesCalledClear) == 1
                }
            }
            
            context("when calling get") {
                beforeEach {
                    scheduler.scheduleAt(10, action: {
                        _ = finalCache.get(key).subscribe(finalCacheObserver)
                    })
                    scheduler.scheduleAt(20, action: {
                        cache1.request?.on(.next(1))
                        cache2.request?.on(.next(2))
                    })
                }
                
                context("when choosing first cache") {
                    beforeEach {
                        scheduler.scheduleAt(0, action: {
                            choosenCache = .cacheA
                        })
                        scheduler.start()
                    }
                    
                    it("should get the value from first cache") {
                        expect(finalCacheObserver.events.first?.value.element!).to(equal(1))
                    }
                }
                
                context("when choosing second cache") {
                    beforeEach {
                        scheduler.scheduleAt(0, action: {
                            choosenCache = .cacheB
                        })
                        scheduler.start()
                    }
                    
                    it("should get the value from first cache") {
                        expect(finalCacheObserver.events.first?.value.element!).to(equal(2))
                    }
                }
            }
            
            context("when calling set") {
                beforeEach {
                    scheduler.scheduleAt(10) {
                        finalCache.set(1, for: key).publish().connect()
                    }
                }
                context("when choosing first cache") {
                    beforeEach {
                        scheduler.scheduleAt(0, action: {
                            choosenCache = .cacheA
                        })
                        scheduler.start()
                    }
                    
                    it("should set the value to the first cache") {
                        expect(cache1.numberOfTimesCalledSet).to(equal(1))
                        expect(cache2.numberOfTimesCalledSet).to(equal(0))
                        expect(cache1.didCalledSetWithValue).to(equal(1))
                    }
                }
                
                context("when choosing first cache") {
                    beforeEach {
                        scheduler.scheduleAt(0, action: {
                            choosenCache = .cacheB
                        })
                        scheduler.start()
                    }
                    
                    it("should set the value to the first cache") {
                        expect(cache1.numberOfTimesCalledSet).to(equal(0))
                        expect(cache2.numberOfTimesCalledSet).to(equal(1))
                        expect(cache2.didCalledSetWithValue).to(equal(1))
                    }
                }
            }
        }
    }
}
