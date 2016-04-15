//
//  CelluloidConfiguration.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

/**
 The configuration object, leave the default session as is or create your own configuration when initializing the camera
 */
public class CelluloidConfiguration {
    /// First camera position on initialization
    var startingCameraPosition: AVCaptureDevicePosition = .Back
    
    /// Image output options. Default type = JPEG
    var imageOutputSettings: [String: String] = [AVVideoCodecKey: AVVideoCodecJPEG]
    
    /// Video output options.
    var videoOutputSettings: [String: Int] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]
}
