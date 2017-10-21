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
import RxCocoa

public class NetworkFetcher: Fetcher {
    
    public typealias Key = URLRequest
    public typealias Value = NSData
    
    public lazy var session: URLSession = URLSession.shared
    
    public func get(_ key: URLRequest) -> Observable<NSData?> {
        return session.rx.data(request: key).map({ $0 as NSData })
    }
}
