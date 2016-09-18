//
//  SessionController+Focus.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 16/09/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation

public extension SessionController {

    /// Set the focus mode to a supported value
    ///
    /// - parameter mode: AVCaptureFocusMode
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    /// - throws: CelluloidError.deviceConfigurationNotSupported
    public func setFocus(mode: AVCaptureFocusMode) throws {
        try configureDevice { device in
            guard device.isFocusModeSupported(mode) else {
                throw CelluloidError.deviceConfigurationNotSupported
            }

            device.focusMode = mode
        }
    }


    /// Set the lens position to control focus
    ///
    /// - parameter position: A value in 0...1
    ///
    /// - throws: CelluloidError.deviceConfigurationFailed
    public func setLens(position: Double) throws {
        try configureDevice { device in
            let p = min(max(position, 0), 1)
            device.setFocusModeLockedWithLensPosition(Float(p), completionHandler: nil)
        }
    }

}
