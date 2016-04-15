//
//  ViewController.swift
//  Example
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import Celluloid

class ViewController: UIViewController {

    let cameraView = CelluloidView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(cameraView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try cameraView.startCamera() { success in
                
            }
            print("camera started")
        } catch {
            print("camera start failed")
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cameraView.frame = view.bounds
    }
}

