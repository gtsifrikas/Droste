//
//  ExpirableCache.swift
//  Droste
//
//  Created by George Tsifrikas on 04/12/2017.
//

import Foundation
import RxSwift

public enum Expiry {
    case never
    case seconds(TimeInterval)
    case date(Foundation.Date)
}

public protocol ExpirableCache {}

public extension Cache where Value: NSCoding, Self: ExpirableCache {
    
    public func expires(at expiry: Expiry) -> CompositeCache<Key, Value> {
//        return
//            CompositeCache(
//                get: {(key: Key) -> Observable<Value?> in
//                    return internalCache.get(key).map({ (dto) -> Value? in
//                        return dto?.value as? Value ?? nil
//                    })
//                }
//                , set: {value, key in
//                    let dto = CacheExpirableDTO(value: value, expiryDate: self.date(for: expiry))
//                    return internalCache.set(dto, for: key)
//                },
//          clear: clear)
        return
            CompositeCache(
                get: {(key: Key) -> Observable<Value?> in
                    return self.get(key)
                        .map({ (possibleDTO: NSCoding?) -> Value? in
                            //TODO: check the expiry
                            return possibleDTO as? Value
                        })
                }
                , set: {(value: Value, key: Key) in
                    return Observable.just(value)
                        .map({ (value: Value) -> CacheExpirableDTO in
                            return CacheExpirableDTO(value: value, expiryDate: self.date(for: expiry))
                        })
                        .flatMap({ (newDTO: CacheExpirableDTO) -> Observable<Void> in
                            return Observable.just(newDTO).flatMap({ (newDTO) -> Observable<Void> in
                                let internaCache = self.mapValues(f: { (value: Value) -> CacheExpirableDTO in
                                    //ignore
                                    fatalError("Should not reach this point.")
                                }, fInv: { (dto: CacheExpirableDTO) -> Value in
                                    return dto.value as! Self.Value
                                })
                                return internaCache.set(newDTO, for: key)
                            })
                        })
                },
                  clear: clear)
    }
    
    private func date(for expiry: Expiry) -> Date {
        switch expiry {
        case .never:
            return Date.distantFuture
        case .seconds(let seconds):
            return Date().addingTimeInterval(seconds)
        case .date(let date):
            return date
        }
    }
}


@objc(_TtC6DrosteP33_82153F3EB6261FB7BD1F3A359158A49D17CacheExpirableDTO)
fileprivate class CacheExpirableDTO: NSObject, NSCoding {
    let value: AnyObject
    let expiryDate: Date

    init(value: AnyObject, expiryDate: Date) {
        self.value = value
        self.expiryDate = expiryDate
    }
    
    func isExpired() -> Bool {
        return expiryDate.isInThePast
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let val = aDecoder.decodeObject(forKey: "value"),
            let expiry = aDecoder.decodeObject(forKey: "expiryDate") as? Date else {
                return nil
        }
        
        self.value = val as AnyObject
        self.expiryDate = expiry
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
        aCoder.encode(expiryDate, forKey: "expiryDate")
    }
}

fileprivate extension Date {
    var isInThePast: Bool {
        return self.timeIntervalSinceNow < 0
    }
}
