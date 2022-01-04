//
//  NetworkFetcher.swift
//  George Tsifrikas
//
//  Created by George Tsifrikas on 16/07/2017.
//  Copyright © 2017 George Tsifrikas. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public enum NetworkFetcherError: Error {
    /// Used when the status code of the network response is not included in the range 200..<300
    case statusCodeNotOk(response: HTTPURLResponse, data: Data?)
    
    /// Used when the network response had an invalid size
    case invalidNetworkResponse(response: HTTPURLResponse)
    
    /// Used when the network request didn't manage to retrieve data
    case noDataRetrieved(response: HTTPURLResponse)
}

public class NetworkFetcher: Fetcher {
    
    public typealias Key = URLRequest
    public typealias Value = NSData
    
    public lazy var session: URLSession = URLSession.shared
    
    public init() {}
    
    private func validate(_ response: HTTPURLResponse, withData data: Data) -> Bool {
        var responseIsValid = true
        let expectedContentLength = response.expectedContentLength
        if expectedContentLength > -1 {
            responseIsValid = Int64(data.count) >= expectedContentLength
        }
        return responseIsValid
    }
    
    public func get(_ key: URLRequest) -> Observable<NSData?> {
        return Observable.create {(o) -> Disposable in
            
            let task = self.session.dataTask(with: key, completionHandler: { (data, response, error) in
                if let error = error {
                    switch (error) {
                    case URLError.cancelled:
                        o.onCompleted()
                    default:
                        o.on(.error(error))
                    }
                } else if let httpResponse = response as? HTTPURLResponse {
                    if !(200..<300).contains(httpResponse.statusCode) {
                        o.on(.error(NetworkFetcherError.statusCodeNotOk(response: httpResponse, data: data)))
                    } else if let data = data , !self.validate(httpResponse, withData: data) {
                        o.on(.error(NetworkFetcherError.invalidNetworkResponse(response: httpResponse)))
                    } else if let data = data {
                        o.on(.next(data as NSData))
                        o.onCompleted()
                    } else {
                        o.on(.error(NetworkFetcherError.noDataRetrieved(response: httpResponse)))
                    }
                }
            })
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
