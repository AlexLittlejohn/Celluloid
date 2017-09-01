//
//  SessionController+Camera.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 04/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

public extension SessionController {

    /// Switch the current capture device and input with the one provided from a list of supported devices in `availableDevices`
    ///
    /// - parameter newDevice: a new AVCaptureDevice to use for video input
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func toggle(to newDevice: AVCaptureDevice) throws {

        guard availableDevices.contains(newDevice) else {
            return
        }

        guard device != newDevice else {
            return
        }

        guard let oldInput = input else {
            throw CelluloidError.deviceConfigurationFailed
        }

        session.beginConfiguration()
        session.removeInput(oldInput)

        guard let newInput = try? AVCaptureDeviceInput(device: newDevice), session.canAddInput(newInput) else {
            session.addInput(oldInput)
            session.commitConfiguration()
            throw CelluloidError.deviceConfigurationFailed
        }

        session.addInput(newInput)
        session.commitConfiguration()

        input = newInput
        device = newDevice

        resetToDefaults()
    }

    public func setPointOfInterest(to point: CGPoint) throws {
        try configureDevice { device in

            let x = min(max(point.x, 0), 1)
            let y = min(max(point.y, 0), 1)

            let pointOfInterest = CGPoint(x: x, y: y)

            let focusMode = device.focusMode
            let exposureMode = device.exposureMode

            if focusMode != .locked &&
                device.isFocusPointOfInterestSupported &&
                device.isFocusModeSupported(focusMode) {
                device.focusPointOfInterest = pointOfInterest
                device.focusMode = focusMode
            }

            if exposureMode != .custom &&
                device.isExposurePointOfInterestSupported &&
                device.isExposureModeSupported(exposureMode) {
                device.exposurePointOfInterest = pointOfInterest
                device.exposureMode = exposureMode
            }
        }
    }

    public func setLensStabilisation(enabled: Bool) {
        guard let output = output, output.isLensStabilizationDuringBracketedCaptureSupported else {

            lensStabilizationEnabled = false
            return
        }

        lensStabilizationEnabled = enabled
    }
}
