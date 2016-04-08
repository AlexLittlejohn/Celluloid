//
//  CelluloidConfiguration.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public class CelluloidConfiguration {
    public static let shared = CelluloidConfiguration()
    
    var videoOutputSettings: [String: Int] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]
    
    var imageOutputSettings: [String: String] = [AVVideoCodecKey: AVVideoCodecJPEG]
    
    var startingCameraPosition: AVCaptureDevicePosition = .Back
}
