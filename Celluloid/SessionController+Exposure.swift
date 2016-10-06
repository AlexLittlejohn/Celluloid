//
//  SessionController+Exposure.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 16/09/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

fileprivate let exposureDurationPower: Double = 5
fileprivate let exposureMinimumDuration: Double = 1/1000

public extension SessionController {

    /// Set the exposure mode of the camera device
    ///
    /// Setting the mode to custom exposure will override the current flash setting to off
    ///
    /// - parameter mode: AVCaptureExposureMode
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    /// - throws: CelluloidError.deviceConfigurationNotSupported
    public func setExposure(mode: AVCaptureExposureMode) throws {
        try configureDevice { device in

            guard device.exposureMode != mode else {
                return
            }

            guard device.isExposureModeSupported(mode) else {
                throw CelluloidError.deviceConfigurationNotSupported
            }

            device.exposureMode = mode

            if mode == .custom {
                flashMode = .off
            }
        }
    }

    /// Set the exposure duration
    ///
    /// Changing the exposure values will override the current flash setting to off
    ///
    /// - parameter duration: A value in 0...1
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func setExposure(duration: Double) throws {
        try configureDevice { device in
            let d = min(max(duration, 0), 1)
            let minDurationSeconds = max(CMTimeGetSeconds(device.activeFormat.minExposureDuration), exposureMinimumDuration)
            let maxDurationSeconds = CMTimeGetSeconds(device.activeFormat.maxExposureDuration)
            let newDurationSeconds = d * (maxDurationSeconds - minDurationSeconds) + minDurationSeconds

            device.setExposureModeCustomWithDuration(CMTimeMakeWithSeconds(newDurationSeconds, 1000 * 1000 * 1000), iso: AVCaptureISOCurrent, completionHandler: nil)

            flashMode = .off
        }
    }

    /// Set the exposure bias in EV units
    ///
    /// - parameter targetBias: A value in device.minExposureTargetBias...device.maxExposureTargetBias
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func setExposure(targetBias: Double) throws {
        try configureDevice { device in
            let bias = min(max(device.minExposureTargetBias, Float(targetBias)), device.maxExposureTargetBias)
            device.setExposureTargetBias(bias, completionHandler: nil)
        }
    }

    /// Set the device ISO
    ///
    /// Changing the exposure values will override the current flash setting to off
    ///
    /// - parameter iso: A value in device.activeFormat.minISO...device.activeFormat.maxISO
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func setISO(iso: Double) throws {
        try configureDevice { device in
            let _iso = min(max(device.activeFormat.minISO, Float(iso)), device.activeFormat.maxISO)
            device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, iso: _iso, completionHandler: nil)

            flashMode = .off
        }
    }
}
