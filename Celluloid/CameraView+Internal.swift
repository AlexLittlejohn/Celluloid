//
//  CameraView+Internal.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

extension CameraView {
    internal func createPreview(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        let preview = AVCaptureVideoPreviewLayer(session: session)

        preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.frame = bounds

        layer.addSublayer(preview)

        return preview
    }
}
