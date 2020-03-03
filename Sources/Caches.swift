//
//  Caches.swift
//  Droste
//
//  Created by George Tsifrikas on 01/11/2017.
//

import Foundation

//some caches to use for common cases/examples
public struct DrosteCaches {
    
    public static var sharedDataCache = dataCache()
    public static var sharedJSONCache = jsonCache()
    public static var sharedImageCache = imageCache()
    
    public static func dataCache(expires: Expiry? = nil) -> CompositeCache<URL, NSData> {
        let networkFetcher = NetworkFetcher()
            .mapKeys { (url: URL) -> URLRequest in//map url to urlrequest
                return URLRequest(url: url)
        }
        let diskCache: CompositeCache<URL, NSData>
        let ramCache: CompositeCache<URL, NSData>
        
        if let expires = expires {
            diskCache = DiskCache().expires(at: expires)
            ramCache = RamCache().expires(at: expires)
        } else {
            diskCache = DiskCache().normalize()
            ramCache = RamCache().normalize()
        }
        
        return ramCache + (diskCache + networkFetcher).reuseInFlight()
    }
    
    public static func jsonCache(expires: Expiry? = nil) -> CompositeCache<URL, AnyObject> {
        return dataCache(expires: expires)
            .mapValues(f: { (data) -> AnyObject in
                //convert NSData to json object
                return try JSONSerialization.jsonObject(with: data as Data, options: [.allowFragments]) as AnyObject
            }, fInv: { (object) -> NSData in
                //convert json object to NSData
                return try JSONSerialization.data(withJSONObject: object, options: []) as NSData
            })
    }
    
    public static func imageCache(expires: Expiry? = nil) -> CompositeCache<URL, UIImage> {
        return dataCache(expires: expires)
            .mapValues(
                f: { (data) -> UIImage in
                    return UIImage(data: data as Data)!
            }) { (image) -> NSData in
                return image.pngData() as! NSData
            }
    }
}
