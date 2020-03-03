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
            let scheduler = TestScheduler(initialClock: 0)
            
            beforeEach {
                cacheObserver  = scheduler.createObserver(Int?.self)
                sut = RamCache()
            }
            
            let key = "testKey"
            
            
            describe("on different threads", {
                let queueScheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "test_async_queue")
                context("when getting a value from different queue", {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = sut.set(1, for: key).publish().connect()
                            _ = sut.get(key).subscribeOn(queueScheduler).subscribe(cacheObserver)
                        }
                        scheduler.start()
                    }
                    
                    it("should return the value") {
                        expect(cacheObserver.events.first?.value.element).toEventually(equal(1))
                        expect(cacheObserver.events).toEventually(haveCount(2))
                    }
                })
            })
            
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
                        expect(cacheObserver.events.first?.value.element).toEventually(equal(1))
                        expect(cacheObserver.events).toEventually(haveCount(2))
                    }
                    
                    context("when using a different key", {
                        beforeEach {
                            scheduler.scheduleAt(15) {
                                _ = sut.get("a random key").subscribe(cacheObserver)
                            }
                            scheduler.start()
                        }
                        
                        it("should return nil") {
                            expect(cacheObserver.events).toEventually(haveCount(4))
                            expect(cacheObserver.events[2].value.element!).toEventually(beNil())
                        }
                    })
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
