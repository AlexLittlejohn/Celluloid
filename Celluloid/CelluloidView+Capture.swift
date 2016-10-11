//
//  CelluloidView+Capture.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

extension CelluloidView {
    open func capturePhoto(livePhoto: Bool = true, rawCapture: Bool = false, lensStabilization: Bool = false, flashMode: AVCaptureFlashMode = .off, completion: @escaping (PHAsset?) -> Void) {
        controller.rawCaptureEnabled = rawCapture
        controller.livePhotoEnabled = livePhoto
        controller.lensStabilizationEnabled = lensStabilization
        controller.flashMode = flashMode

        guard let output = controller.output, let connection = output.connection(withMediaType: AVMediaTypeVideo) else {
            return
        }

        let orientation = connection.videoOrientation

        controller.capturePhoto(previewOrientation: orientation, willCapture: animateCapture, completion: completion)
    }
}
