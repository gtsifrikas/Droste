//
//  MapTests.swift
//  Droste
//
//  Created by George Tsifrikas on 29/10/2017.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import Droste

class MapTests: QuickSpec {
    override func spec() {
        struct CouldNotConvertStringToNumber: Error {}
        struct RandomError: Error {}
        
        describe("The map key operator") {
            var cache: CacheFake<Int, Int>!
            var mappedCache: CompositeCache<String, Int>!
            
            let inverseKeyMapper: (String) throws -> Int = { aStringifiedNumber in
                if let aNumber = Int(aStringifiedNumber) {
                    return aNumber
                } else {
                    throw CouldNotConvertStringToNumber()
                }
            }
            
            var scheduler: TestScheduler!
            var mappedCacheObserver: TestableObserver<Int?>!
            
            beforeEach {
                scheduler = TestScheduler(initialClock: 0)
                cache = CacheFake()
                mappedCache = cache
                    .mapKeys(fInv: inverseKeyMapper)
                mappedCacheObserver = scheduler.createObserver(Int?.self)
            }
            
            context("when calling get") {
                beforeEach {
                    _ = mappedCache.get("1").publish().connect()
                }
                
                it("should correct map the key") {
                    expect(cache.didCallGetWithKey).to(equal(1))
                }
                
                context("when key mapping fails") {
                    beforeEach {
                        scheduler.scheduleAt(0) {
                            _ = mappedCache.get("Hello world!").subscribe(mappedCacheObserver)
                        }
                        scheduler.start()
                    }
                    
                    it("should bubble up the error") {
                        expect(mappedCacheObserver.events.first?.value.error).to(matchError(CouldNotConvertStringToNumber()))
                    }
                }
            }
            
            context("when calling set") {
                beforeEach {
                    _ = mappedCache.set(1, for: "1").publish().connect()
                }
                
                it("should correct map the key") {
                    expect(cache.didCalledSetWithKey).to(equal(1))
                }
                
                context("when key mapping fails") {
                    
                    var setObserver: TestableObserver<Void>!
                        
                    beforeEach {
                        setObserver = scheduler.createObserver(Void.self)
                        scheduler.scheduleAt(0) {
                            _ = mappedCache.set(1, for: "Hello world!").subscribe(setObserver)
                        }
                        scheduler.start()
                    }
                    
                    it("should bubble up the error") {
                        expect(setObserver.events.first?.value.error).to(matchError(CouldNotConvertStringToNumber()))
                    }
                }
            }
        }
        
        describe("The map value operator") {
            var cache: CacheFake<String, Int>!
            var mappedCache: CompositeCache<String, String>!
            
            let valueMapper: (Int) throws -> String = { aNumber in
                return "\(aNumber)"
            }
            
            let faultyValueMapper: (Int) throws -> String = { aNumber in
                throw RandomError()
            }
            
            let inverseValueMapper: (String) throws -> Int = { aStringifiedNumber in
                if let aNumber = Int(aStringifiedNumber) {
                    return aNumber
                } else {
                    throw CouldNotConvertStringToNumber()
                }
            }
            
            var scheduler: TestScheduler!
            var mappedCacheObserver: TestableObserver<String?>!
            
            let key = "testKey"
            let setKey = "setTestKey"
            
            beforeEach {
                scheduler = TestScheduler(initialClock: 0)
                cache = CacheFake()
                mappedCache = cache
                    .mapValues(f: valueMapper, fInv: inverseValueMapper)
                mappedCacheObserver = scheduler.createObserver(String?.self)
                
                scheduler.scheduleAt(0) {
                    _ = mappedCache.get(key).subscribe(mappedCacheObserver)
                    _ = mappedCache.set("1", for: setKey).publish().connect()
                }
            }
            
            context("when calling get") {
                beforeEach {
                    scheduler.start()
                }
                
                it("should call get on the underlying cache") {
                    expect(cache.numberOfTimesCalledGet).to(equal(1))
                }
                
                it("should use the right key") {
                    expect(cache.didCallGetWithKey).to(equal(key))
                }
                
                context("when the value doesn't exist") {
                    beforeEach {
                        scheduler.scheduleAt(10) {
                            cache.request.on(.next(nil))
                        }
                        scheduler.start()
                    }
                    
                    it("should return the correct transformed value") {
                        expect(mappedCacheObserver.events.first?.value.element!).to(beNil())
                    }
                }
                
                context("when the request succeeds") {
                    let actualCacheResponse = 1
                    let mappedCacheResponse = try! valueMapper(actualCacheResponse)
                    
                    beforeEach {
                        scheduler.scheduleAt(10) {
                            cache.request.on(.next(actualCacheResponse))
                        }
                        scheduler.start()
                    }
                    
                    it("should return the correct transformed value") {
                        expect(mappedCacheObserver.events.first?.value.element!).to(equal(mappedCacheResponse))
                    }
                }
                
                context("when the request fails in mapping") {
                    let actualCacheResponse = 1
                    
                    beforeEach {
                        mappedCache = cache
                            .mapValues(f: faultyValueMapper, fInv: inverseValueMapper)
                        mappedCacheObserver = scheduler.createObserver(String?.self)
                        
                        scheduler.scheduleAt(10) {
                            _ = mappedCache.get(key).subscribe(mappedCacheObserver)
                        }
                        
                        scheduler.scheduleAt(20) {
                            cache.request.on(.next(actualCacheResponse))
                        }
                        
                        scheduler.start()
                    }
                    
                    it("should bubble the error to the mapped cache") {
                        expect(mappedCacheObserver.events.first?.value.error).to(matchError(RandomError()))
                    }
                }
                
                context("when the underlying cache fails") {
                    
                    beforeEach {
                        mappedCache = cache
                            .mapValues(f: valueMapper, fInv: inverseValueMapper)
                        mappedCacheObserver = scheduler.createObserver(String?.self)
                        
                        scheduler.scheduleAt(10) {
                            _ = mappedCache.get(key).subscribe(mappedCacheObserver)
                        }
                        
                        scheduler.scheduleAt(20) {
                            cache.request.on(.error(RandomError()))
                        }
                        
                        scheduler.start()
                    }
                    
                    it("should bubble the error to the mapped cache") {
                        expect(mappedCacheObserver.events.first?.value.error).to(matchError(RandomError()))
                    }
                }
            }
            
            context("when calling set") {
                beforeEach {
                    scheduler.start()
                }
                
                it("should call set on the underlying cache") {
                    expect(cache.numberOfTimesCalledSet).to(equal(1))
                }
                
                it("should use the right key") {
                    expect(cache.didCalledSetWithKey).to(equal(setKey))
                }
                
                context("when the set succeeds") {
                    let actualSetRequest = "1"
                    let mappedCacheRequest = try! inverseValueMapper(actualSetRequest)
                    
                    beforeEach {
                        scheduler.scheduleAt(10) {
                            _ = mappedCache.set(actualSetRequest, for: setKey)
                        }
                        scheduler.start()
                    }
                    
                    it("should set the correct transformed value") {
                        expect(cache.didCalledSetWithValue).to(equal(mappedCacheRequest))
                    }
                }
                
                context("when the set fails in mapping") {
                    let actualCacheSetRequest = "hello world!"//should fail converting this to Int
                    var setObserver: TestableObserver<Void>!
                    
                    beforeEach {
                        setObserver = scheduler.createObserver(Void.self)
                        mappedCache = cache
                            .mapValues(f: faultyValueMapper, fInv: inverseValueMapper)
                        mappedCacheObserver = scheduler.createObserver(String?.self)
                        
                        scheduler.scheduleAt(10) {
                            _ = mappedCache.set(actualCacheSetRequest, for: setKey).subscribe(setObserver)
                        }
                        
                        scheduler.start()
                    }
                    
                    it("should bubble up the error to the mapped cache") {
                        expect(setObserver.events.first?.value.error).to(matchError(CouldNotConvertStringToNumber()))
                    }
                }
                
                context("when the underlying cache fails") {
                    
                    beforeEach {
                        mappedCache = cache
                            .mapValues(f: valueMapper, fInv: inverseValueMapper)
                        mappedCacheObserver = scheduler.createObserver(String?.self)
                        
                        scheduler.scheduleAt(10) {
                            _ = mappedCache.get(key).subscribe(mappedCacheObserver)
                        }
                        
                        scheduler.scheduleAt(20) {
                            cache.request.on(.error(RandomError()))
                        }
                        
                        scheduler.start()
                    }
                    
                    it("should bubble the error to the mapped cache") {
                        expect(mappedCacheObserver.events.first?.value.error).to(matchError(RandomError()))
                    }
                }
            }
            
            context("when calling clear") {
                beforeEach {
                    mappedCache.clear()
                }
                
                it("should call clear on the underlying cache") {
                    expect(cache.numberOfTimesCalledClear) == 1
                }
            }
        }
    }
}
