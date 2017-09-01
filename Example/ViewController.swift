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

    let cameraView = CameraView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(cameraView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try cameraView.start() { success in
                print(success)
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

