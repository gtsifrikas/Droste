//
//  ExpirableCache.swift
//  Droste
//
//  Created by George Tsifrikas on 04/12/2017.
//

import Foundation
import RxSwift

public enum Expiry {
    case seconds(TimeInterval)
    case date(Foundation.Date)
}

public protocol ExpirableCache: Cache {
    func getData<GenericValueType>(_ key: Self.Key) -> Observable<GenericValueType?>
    func setData<GenericValueType>(_ value: GenericValueType, for key: Self.Key) -> Observable<Void>
}

public extension ExpirableCache {
    public func get(_ key: Key) -> Observable<Value?> {
        return getData(key)
    }

    public func set(_ value: Value, for key: Key) -> Observable<Void> {
        return setData(value, for: key)
    }
}

public extension ExpirableCache {
    
    public func expires(at expiry: Expiry) -> CompositeCache<Key, Value> {
        return
            CompositeCache(
                get: {(key: Key) -> Observable<Value?> in
                    return self.getData(key)
                        .map({ (cacheDTO: CacheExpirableDTO?) -> Value? in
                            guard let cacheDTO = cacheDTO else { return nil }
                            guard !cacheDTO.isExpired() else { return nil }
                            return cacheDTO.value as? Value
                        })
                }
                , set: {(value: Value, key: Key) in
                    let cacheDTO = CacheExpirableDTO(value: value as AnyObject, expiryDate: self.date(for: expiry))
                    return self.setData(cacheDTO, for: key)
                },
                  clear: clear)
    }
    
    private func date(for expiry: Expiry) -> Date {
        switch expiry {
        case .seconds(let seconds):
            return Date().addingTimeInterval(seconds)
        case .date(let date):
            return date
        }
    }
}

public class CacheExpirableDTO: NSObject, NSCoding {
    let value: AnyObject
    let expiryDate: Date

    init(value: AnyObject, expiryDate: Date) {
        self.value = value
        self.expiryDate = expiryDate
    }
    
    func isExpired() -> Bool {
        return expiryDate.isInThePast
    }
    
    required public init?(coder aDecoder: NSCoder) {
        guard let val = aDecoder.decodeObject(forKey: "value"),
            let expiry = aDecoder.decodeObject(forKey: "expiryDate") as? Date else {
                return nil
        }
        
        self.value = val as AnyObject
        self.expiryDate = expiry
        super.init()
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
        aCoder.encode(expiryDate, forKey: "expiryDate")
    }
}

fileprivate extension Date {
    var isInThePast: Bool {
        return self.timeIntervalSinceNow < 0
    }
}
