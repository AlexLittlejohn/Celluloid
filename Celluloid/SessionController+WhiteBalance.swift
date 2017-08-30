//
//  SessionController+WhiteBalance.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 16/09/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

// For sanity
fileprivate let maximumTemperature: Float = 8000
fileprivate let minimumTemperature: Float = 3000
fileprivate let maximumTint: Float = 150
fileprivate let minimumTint: Float = -150
fileprivate let minimumGain: Float = 1.0

public extension SessionController {

    /// Set the white balance mode
    ///
    /// - parameter mode: AVCaptureWhiteBalanceMode
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    /// - throws: CelluloidError.deviceConfigurationNotSupported
    public func setWhiteBalance(mode: AVCaptureDevice.WhiteBalanceMode) throws {
        try configureDevice { device in

            guard device.whiteBalanceMode != mode else {
                return
            }

            guard device.isWhiteBalanceModeSupported(mode) else {
                throw CelluloidError.deviceConfigurationNotSupported
            }

            device.whiteBalanceMode = mode
        }
    }

    /// Set white balance gains
    ///
    /// - parameter gains: The computed white balance gains. Will be normalized to prevent out of bounds errors
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func setWhiteBalance(gains: AVCaptureDevice.WhiteBalanceGains) throws {
        try configureDevice { device in
            let normalized = normalizedGains(gains: gains, device: device)
            device.setWhiteBalanceModeLocked(with: normalized, completionHandler: nil)
        }
    }

    /// Change the white balance gains to match
    ///
    /// - parameter temperature: tempertature in kelvin 3000...8000
    /// - parameter tint:        tint -150.0...150.0
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func setWhiteBalance(temperature: Double, tint: Double) throws {

        guard let device = device else {
            throw CelluloidError.deviceConfigurationFailed
        }

        let _temperature = min(max(minimumTemperature, Float(temperature)), maximumTemperature)
        let _tint = min(max(minimumTint, Float(tint)), maximumTint)

        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: _temperature, tint: _tint)

        try setWhiteBalance(gains: device.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
}


/// Normalizes a set of gains for a device to prevent out of bounds errors
///
/// - parameter gains:  An unnormalized AVCaptureWhiteBalanceGains struct
/// - parameter device: A device against which the gains should be normalized
///
/// - returns: normalized AVCaptureWhiteBalanceGains
fileprivate func normalizedGains(gains: AVCaptureDevice.WhiteBalanceGains, device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
    var g = gains

    g.redGain = max(minimumGain, g.redGain)
    g.greenGain = max(minimumGain, g.greenGain)
    g.blueGain = max(minimumGain, g.blueGain)

    g.redGain = min(device.maxWhiteBalanceGain, g.redGain)
    g.greenGain = min(device.maxWhiteBalanceGain, g.greenGain)
    g.blueGain = min(device.maxWhiteBalanceGain, g.blueGain)
    
    return g
}
