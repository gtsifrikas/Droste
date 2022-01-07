//
//  SkipWhileTests.swift
//  Droste
//
//  Created by George Tsifrikas on 27/10/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class SkipWhileTests: QuickSpec {
    override func spec() {
        describe("The skipWhile operator") {
            var scheduler: TestScheduler!
            var cacheObserver: TestableObserver<Int?>!
            var cache: CacheFake<String, Int>!
            var cacheUnderTest: CompositeCache<String, Int>!
            let key = "testKey"
            
            var aCondition: Bool = false
            
            beforeEach {
                cache = CacheFake<String, Int>()
                scheduler = TestScheduler(initialClock: 0)
                cacheObserver = scheduler.createObserver(Int?.self)
                
                cacheUnderTest = cache.skipWhile({ (key) -> Observable<Bool> in
                    return Observable.just(aCondition)
                })
            }
            
            context("When condition is false") {
                beforeEach {
                    aCondition = false
                    
                    scheduler.scheduleAt(0) {
                        _ = cacheUnderTest.get(key).subscribe(cacheObserver)
                    }
                    
                    scheduler.scheduleAt(10) {
                        cache.request.on(.next(1))
                    }
                    
                    scheduler.start()
                }
                
                it("should not skip cache") {
                    expect(cacheObserver.events).toEventually(haveCount(1))
                    expect(cache.numberOfTimesCalledGet).toEventually(equal(1))
                }
            }
            
            context("When condition is true") {
                beforeEach {
                    aCondition = true
                    
                    scheduler.scheduleAt(0) {
                        _ = cacheUnderTest.get(key).subscribe(cacheObserver)
                    }
                    
                    scheduler.start()
                }
                
                it("should skip asking cache for the value") {
                    expect(cache.numberOfTimesCalledGet).toEventually(equal(0))
                }
            }
        }
    }
}
