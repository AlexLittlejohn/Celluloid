//
//  CelluloidView.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public typealias CelluloidStartUpComplete = (success: Bool, error: CelluloidError?) -> Void

public class CelluloidView: UIView {
    
    var sessionController: CelluloidSessionController!
    var preview: AVCaptureVideoPreviewLayer!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func startCamera(completion: CelluloidStartUpComplete) {
        
        preview = createPreview(session: sessionController.session)
        
        layer.addSublayer(preview)
        
        sessionController.session.startRunning()
    }
    
    public func stopCamera() {
        sessionController.session.stopRunning()
    }
}

public extension CelluloidView {
    var flashMode: AVCaptureFlashMode {
        return sessionController.device.flashMode ?? .Off
    }
    var focusMode: AVCaptureFocusMode {
        return sessionController.device.focusMode ?? .Locked
    }
    var exposureMode: AVCaptureExposureMode {
        return sessionController.device.exposureMode ?? .Locked
    }
    
    var position: AVCaptureDevicePosition {
        return sessionController.device.position ?? CelluloidConfiguration.shared.startingCameraPosition
    }
}

public extension CelluloidView {
    public func cycleFlash() throws {
        let mode = nextFlashMode(flashMode)
        try sessionController.setFlash(mode: mode)
    }
    
    public func nextFlashMode(mode: AVCaptureFlashMode) -> AVCaptureFlashMode {
        switch mode {
        case .On:
            return .Off
        case .Off:
            return .Auto
        case .Auto:
            return .On
        }
    }
}

public extension CelluloidView {
    public func setFocus(toPoint toPoint: CGPoint) throws {
        // focus points are in 0...1, not screen pixels
        let focusPoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try sessionController.setFocus(toPoint: focusPoint)
    }
}

public extension CelluloidView {
    public func setExposue(toPoint toPoint: CGPoint) throws {
        // exposure points are in 0...1, not screen pixels
        let exposurePoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try sessionController.setExposue(toPoint: exposurePoint)
    }
}

public extension CelluloidView {
    public func swapCameraPosition() throws {
        let newPosition: AVCaptureDevicePosition = position == .Front ? .Back : .Front
        try sessionController.setCamera(position: newPosition)
    }
}

public extension CelluloidView {
    public func setCamera(zoom zoom: CGFloat) throws {
        try setCamera(zoom: zoom)
    }
}

private extension CelluloidView {
    private func createPreview(session session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = bounds
        
        return preview
    }
}

