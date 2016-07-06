//
//  Authorizer.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

/**
 Camera authorization closure signature.
 */
public typealias AuthorizeCameraComplete = (Bool) -> Void

/**
 Camera authorization function.
 */
internal func authorizeCamera(_ completion: AuthorizeCameraComplete) {
    
    guard AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != .authorized else {
        completion(true)
        return
    }
    
    AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { completion($0) }
}
