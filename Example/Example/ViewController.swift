//
//  ViewController.swift
//  Example
//
//  Copyright © 2016 George Tsifrikas. All rights reserved.
//

import UIKit
import RxSwift
import Droste

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let networkFetcher = NetworkFetcher()
            .mapKeys { (url: URL) -> URLRequest in//map url to urlrequest
                return URLRequest(url: url)
        }
        
        let ramCache = RamCache<URL, NSData>().expires(at: .seconds(30))
        let diskCache = DiskCache<URL, NSData>().expires(at: .seconds(120))
        
        let dataCache = ramCache + (diskCache + networkFetcher).reuseInFlight()
        
        let imageCache = dataCache
            .mapValues(
                f: { (data) -> UIImage in
                    return UIImage(data: data as Data)!
            }) { (image) -> NSData in
                return (UIImagePNGRepresentation(image) as NSData?)!
        }
        
        imageCache
            .get(URL(string: "https://dars.io/wp-content/uploads/2015/06/1435934506-50d83ee90498b3e4f9578a58ff8b5880.png")!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (image) in
                self?.imageView.image = image
            })
            .disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

