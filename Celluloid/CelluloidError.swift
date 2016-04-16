//
//  CelluloidError.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

/**
 CelluloidError type. All possible camera errors.
 */
public enum CelluloidError: ErrorType {
    case DeviceLockFailed
    case DeviceNotSet
    case ExposureNotSupported
    case FocusNotSupported
    case FlashNotSupported
    case InputNotSet
    case DeviceCreationFailed
    case InputCreationFailed
    case ImageOutputCreationFailed
    case MovieOutputCreationFailed
}
