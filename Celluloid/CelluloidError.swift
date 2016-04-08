//
//  CelluloidError.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

public enum CelluloidError: ErrorType {
    case DeviceCreationFailed
    case DeviceLockFailed
    case DeviceNotSet
    case ExposureNotSupported
    case FocusNotSupported
    case FlashNotSupported
    case InputCreationFailed
    case SessionNotSet
    case SessionCreationError
    case CameraAuthorizationFailed
    case ImageOutputCreationFailed
    case VideoOutputCreationFailed
    case VideoOutputDelegateDeallocated
}
