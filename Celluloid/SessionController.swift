//
//  SessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public typealias SessionStartComplete = AuthorizeCameraComplete
public typealias SessionStopComplete = () -> Void

public class SessionController {

    public let session = AVCaptureSession()
    public let captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
    
    let sessionQueue = DispatchQueue(label: "com.zero.SessionController.Queue")
    
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var device: AVCaptureDevice!

    public func start(completion: @escaping SessionStartComplete) throws {
        try setup()
        authorizeCamera { success in
            if success {
                async(queue: self.sessionQueue) {
                    self.session.startRunning()
                }
            }
            
            async {
                completion(success)
            }
        }
    }
    
    public func stop(closure: @escaping SessionStopComplete) {
        async(queue: sessionQueue) {
            self.session.stopRunning()

            async {
                closure()
            }
        }
    }
}

public extension SessionController {

    var flashMode: AVCaptureFlashMode? {
        return captureSettings.flashMode
    }
    
    var focusMode: AVCaptureFocusMode? {
        return device.focusMode
    }
    
    var exposureMode: AVCaptureExposureMode? {
        return device.exposureMode
    }
    
    var position: AVCaptureDevicePosition? {
        return device.position
    }
}

public extension SessionController {

    public func setFlash(mode: AVCaptureFlashMode) {
        captureSettings.flashMode = mode
    }

    public func setCamera(position: AVCaptureDevicePosition) throws {
        guard let oldInput = input else {
            throw CelluloidError.deviceConfigurationFailed
        }

        let newDevice = try deviceWith(position: position)
        let newInput = try inputFor(session: session, device: device)

        session.beginConfiguration()
        session.removeInput(oldInput)
        session.addInput(newInput)
        session.commitConfiguration()
        
        input = newInput
        device = newDevice
    }
    
    public func setCamera(zoom: CGFloat) throws {
        try configureDevice { device in
            device.videoZoomFactor = max(1.0, min(zoom, device.activeFormat.videoMaxZoomFactor))
        }
    }
}

internal extension SessionController {

    internal func setup() throws {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        device = try deviceWith(position: .back)
        input = try inputFor(session: session, device: device)
        output = try outputFor(session: session)
        session.commitConfiguration()
    }
    
    internal func deviceWith(position: AVCaptureDevicePosition) throws -> AVCaptureDevice {
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice], let device = devices.filter({ $0.position == position }).first else {
            throw CelluloidError.deviceConfigurationFailed
        }

        return device
    }
    
    internal func inputFor(session: AVCaptureSession, device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            throw CelluloidError.deviceConfigurationFailed
        }
        
        session.addInput(input)

        return input
    }
        
    internal func outputFor(session: AVCaptureSession) throws -> AVCapturePhotoOutput {
        let output = AVCapturePhotoOutput()

        guard session.canAddOutput(output) else {
            throw CelluloidError.deviceConfigurationFailed
        }
        
        return output
    }

    internal func configureDevice(closure: (AVCaptureDevice) throws -> Void ) throws {
        
        guard let device = device else {
            throw CelluloidError.deviceConfigurationFailed
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.deviceConfigurationFailed
        }

        try closure(device)
        device.unlockForConfiguration()
    }
}
