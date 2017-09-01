//
//  CameraView+Capture.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

extension CameraView {
    open func capturePhoto(livePhoto: Bool = true, rawCapture: Bool = false, lensStabilization: Bool = false, flashMode: AVCaptureDevice.FlashMode = .off, completion: @escaping (PHAsset?) -> Void) {
        controller.rawCaptureEnabled = rawCapture
        controller.livePhotoEnabled = livePhoto
        controller.lensStabilizationEnabled = lensStabilization
        controller.flashMode = flashMode

        guard let output = controller.output, let connection = output.connection(with: AVMediaType.video) else {
            return
        }

        let orientation = connection.videoOrientation

        controller.capturePhoto(previewOrientation: orientation, willCapture: animateCapture, completion: completion)
    }
}
