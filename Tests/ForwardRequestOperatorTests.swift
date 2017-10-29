//
//  ForwardRequestOperatorTests.swift
//  RxCache
//
//  Created by George Tsifrikas on 29/10/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import RxCache

class ForwardRequestOperatorTests: QuickSpec {
    override func spec() {
        describe("The forward request operator") {
            var cache1: CacheFake<String, Int>!
            var cache2: CacheFake<String, Int>!
            var composedCache: CompositeCache<String, Int>!
            
            var scheduler: TestScheduler!
            var composedCacheObserver: TestableObserver<Int?>!
            
            let key = "testKey"
            
            beforeEach {
                cache1 = CacheFake<String, Int>()
                cache2 = CacheFake<String, Int>()
                composedCache = cache1.forwardRequest() + cache2
                
                scheduler = TestScheduler(initialClock: 0)
                composedCacheObserver = scheduler.createObserver(Int?.self)
            }
            
            context("when first cache has a value") {
                let cache1ResponseValue = 1
                let cache2ResponseValue = 2
                
                beforeEach {
                    scheduler.scheduleAt(0) {
                        _ = composedCache.get(key).subscribe(composedCacheObserver)
                    }
                    
                    scheduler.scheduleAt(10) {
                        cache1.request.on(.next(cache1ResponseValue))
                    }
                    
                    scheduler.start()
                }
                
                it("should return that value") {
                    expect(composedCacheObserver.events.first?.value.element!).to(equal(1))
                }
                
                it("should propage the request to the second cache once") {
                    expect(cache2.numberOfTimesCalledGet).to(equal(cache1ResponseValue))
                }
                
                context("when the second cache has a value") {
                    beforeEach {
                        scheduler.scheduleAt(20) {
                            cache2.request.on(.next(cache2ResponseValue))
                        }
                        
                        scheduler.start()
                    }
                    
                    it("should get asked once") {
                        expect(cache2.numberOfTimesCalledGet).to(equal(1))
                    }
                    
                    it("shoud return the second value") {
                        expect(composedCacheObserver.events[1].value.element!).to(equal(cache2ResponseValue))
                    }
                }
            }
            
            context("when first cache has not a value") {
                let cache1ResponseValue: Int? = nil
                let cache2ResponseValue = 2
                
                beforeEach {
                    scheduler.scheduleAt(0) {
                        _ = composedCache.get(key).subscribe(composedCacheObserver)
                    }
                    
                    scheduler.scheduleAt(10) {
                        cache1.request.on(.next(cache1ResponseValue))
                    }
                    
                    scheduler.start()
                }
                
                it("should not return nil") {
                    expect(composedCacheObserver.events).to(haveCount(0))
                }
                
                it("should propage the request to the second cache once") {
                    expect(cache2.numberOfTimesCalledGet).to(equal(1))
                }
                
                context("when the second cache has a value") {
                    beforeEach {
                        scheduler.scheduleAt(20) {
                            cache2.request.on(.next(cache2ResponseValue))
                        }
                        
                        scheduler.start()
                    }
                    
                    it("should get asked once") {
                        expect(cache2.numberOfTimesCalledGet).to(equal(1))
                    }
                    
                    it("shoud return the second value") {
                        expect(composedCacheObserver.events.first?.value.element!).to(equal(cache2ResponseValue))
                    }
                }
            }
        }
    }
}
