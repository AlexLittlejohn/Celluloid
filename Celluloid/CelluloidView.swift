//
//  CelluloidView.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public class CelluloidView: UIView {

    lazy var sessionController: SessionController = SessionController()
    
    var preview: AVCaptureVideoPreviewLayer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        preview = createPreview(session: sessionController.session)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        preview = createPreview(session: sessionController.session)
    }
    
    public func startCamera(closure: @escaping SessionStartComplete) throws {
        try sessionController.start(completion: closure)
    }
    
    public func stopCamera(closure: @escaping SessionStopComplete) {
        sessionController.stop(closure: closure)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = layer.bounds
    }
}

public extension CelluloidView {
    var flashMode: AVCaptureFlashMode? {
        return sessionController.flashMode
    }
    
    var focusMode: AVCaptureFocusMode? {
        return sessionController.focusMode
    }
    
    var exposureMode: AVCaptureExposureMode? {
        return sessionController.exposureMode
    }
    
    var position: AVCaptureDevicePosition? {
        return sessionController.position
    }
}

public extension CelluloidView {

    public func cycleFlash() -> AVCaptureFlashMode {
        let mode = nextFlash(mode: flashMode ?? .auto)
        sessionController.setFlash(mode: mode)
        return mode
    }

    internal func nextFlash(mode: AVCaptureFlashMode) -> AVCaptureFlashMode {

        guard sessionController.device.isFlashAvailable else {
            return .off
        }

        let availableModes = sessionController.output.supportedFlashModes

        let newMode: AVCaptureFlashMode

        switch mode {
        case .on:
            newMode = .off
        case .off:
            newMode = .auto
        case .auto:
            newMode = .on
        }

        guard availableModes.contains(NSNumber(integerLiteral: newMode.rawValue)) else {
            return mode
        }

        return newMode
    }

    public func setFocus(toPoint: CGPoint) throws {
        // - focus points are in 0...1, not screen pixels
        let focusPoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try sessionController.setFocus(toPoint: focusPoint)
    }

    public func setExposue(toPoint: CGPoint) throws {
        // - exposure points are in 0...1, not screen pixels
        let exposurePoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try sessionController.setExposue(toPoint: exposurePoint)
    }

    public func swapCameraPosition() throws {
        let newPosition: AVCaptureDevicePosition = position == .front ? .back : .front
        try sessionController.setCamera(position: newPosition)
    }

    public func setCamera(zoom: CGFloat) throws {
        try sessionController.setCamera(zoom: zoom)
    }
}

extension CelluloidView {

    func createPreview(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer? {
        guard let preview = AVCaptureVideoPreviewLayer(session: session) else {
            return nil
        }

        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = layer.bounds
        
        layer.addSublayer(preview)
        
        return preview
    }
}

