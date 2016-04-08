//
//  Authorizer.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public typealias AuthorizeCameraComplete = (success: Bool) -> Void

internal func authorizeCamera(completion: AuthorizeCameraComplete) {
    guard AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) != .Authorized else {
        completion(success: true)
        return
    }
    
    AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { completion(success: $0) }
}
