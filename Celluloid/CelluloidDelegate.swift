//
//  CelluloidDelegate.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 7/15/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import Photos

protocol CelluloidDelegate {
    func cameraDidCapture(photo: Photo)
    func cameraDidCapture(livePhoto: LivePhoto)
    func cameraCaptureDidFail(error: Error)
    func cameraDidStart()
    func cameraDidStop(error: Error?)
}
