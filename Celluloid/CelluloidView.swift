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

    lazy var controller: SessionController = SessionController()
    
    var preview: AVCaptureVideoPreviewLayer?

    public func start(closure: @escaping SessionStartComplete) throws {
        try controller.start { success in
            if success {
                self.preview = self.createPreview(session: self.controller.session)
            }

            closure(success)
        }
    }

    public func stop() {
        controller.stop()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = layer.bounds
    }
}

public extension CelluloidView {
    var flashMode: AVCaptureFlashMode {
        return controller.flashMode
    }
}

public extension CelluloidView {

    public func cycleFlash() -> AVCaptureFlashMode {
        let mode = nextFlash(mode: flashMode)
        controller.setFlash(mode: mode)
        return mode
    }

    internal func nextFlash(mode: AVCaptureFlashMode) -> AVCaptureFlashMode {

        guard let device = controller.device, device.isFlashAvailable else {
            return .off
        }

        let availableModes = controller.output.supportedFlashModes

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

    public func setPointOfInterest(toPoint: CGPoint) throws {

        // points of interest are in 0...1, not screen pixels
        let point = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try controller.setPointOfInterest(toPoint: point)
    }

    public func cycleCamera() throws {

        guard let device = controller.device,
            let newDevice = controller.availableDevices.nextOrFirst(after: device) else {
            throw CelluloidError.deviceConfigurationFailed
        }

        try controller.switchTo(newDevice: newDevice)
    }

    public func zoom(to level: CGFloat) throws {
        try controller.zoom(to: level)
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

