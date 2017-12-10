//
//  ExpireTests.swift
//  Droste
//
//  Created by George Tsifrikas on 09/12/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class ExpireTests: QuickSpec {
    override func spec() {
        describe("The expires operator") {
            var cache: CacheFake<Int, String>!
            var scheduler: TestScheduler!
            var cacheObserver: TestableObserver<String>!
            var sut: CompositeCache<Int, String>!
            
            beforeEach {
                scheduler = TestScheduler(initialClock: 0)
                cacheObserver = scheduler.createObserver(String.self)
            }
            
            context("when does not expires", {
                beforeEach {
                    cache = CacheFake()
                    sut = cache.expires(at: .never)
                }
                
                context("when calling set", {
                    beforeEach {
                        _ = sut.set("Hello World", for: 1).subscribe()
                    }
                    
                    it("should create the correct CacheExpirableDTO", closure: {
                        let createdDTO = cache.didCalledGenericDataSetWithValue as? CacheExpirableDTO
                        expect(createdDTO?.value as? String).to(equal("Hello World"))
                        expect(createdDTO?.expiryDate).to(equal(Date.distantFuture))
                    })
                })
                
                context("when calling get", {
                    context("when value is malformed") {
                        beforeEach {
                            scheduler.scheduleAt(0) {
                                _ = sut.get(1).subscribe(cacheObserver)
                            }
                            
                            scheduler.scheduleAt(1) {
                                let cacheExpirableDTO = CacheExpirableDTO(value: 12345 as AnyObject, expiryDate: Date.distantFuture)
                                cache.genericDataRequest.on(.next(cacheExpirableDTO))
                            }
                            scheduler.start()
                        }
                        
                        it("should invoke getData of cache", closure: {
                            expect(cache.numberOfTimesCalledGenericDataGet).to(equal(1))
                        })
                        
                        it("should return nil", closure: {
                            expect(cacheObserver.events.first?.value.element).to(beNil())
                        })
                    }
                    context("when value exists", {
                        beforeEach {
                            scheduler.scheduleAt(0) {
                                _ = sut.get(1).subscribe(cacheObserver)
                            }
                            
                            scheduler.scheduleAt(1) {
                                let cacheExpirableDTO = CacheExpirableDTO(value: "Hello World" as AnyObject, expiryDate: Date.distantFuture)
                                cache.genericDataRequest.on(.next(cacheExpirableDTO))
                            }
                            scheduler.start()
                        }
                        
                        it("should invoke getData of cache", closure: {
                            expect(cache.numberOfTimesCalledGenericDataGet).to(equal(1))
                        })
                        
                        it("should return the correct value from the DTO", closure: {
                            expect(cacheObserver.events.first?.value.element).to(equal("Hello World"))
                        })
                    })
                    
                    context("when value does not exists", {
                        beforeEach {
                            scheduler.scheduleAt(0) {
                                _ = sut.get(1).subscribe(cacheObserver)
                            }
                            
                            scheduler.scheduleAt(1) {
                                cache.genericDataRequest.on(.next(nil))
                            }
                            scheduler.start()
                        }
                        
                        it("should invoke getData of cache", closure: {
                            expect(cache.numberOfTimesCalledGenericDataGet).to(equal(1))
                        })
                        
                        it("should return the correct value from the DTO", closure: {
                            expect(cacheObserver.events.first?.value.element).to(beNil())
                        })
                    })
                })
            })
            
            context("when does expires", {
                beforeEach {
                    cache = CacheFake()
                    sut = cache.expires(at: .seconds(10))
                }
                
                context("when calling set", {
                    beforeEach {
                        _ = sut.set("Hello World", for: 1).subscribe()
                    }
                    
                    it("should create the correct CacheExpirableDTO", closure: {
                        let createdDTO = cache.didCalledGenericDataSetWithValue as? CacheExpirableDTO
                        expect(createdDTO?.value as? String).to(equal("Hello World"))
                        expect(Int(createdDTO!.expiryDate.timeIntervalSinceNow))
                            .to(equal(Int(Date(timeIntervalSinceNow: 10).timeIntervalSinceNow)))
                    })
                })
                
                context("when calling get before expiry", {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = sut.get(1).subscribe(cacheObserver)
                        }
                        
                        scheduler.scheduleAt(1) {
                            let cacheExpirableDTO = CacheExpirableDTO(value: "Hello World" as AnyObject, expiryDate: Date(timeIntervalSinceNow: 1))
                            cache.genericDataRequest.on(.next(cacheExpirableDTO))
                        }
                        scheduler.start()
                    }
                    
                    it("should invoke getData of cache", closure: {
                        expect(cache.numberOfTimesCalledGenericDataGet).to(equal(1))
                    })
                    
                    it("should return the correct value from the DTO", closure: {
                        expect(cacheObserver.events.first?.value.element).to(equal("Hello World"))
                    })
                })
                
                context("when calling get after expiry", {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = sut.get(1).subscribe(cacheObserver)
                        }
                        
                        scheduler.scheduleAt(1) {
                            let cacheExpirableDTO = CacheExpirableDTO(value: "Hello World" as AnyObject, expiryDate: Date(timeIntervalSinceNow: -1))
                            cache.genericDataRequest.on(.next(cacheExpirableDTO))
                        }
                        scheduler.start()
                    }
                    
                    it("should invoke getData of cache", closure: {
                        expect(cache.numberOfTimesCalledGenericDataGet).to(equal(1))
                    })
                    
                    it("should return the correct value from the DTO", closure: {
                        expect(cacheObserver.events.first?.value.element).to(beNil())
                    })
                })
            })
        }
    }
}
