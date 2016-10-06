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
 Authorization closure signature.
 */
public typealias AuthorizeComplete = (Bool) -> Void

/**
 Camera authorization function. Can call the closure on an arbitrary thread
 */
internal func authorizeCamera(_ completion: @escaping AuthorizeComplete) {

    let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)

    switch authorizationStatus {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: completion)
    default:
        completion(false)
    }
}

/**
 Audio authorization function. Can call the closure on an arbitrary thread
 */
internal func authorizeMicrophone(_ completion: @escaping AuthorizeComplete) {

    let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)

    switch authorizationStatus {
    case .authorized:
        completion(true)
    case .denied, .restricted:
        completion(false)
    case .notDetermined:
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: completion)
    }
}
