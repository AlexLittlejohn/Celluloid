//
//  CelluloidSessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public typealias CelluloidSessionStartComplete = AuthorizeCameraComplete
public typealias CelluloidSessionStopComplete = () -> Void

public class CelluloidSessionController {

    public let session = AVCaptureSession()
    public let captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
    
    let sessionQueue = DispatchQueue(label: "com.zero.CelluloidSessionController.Queue")
    
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var device: AVCaptureDevice!

    public func start(completion: CelluloidSessionStartComplete) throws {
        try setup()
        authorizeCamera { success in
            if success {
                async(self.sessionQueue) {
                    self.session.startRunning()
                }
            }
            
            async {
                completion(success)
            }
        }
    }
    
    public func stop(closure: CelluloidSessionStopComplete) {
        async(sessionQueue) {
            self.session.stopRunning()

            async {
                closure()
            }
        }
    }
}

public extension CelluloidSessionController {

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

public extension CelluloidSessionController {

    public func setFlash(mode: AVCaptureFlashMode) {
        captureSettings.flashMode = mode
    }
    
    public func setFocus(toPoint: CGPoint) throws {
        try configureDevice { device in
            guard device.isFocusModeSupported(.continuousAutoFocus) else {
                throw CelluloidError.focusNotSupported
            }
            
            device.focusMode = .continuousAutoFocus
            device.focusPointOfInterest = toPoint
        }
    }
    
    public func setExposue(toPoint: CGPoint) throws {
        try configureDevice { device in
            guard device.isExposureModeSupported(.continuousAutoExposure) else {
                throw CelluloidError.exposureNotSupported
            }
            
            device.exposureMode = .continuousAutoExposure
            device.exposurePointOfInterest = toPoint
        }
    }

    public func setCamera(position: AVCaptureDevicePosition) throws {
        guard let oldInput = input else {
            throw CelluloidError.inputNotSet
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

fileprivate extension CelluloidSessionController {

    fileprivate func setup() throws {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        device = try deviceWith(position: .back)
        input = try inputFor(session: session, device: device)
        output = try outputFor(session: session)
        session.commitConfiguration()
    }
    
    fileprivate func deviceWith(position: AVCaptureDevicePosition) throws -> AVCaptureDevice {
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice], let device = devices.filter({ $0.position == position }).first else {
            throw CelluloidError.deviceCreationFailed
        }

        return device
    }
    
    fileprivate func inputFor(session: AVCaptureSession, device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            throw CelluloidError.inputCreationFailed
        }
        
        session.addInput(input)

        return input
    }
        
    fileprivate func outputFor(session: AVCaptureSession) throws -> AVCapturePhotoOutput {
        let output = AVCapturePhotoOutput()

        guard session.canAddOutput(output) else {
            throw CelluloidError.imageOutputCreationFailed
        }
        
        return output
    }

    fileprivate func configureDevice(closure: (AVCaptureDevice) throws -> Void ) throws {
        
        guard let device = device else {
            throw CelluloidError.deviceNotSet
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.deviceLockFailed
        }

        try closure(device)
        device.unlockForConfiguration()
    }
}
