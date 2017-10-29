//
//  ViewController.swift
//  Example
//
//  Copyright © 2016 George Tsifrikas. All rights reserved.
//

import UIKit
import RxCache

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let cache = DiskCache<String, NSData>()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

