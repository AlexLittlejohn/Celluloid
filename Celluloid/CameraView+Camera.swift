//
//  CameraView+Camera.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

extension CameraView {

    public func cycleFlash() -> AVCaptureDevice.FlashMode {
        let mode = nextFlash(mode: controller.flashMode)
        controller.setFlash(mode: mode)
        return mode
    }

    internal func nextFlash(mode: AVCaptureDevice.FlashMode) -> AVCaptureDevice.FlashMode {

        guard let device = controller.device, device.isFlashAvailable else {
            return .off
        }

        let availableModes = controller.output.supportedFlashModes

        let newMode: AVCaptureDevice.FlashMode

        switch mode {
        case .on:
            newMode = .off
        case .off:
            newMode = .auto
        case .auto:
            newMode = .on
        }

        guard availableModes.contains(newMode) else {
            return mode
        }

        return newMode
    }

    public func setPointOfInterest(to point: CGPoint) throws {

        // points of interest are in 0...1, not screen pixels
        let normalisedPoint = CGPoint(x: point.x / frame.width, y: point.y / frame.height)
        try controller.setPointOfInterest(to: normalisedPoint)
    }

    public func cycleCamera() throws {

        guard let device = controller.device,
            let newDevice = controller.availableDevices.nextOrFirst(after: device) else {
                throw CelluloidError.deviceConfigurationFailed
        }

        try controller.toggle(to: newDevice)
    }

    open func zoom(with velocity: CGFloat) throws {

        guard let device = controller.device else {
            throw CelluloidError.deviceConfigurationFailed
        }

        guard !velocity.isNaN else {
            return
        }

        let velocityFactor: CGFloat = 8.0
        let desiredZoomFactor = device.videoZoomFactor + atan2(velocity, velocityFactor)
        
        try controller.zoom(to: desiredZoomFactor)
    }
}
