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
public enum CelluloidError: Error {
    case deviceLockFailed
    case deviceNotSet
    case exposureNotSupported
    case focusNotSupported
    case flashNotSupported
    case inputNotSet
    case deviceCreationFailed
    case inputCreationFailed
    case imageOutputCreationFailed
    case movieOutputCreationFailed
}
