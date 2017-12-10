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
    
    public static func dataCache(expires: Expiry = .never) -> CompositeCache<URL, NSData> {
        let networkFetcher = NetworkFetcher()
            .mapKeys { (url: URL) -> URLRequest in//map url to urlrequest
                return URLRequest(url: url)
        }
        let diskCache = DiskCache<URL, NSData>().expires(at: expires)
        let ramCache = RamCache<URL, NSData>().expires(at: expires)
        return ramCache + (diskCache + networkFetcher).reuseInFlight()
    }
    
    public static func jsonCache(expires: Expiry = .never) -> CompositeCache<URL, AnyObject> {
        return dataCache(expires: expires)
            .mapValues(f: { (data) -> AnyObject in
                //convert NSData to json object
                return try JSONSerialization.jsonObject(with: data as Data, options: [.allowFragments]) as AnyObject
            }, fInv: { (object) -> NSData in
                //convert json object to NSData
                return try JSONSerialization.data(withJSONObject: object, options: []) as NSData
            })
    }
    
    public static func imageCache(expires: Expiry = .never) -> CompositeCache<URL, UIImage> {
        return dataCache(expires: expires)
            .mapValues(
                f: { (data) -> UIImage in
                    return UIImage(data: data as Data)!
            }) { (image) -> NSData in
                return UIImagePNGRepresentation(image) as! NSData
            }
    }
}
