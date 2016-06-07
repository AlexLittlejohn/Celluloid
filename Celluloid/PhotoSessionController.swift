//
//  PhotoSessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

class PhotoSessionController {

    let output: AVCaptureStillImageOutput
    let device: AVCaptureDevice
    
    init(session: AVCaptureSession, device: AVCaptureDevice, configuration: CelluloidConfiguration) throws {
        self.device = device
        
        output = AVCaptureStillImageOutput()
        output.outputSettings = configuration.imageOutputSettings
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.ImageOutputCreationFailed
        }
        
        session.addOutput(output)
    }
    
    func capturePhoto(closure: StillImageCaptureCompletion) {
        while device.adjustingWhiteBalance || device.adjustingExposure || device.adjustingFocus { }
        
        guard let connection = output.connectionWithMediaType(AVMediaTypeVideo) else {
            closure(nil)
            return
        }
        
        output.captureStillImageAsynchronouslyFromConnection(connection) { buffer, error in
            guard let buffer = buffer, imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), image = UIImage(data: imageData) else {
                async {
                    closure(nil)
                }
                return
            }
            
            async {
                closure(image)
            }
        }
    }
}
