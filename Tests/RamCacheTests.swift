//
//  RamCacheTests.swift
//  Droste
//
//  Created by George Tsifrikas on 01/11/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class RamCacheTests: QuickSpec {
    override func spec() {
        describe("The Ram Cache") {
            var sut: RamCache<String, Int>!
            var cacheObserver: TestableObserver<Int?>!
            var scheduler = TestScheduler(initialClock: 0)
            
            beforeEach {
                cacheObserver  = scheduler.createObserver(Int?.self)
                sut = RamCache()
            }
            
            let key = "testKey"
            
            context("when calling get") {
                beforeEach {
                    scheduler.scheduleAt(10) {
                        _ = sut.get(key).subscribe(cacheObserver)
                    }
                }
                
                context("when cache does not have a value") {
                    beforeEach {
                        scheduler.start()
                    }
                    
                    it("should return nil") {
                        expect(cacheObserver.events.first?.value.element!).to(beNil())
                    }
                }
                
                context("when cache does have a value") {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = sut.set(1, for: key).publish().connect()
                        }
                        scheduler.start()
                    }
                    
                    it("should return the value") {
                        expect(cacheObserver.events.first?.value.element).to(equal(1))
                    }
                }
                
                context("when cache does have a value but we query with different key than the saved one") {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = sut.set(1, for: "random").publish().connect()
                        }
                        scheduler.start()
                    }
                    
                    it("should NOT return a value") {
                        expect(cacheObserver.events.first?.value.element!).to(beNil())
                    }
                }
                
                context("when calling clear") {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = sut.set(1, for: key).publish().connect()
                        }
                        scheduler.scheduleAt(5) {
                            sut.clear()
                        }
                        scheduler.start()
                    }
                    
                    it("should return nil") {
                        expect(cacheObserver.events.first?.value.element!).to(beNil())
                    }
                }
            }
        }
    }
}
