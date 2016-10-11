//
//  CelluloidView+Internal.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

extension CelluloidView {
    internal func createPreview(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer? {
        guard let preview = AVCaptureVideoPreviewLayer(session: session) else {
            return nil
        }

        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = bounds

        layer.addSublayer(preview)

        return preview
    }

}
