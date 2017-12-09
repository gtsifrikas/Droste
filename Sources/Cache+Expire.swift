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

public protocol ExpirableCache: Cache {
    func _getExpirableDTO(_ key: Self.Key) -> Observable<CacheExpirableDTO?>
    func _setExpirableDTO(_ value: CacheExpirableDTO, for key: Self.Key) -> Observable<Void>
}

public extension Cache where Value: NSCoding, Self: ExpirableCache {
    
    public func expires(at expiry: Expiry) -> CompositeCache<Key, Value> {
        return
            CompositeCache(
                get: {(key: Key) -> Observable<Value?> in
                    return self._getExpirableDTO(key)
                        .map({ (cacheDTO: CacheExpirableDTO?) -> Value? in
                            //TODO: check the expiry
                            guard let cacheDTO = cacheDTO else { return nil }
                            guard !cacheDTO.isExpired() else { return nil }
                            return cacheDTO.value as? Value
                        })
                }
                , set: {(value: Value, key: Key) in
                    let cacheDTO = CacheExpirableDTO(value: value, expiryDate: self.date(for: expiry))
                    return self._setExpirableDTO(cacheDTO, for: key)
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
