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
        
        let imageCache = DrosteCaches.sharedImageCache
        
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

