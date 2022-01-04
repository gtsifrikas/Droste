//
//  DiskCache.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 16/07/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import RxSwift
import DrosteObjc

public struct CacheDefaults {
    public static let defaultDiskCacheLocation = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0].appending("/com.Droste.default")
}

public enum DrosteDiskError: Error {
    case diskSaveFailed
}

final public class DiskCache<K, V>: ExpirableCache where K: StringConvertible, V: NSCoding {
    
    public typealias Key = K
    public typealias Value = V
    
    private let path: String
    private var size: UInt64 = 0
    private let fileManager: FileManager
    
    private let cacheQueue: DispatchQueue
    private let cacheScheduler: SerialDispatchQueueScheduler
    
    /// The capacity of the cache
    public var capacity: UInt64 = 0 {
        didSet {
            self.cacheQueue.async {
                self.controlCapacity()
            }
        }
    }
    
    public init(path: String = CacheDefaults.defaultDiskCacheLocation,
                capacity: UInt64 = 100 * 1024 * 1024,
                fileManager: FileManager = FileManager.default) {
        self.path = path
        self.fileManager = fileManager
        self.capacity = capacity
        
        var generatedQueue: DispatchQueue?
        cacheScheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "com.droste.disk", serialQueueConfiguration: { (queue) in
            generatedQueue = queue// we are using the configuration block of SerialDispatchQueueScheduler to get the internal queue ref, doing so it ensures the timing of the disk operations are executed as intended
        })
        
        if let generatedQueue = generatedQueue {
            cacheQueue = generatedQueue
        } else {
            //fallback if for some reason we don't have a reference on the internal queue
            cacheQueue = DispatchQueue(label: "com.droste.disk", qos: .userInitiated)
        }
        
        _ = try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [:])
        
        cacheQueue.async {[weak self] in
            self?.calculateSize()
            self?.controlCapacity()
        }
    }
    
    public func _getData<GenericValueType>(_ key: K) -> Observable<GenericValueType?> {
        return Observable.create({ (observer) -> Disposable in
            let path = self.pathForKey(key)
            if let obj = NSKeyedUnarchiver.unarchive(with: path) as? GenericValueType {
                observer.onNext(obj)
                observer.onCompleted()
                _ = self.updateDiskAccessDateAtPath(path)
            } else {
                observer.onNext(nil)
                observer.onCompleted()
                _ = try? self.fileManager.removeItem(atPath: path)
            }
            return Disposables.create()
        })
        .subscribeOn(cacheScheduler)
    }

    public func _setData<GenericValueType>(_ value: GenericValueType, for key: K) -> Observable<Void> {
        return Observable.create({ (observer) -> Disposable in
            let path = self.pathForKey(key)
            let previousSize = self.sizeForFileAtPath(path)
            
            if NSKeyedArchiver.archiveRootObject(value, toFile: path) {
                _ = self.updateDiskAccessDateAtPath(path)
                
                let newSize = self.sizeForFileAtPath(path)
                if newSize > previousSize {
                    self.size += newSize - previousSize
                    self.controlCapacity()
                } else {
                    self.size -= previousSize - newSize
                }
                observer.on(.next(()))
                observer.onCompleted()
            } else {
                observer.on(.error(DrosteDiskError.diskSaveFailed))
                observer.onCompleted()
            }
            return Disposables.create()
        })
            .subscribeOn(cacheScheduler)
    }
    
    public func clear() {
        cacheQueue.async {
            self.itemsInDirectory(self.path).forEach { filePath in
                _ = try? self.fileManager.removeItem(atPath: filePath)
            }
            self.calculateSize()
        }
    }
    
    private func updateDiskAccessDateAtPath(_ path: String) -> Bool {
        var result = false
        
        do {
            try fileManager.setAttributes([
                FileAttributeKey.modificationDate: Date()
                ], ofItemAtPath: path)
            result = true
        } catch _ {}
        
        return result
    }
    
    private func sizeForFileAtPath(_ filePath: String) -> UInt64 {
        var size: UInt64 = 0
        
        do {
            let attributes: NSDictionary = try fileManager.attributesOfItem(atPath: filePath) as NSDictionary
            size = attributes.fileSize()
        } catch {}
        
        return size
    }
    
    private func calculateSize() {
        size = itemsInDirectory(path).reduce(0, { (accumulator, filePath) in
            accumulator + sizeForFileAtPath(filePath)
        })
    }
    
    private func controlCapacity() {
        if size > capacity {
            enumerateContentsOfDirectorySortedByAscendingModificationDateAtPath(path) { (URL, stop: inout Bool) in
                removeFileAtPath(URL.path)
                stop = size <= capacity
            }
        }
    }
    
    private func pathForKey(_ key: K) -> String {
        return (path as NSString).appendingPathComponent(key.toString().MD5String())
    }
    
    private func removeFileAtPath(_ path: String) {
        do {
            if let attributes: NSDictionary = try fileManager.attributesOfItem(atPath: path) as NSDictionary? {
                try fileManager.removeItem(atPath: path)
                size -= attributes.fileSize()
            }
        } catch _ {}
    }
    
    private func itemsInDirectory(_ directory: String) -> [String] {
        var items: [String] = []
        
        do {
            items = try fileManager.contentsOfDirectory(atPath: directory).map {
                (directory as NSString).appendingPathComponent($0)
            }
        } catch _ {}
        
        return items
    }
    
    private func enumerateContentsOfDirectorySortedByAscendingModificationDateAtPath(_ path: String, usingBlock block: (URL, inout Bool) -> Void) {
        let property = URLResourceKey.contentModificationDateKey
        
        do {
            let directoryURL = URL(fileURLWithPath: path)
            let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [property], options: [])
            let sortedContents = contents.sorted(by: { (URL1, URL2) in
                var value1: AnyObject?
                do {
                    try (URL1 as NSURL).getResourceValue(&value1, forKey: property)
                } catch _ {
                    return true
                }
                
                var value2: AnyObject?
                do {
                    try (URL2 as NSURL).getResourceValue(&value2, forKey: property)
                } catch _ {
                    return false
                }
                
                if let date1 = value1 as? Date, let date2 = value2 as? Date {
                    return date1.compare(date2) == .orderedAscending
                }
                
                return false
            })
            
            for value in sortedContents {
                var stop = false
                block(value, &stop)
                if stop {
                    break
                }
            }
        } catch _ {}
    }
}

extension NSKeyedUnarchiver {
    fileprivate static func unarchive(with filePath: String) -> Any? {
        return nil
//        return self.unarchiveObjectSafely(withFilePath: filePath)
    }
}
