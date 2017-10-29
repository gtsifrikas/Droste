//
//  ViewController.swift
//  Example
//
//  Copyright © 2016 George Tsifrikas. All rights reserved.
//

import UIKit
import RxSwift
import RxCache

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let diskCache = DiskCache<String, UIImage>()
        
        let networkImageFetcher = NetworkFetcher()
            .mapValues(
                f: { (data) -> UIImage in
                    return UIImage(data: data as Data)!
            }) { (_) -> NSData in
                NSData()
            }
            .mapKeys { (url: String) -> URLRequest in
                URLRequest(url: URL(string: url)!)
        }
        
        let imageCache = diskCache + networkImageFetcher
        
        imageCache
            .get("https://dars.io/wp-content/uploads/2015/06/1435934506-50d83ee90498b3e4f9578a58ff8b5880.png")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[unowned self] (image) in
                self.imageView.image = image
            })
            .disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

