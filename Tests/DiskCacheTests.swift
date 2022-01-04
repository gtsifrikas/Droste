//
//  DiskCacheTests.swift
//  George TsifrikasTests
//
//  Created by George Tsifrikas on 18/10/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import Nimble
import Quick
import RxSwift
import RxTest
@testable import DrosteSwift

private func filesInDirectory(directory: String) -> [String] {
    let result = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
    
    return result
}

class DiskCacheTests: QuickSpec {
    override func spec() {
        
        describe("The Disk Cache") {
            var sut: DiskCache<String, NSData>!
            let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0].appending("/com.Droste.default").appending("/test")
            let capacity: UInt64 = 400//bytes
            var fileManager: FileManager!
            var scheduler: TestScheduler!
            var cacheObserver: TestableObserver<NSData?>!
            
            beforeEach {
                fileManager = FileManager.default
                _ = try? fileManager.removeItem(atPath: path)
                
                sut = DiskCache(path: path, capacity: capacity)
                scheduler = TestScheduler(initialClock: 0)
                cacheObserver = scheduler.createObserver(NSData?.self)
            }
            
            context("when calling get") {
                let key = "testKey"
                
                beforeEach {
                    scheduler.scheduleAt(0) {
                        _ = sut.get(key).subscribe(cacheObserver)
                    }
                    
                    scheduler.start()
                }
                
                it("should have 2 events") {
                    expect(cacheObserver.events).toEventually(haveCount(2))//next, completed
                }
                
                it("should return nil") {
                    expect(cacheObserver.events.first?.value.element ?? NSData()).toEventually(beNil())
                }
                
                context("when setting a value for that key") {
                    let value = "value to set".data(using: .utf8, allowLossyConversion: false)! as NSData
                    
                    beforeEach {
                        scheduler.scheduleAt(10) {
                            _ = sut.set(value, for: key).publish().connect()
                        }
                        scheduler.start()
                    }
                    
                    context("when getting the value for another key") {
                        let anotherKey = "test_key_2"
                        
                        beforeEach {
                            cacheObserver = scheduler.createObserver(NSData?.self)
                            scheduler.scheduleAt(20) {
                                _ = sut.get(anotherKey).subscribe(cacheObserver)
                            }
                            
                            scheduler.start()
                        }
                        
                        it("should have 2 events") {
                            expect(cacheObserver.events).toEventually(haveCount(2))//next, completed
                        }
                        
                        it("should return nil") {
                            expect((cacheObserver.events.first?.value.element ?? NSData())).toEventually(beNil())
                            expect(cacheObserver.events[1].value.isStopEvent).toEventually(beTrue())
                        }
                    }
                }
                
                context("when calling set") {
                    let key = "key"
                    let value = "value".data(using: .utf8, allowLossyConversion: false)! as NSData
                    var cacheSetObserver: TestableObserver<Void>!
                    
                    beforeEach {
                        cacheSetObserver = scheduler.createObserver(Void.self)
                        scheduler.scheduleAt(30) {
                            _ = sut.set(value, for: key).subscribe(cacheSetObserver)
                        }
                        scheduler.start()
                    }
                    
                    it("should save the key on disk") {
                        expect(fileManager.fileExists(atPath: (path as NSString).appendingPathComponent(key.MD5String()))).toEventually(beTrue())
                    }
                    
                    it("should save the data on disk") {
                        expect(NSKeyedUnarchiver.unarchiveObject(withFile: (path as NSString).appendingPathComponent(key.MD5String())) as? NSData).toEventually(equal(value as NSData))
                    }
                    
                    // TODO: How to simulate failure during writing in order to test it?
                    it("should eventually succeed") {
                        expect(cacheSetObserver.events).toEventually(haveCount(2))
                        expect(cacheSetObserver.events[1].value.isCompleted).toEventually(beTrue())
                    }
                    
                    context("when calling get") {
                        beforeEach {
                            cacheObserver = scheduler.createObserver(NSData?.self)
                            scheduler.scheduleAt(40) {
                                _ = sut.get(key).subscribe(cacheObserver)
                            }
                            scheduler.start()
                        }
                        
                        it("should succeed") {
                            expect(cacheObserver.events).toEventually(haveCount(2))
                            expect(cacheObserver.events.first?.value.element ?? NSData()).toEventually(equal(value))
                            expect(cacheObserver.events[1].value.isCompleted).toEventually(beTrue())
                        }
                    }
                    
                    context("when setting a different value for the same key") {
                        let newValue = "another value".data(using: .utf8, allowLossyConversion: false)! as NSData
                        
                        beforeEach {
                            cacheSetObserver = scheduler.createObserver(Void.self)
                            scheduler.scheduleAt(40) {
                                _ = sut.set(newValue, for: key).subscribe(cacheSetObserver)
                            }
                            scheduler.start()
                        }
                        
                        it("should keep the key on disk") {
                            expect(fileManager.fileExists(atPath: (path as NSString).appendingPathComponent(key.MD5String()))).toEventually(beTrue())
                        }
                        
                        it("should overwrite the data on disk") {
                            let newValueFromDisk: () -> NSData? = {
                                return NSKeyedUnarchiver.unarchiveObject(withFile: (path as NSString).appendingPathComponent(key.MD5String())) as? NSData
                            }
                            expect(newValueFromDisk()).toEventually(equal(newValue))
                        }
                        
                        context("when calling get") {
                            beforeEach {
                                cacheObserver = scheduler.createObserver(NSData?.self)
                                scheduler.scheduleAt(45) {
                                    _ = sut.get(key).subscribe(cacheObserver)
                                }
                                scheduler.start()
                            }
                            
                            it("should succeed") {
                                expect(cacheObserver.events).toEventually(haveCount(2))
                                expect(cacheObserver.events.first?.value.element ?? NSData()).toEventually(equal(newValue))
                                expect(cacheObserver.events[1].value.isCompleted).toEventually(beTrue())
                            }
                        }
                    }
                    
                    context("when setting more than its capacity") {
                        let otherKeys = ["key1", "key2", "key3"]
                        let otherValues = [
                            "long string value",
                            "even longer string value but should still fit the cache",
                            "longest string value that should fill the cache capacity and force it to evict some values"
                        ]
                        
                        beforeEach {
                            cacheObserver = scheduler.createObserver(NSData?.self)
                            cacheSetObserver = scheduler.createObserver(Void.self)
                            scheduler.scheduleAt(40) {
                                let setValuesObservables = zip(otherKeys, otherValues)
                                    .map({ (key, value) -> Observable<Void> in
                                        sut.set(value.data(using: .utf8, allowLossyConversion: false)! as NSData, for: key)
                                    })
                                
                                _ = Observable.merge(setValuesObservables)
                                    .subscribe(cacheSetObserver)
                            }
                            scheduler.scheduleAt(50) {
                                let getValuesObservables = otherKeys
                                    .map({ key -> Observable<NSData?> in
                                        sut.get(key)
                                    })
                                _ = Observable.merge(getValuesObservables)
                                    .subscribe(cacheObserver)
                            }
                            scheduler.start()
                        }
                        
                        it("should evict at least one value") {
                            
                            let savedValuesAllSaved: () -> Bool = { cacheObserver.events
                                .filter({ !$0.value.isCompleted })
                                .map({ (recordedEvent) -> Bool in
                                    return (recordedEvent.value.element ?? nil) != nil
                                })
                                .reduce(true, { $0 && $1 }) && cacheObserver.events.count > 0 }
                            
                            expect(savedValuesAllSaved()).toEventually(beFalse())
                        }
                    }
                    
                    
                    context("when calling clear") {
                        beforeEach {
                            sut.clear()
                        }
                        
                        it("should remove all the files on disk") {
                            expect(filesInDirectory(directory: path)).toEventually(beEmpty(), timeout: .seconds(10))
                        }
                        
                        context("when calling get") {
                            beforeEach {
                                cacheObserver = scheduler.createObserver(NSData?.self)
                                scheduler.scheduleAt(50) {
                                    _ = sut.get(key).subscribe(cacheObserver)
                                }
                                scheduler.start()
                            }
                            
                            it("should not succeed") {
                                expect(cacheObserver.events).toEventually(haveCount(2))
                                expect(cacheObserver.events.first?.value.element ?? NSData()).toEventually(beNil())
                                expect(cacheObserver.events[1].value.isCompleted).toEventually(beTrue())
                            }
                        }
                    }
                }
                
                context("Failing to save/retrieve value") {
                    var sut: DiskCache<String, BadObject>!
                    var cacheObserver: TestableObserver<BadObject?>!
                    var cacheSetObserver: TestableObserver<Void>!
                    
                    beforeEach {
                        sut = DiskCache(path: path, capacity: capacity)
                        let badObject = BadObject()
                        cacheObserver = scheduler.createObserver(BadObject?.self)
                        cacheSetObserver = scheduler.createObserver(Void.self)
                        scheduler.scheduleAt(40) {
                            _ = sut.set(badObject, for: key).subscribe(cacheSetObserver)
                        }
                        scheduler.scheduleAt(50) {
                            _ = sut.get(key).subscribe(cacheObserver)
                        }
                        scheduler.start()
                    }
                    
                    it("should not crash and return nil") {
                        expect(cacheObserver.events).toEventually(haveCount(2))
                        expect(cacheObserver.events.first?.value.element ?? BadObject()).toEventually(beNil())
                        expect(cacheObserver.events[1].value.isCompleted).toEventually(beTrue())
                    }
                    
                    it("should delete the potentially corrupted file") {
                        expect(fileManager.fileExists(atPath: (path as NSString).appendingPathComponent(key.MD5String()))).toEventually(beFalse())
                    }
                }
            }
        }
    }
}

class BadObject: NSObject, NSCoding {
    override init() {}
    required init?(coder aDecoder: NSCoder) {
        NSException(name: NSExceptionName(rawValue: "Cannot Encode"), reason: "I don't like the folder name", userInfo: nil).raise()
    }
    func encode(with aCoder: NSCoder) {}
}
