//
//  SalientTests.swift
//  Droste
//
//  Created by George Tsifrikas on 29/10/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import DrosteSwift

class SalientTests: QuickSpec {
    override func spec() {
        describe("The salient get func") {
            var scheduler: TestScheduler!
            var cacheObserver: TestableObserver<Int>!
            var cache: CacheFake<String, Int>!
            let key = "testKey"
            
            beforeEach {
                cache = CacheFake<String, Int>()
                scheduler = TestScheduler(initialClock: 0)
                cacheObserver = scheduler.createObserver(Int.self)
            }
            
            context("When cache has a value") {
                beforeEach {
                    scheduler.scheduleAt(0) {
                        _ = cache.get(key).subscribe(cacheObserver)
                    }
                    
                    scheduler.scheduleAt(10) {
                        cache.request.on(.next(1))
                    }
                    
                    scheduler.start()
                }
                
                it("should return that value") {
                    expect(cacheObserver.events.first?.value.element).toEventually(equal(1))
                }
            }
            
            context("When cache has not a value") {
                beforeEach {
                    scheduler.scheduleAt(0) {
                        _ = cache.get(key).subscribe(cacheObserver)
                    }
                    
                    scheduler.scheduleAt(10) {
                        cache.request.on(.next(nil))
                    }
                    
                    scheduler.start()
                }
                
                it("should return valueNotFoundError") {
                     expect(cacheObserver.events.first?.value.error).toEventually(matchError(CacheFetchError.valueNotFound))
                }
            }
        }
    }
}
