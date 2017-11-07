//
//  Caches.swift
//  RxCache
//
//  Created by George Tsifrikas on 01/11/2017.
//

import Foundation

//some caches to use for common cases/examples
public struct Caches {
    
    public static var sharedDataCache = dataCache()
    public static var sharedJSONCache = jsonCache()
    public static var sharedImageCache = imageCache()
    
    public static func dataCache() -> CompositeCache<URL, NSData> {
        let networkFetcher = NetworkFetcher()
            .mapKeys { (url: URL) -> URLRequest in//map url to urlrequest
                return URLRequest(url: url)
        }
        let diskCache = DiskCache<URL, NSData>()
        let ramCache = RamCache<URL, NSData>()
        return ramCache + (diskCache + networkFetcher).reuseInFlight()
    }
    
    public static func jsonCache() -> CompositeCache<URL, AnyObject> {
        return dataCache()
            .mapValues(f: { (data) -> AnyObject in
                //convert NSData to json object
                return try JSONSerialization.jsonObject(with: data as Data, options: [.allowFragments]) as AnyObject
            }, fInv: { (object) -> NSData in
                //convert json object to NSData
                return try JSONSerialization.data(withJSONObject: object, options: []) as NSData
            })
    }
    
    public static func imageCache() -> CompositeCache<URL, UIImage> {
        return dataCache()
            .mapValues(
                f: { (data) -> UIImage in
                    return UIImage(data: data as Data)!
            }) { (image) -> NSData in
                return UIImagePNGRepresentation(image) as! NSData
            }
    }
}
