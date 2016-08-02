//
//  CelluloidSessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

/**
 Closure signature for camera startup
 */
public typealias CelluloidSessionStartComplete = AuthorizeCameraComplete
public typealias CelluloidSessionStopComplete = () -> Void

/**
 The camera session controller. Controls the finer aspects of a camera device.
 */
public class CelluloidSessionController {

    /**
     The session object that manages the camera
     */
    public let session = AVCaptureSession()
    public let captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
    
    /**
     The session dispath queue named **com.zero.CelluloidSessionController.Queue**
     */
    let sessionQueue = DispatchQueue(label: "com.zero.CelluloidSessionController.Queue", attributes: .serial)
    
    /**
     The current camera input
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var input: AVCaptureDeviceInput!

    /**
     The current video output
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var movieOutput: AVCaptureMovieFileOutput!

    /**
     The current image output
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var photoOutput: AVCapturePhotoOutput!

    /**
     The current camera device
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var device: AVCaptureDevice!

    /**
     This is required to start the camera session. If permission is not given by the user to access the camera the closure paramater will be false. If an error occurs the method will throw one of the following `CelluloidError` types.
     
     - VideoOutputDelegateDeallocated
     - DeviceCreationFailed
     - InputCreationFailed
     - ImageOutputCreationFailed
     - VideoOutputCreationFailed
     
     ---
     
     - paramater **closure**: A closure that will be called after the session starts up and/or authorization fails
     */
    public func start(closure: CelluloidSessionStartComplete) throws {
        try setup()
        authorizeCamera { success in
            if success {
                async(self.sessionQueue) {
                    self.session.startRunning()
                }
            }
            
            async {
                closure(success)
            }
        }
    }
    
    /**
     Stops the camera session from running.
     */
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
    /**
     The current flash mode.
     */
    var flashMode: AVCaptureFlashMode? {
        return captureSettings.flashMode
    }
    
    /**
     The current focus mode.
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var focusMode: AVCaptureFocusMode? {
        return device.focusMode
    }
    
    /**
     The current exposure mode.
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var exposureMode: AVCaptureExposureMode? {
        return device.exposureMode
    }
    
    /**
     The current camera position.
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var position: AVCaptureDevicePosition? {
        return device.position
    }
}

public extension CelluloidSessionController {
    /**
     Set the flash to a mode specified in `AVCaptureFlashMode`.
     */
    public func setFlash(mode: AVCaptureFlashMode) {
        captureSettings.flashMode = mode
    }
    
    /**
     Sets the focus point of interest to the point specified
     
     Throws:
     - CelluloidError.FocusNotSupported
     - CelluloidError.DeviceNotSet
     - CelluloidError.DeviceLockFailed
     
     ---
     
     - paramater **toPoint**: The focus point of interest in reference coordinates - 0...1.
     
     */
    public func setFocus(toPoint: CGPoint) throws {
        try configureDevice { device in
            guard device.isFocusModeSupported(.continuousAutoFocus) else {
                throw CelluloidError.focusNotSupported
            }
            
            device.focusMode = .continuousAutoFocus
            device.focusPointOfInterest = toPoint
        }
    }
    
    /**
     Sets the exposure point of interest to the point specified
     
     Throws:
     - CelluloidError.ExposureNotSupported
     - CelluloidError.DeviceNotSet
     - CelluloidError.DeviceLockFailed
     
     ---
     
     - paramater **toPoint**: The exposure point of interest in reference coordinates - 0...1.
     
     */
    public func setExposue(toPoint: CGPoint) throws {
        try configureDevice { device in
            guard device.isExposureModeSupported(.continuousAutoExposure) else {
                throw CelluloidError.exposureNotSupported
            }
            
            device.exposureMode = .continuousAutoExposure
            device.exposurePointOfInterest = toPoint
        }
    }
    
    /**
     Set the camera position to a position specified in `AVCaptureDevicePosition`
     
     Throws:
     - CelluloidError.InputNotSet
     - CelluloidError.DeviceCreationFailed
     - CelluloidError.InputCreationFailed
     
     ---
     
     - paramater **position**: The new position for the camera.
     
     */
    public func setCamera(position: AVCaptureDevicePosition) throws {
        guard let oldInput = input else {
            throw CelluloidError.inputNotSet
        }
        
        session.beginConfiguration()
        session.removeInput(oldInput)
        
        let newDevice = try deviceWith(position: position)
        let newInput = try videoInputFor(session: session, device: device)
        
        session.addInput(newInput)
        session.commitConfiguration()
        
        input = newInput
        device = newDevice
    }
    
    /**
     Sets the zoom scale level that will be applied to the preview and the output.
     
     Note that zoom is digital only and that high zoom scales will degrade the image output quality.
     
     Throws:
     - CelluloidError.DeviceNotSet
     - CelluloidError.DeviceLockFailed
     
     ---
     
     - paramater **zoom**: A float value denoting the desired zoom scale
     */
    public func setCamera(zoom: CGFloat) throws {
        try configureDevice { device in
            device.videoZoomFactor = max(1.0, min(zoom, device.activeFormat.videoMaxZoomFactor))
        }
    }
}

private extension CelluloidSessionController {
    /**
     Initializes all the requires camera objects
     
     If an error occurs the method will throw one of the following `CelluloidError` types.
     
     - DeviceCreationFailed
     - InputCreationFailed
     - ImageOutputCreationFailed
     */
    private func setup() throws {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        device = try deviceWith(position: .back)
        input = try videoInputFor(session: session, device: device)
        photoOutput = try photoOutputFor(session: session)
        session.commitConfiguration()
    }
    
    /**
     Create a capture device using a session and a position
     
     Throws:
     - DeviceCreationFailed
     
     ---
     
     - paramater **type**: The required media type for the device.
     - paramater **position**: The required camera position for the device.
     - returns: A new AVCaptureDevice that fits the type and position
     */
    private func deviceWith(position: AVCaptureDevicePosition) throws -> AVCaptureDevice {
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice], let device = devices.filter({ $0.position == position }).first else {
            throw CelluloidError.deviceCreationFailed
        }

        return device
    }
    
    /**
     Create a video input for the camera
     
     Throws:
     - InputCreationFailed
     
     ---
     
     - paramater **session**: A capture session used to create the input.
     - paramater **device**: A device used to create the input.
     - returns: A new `AVCaptureDeviceInput` for the session and device
     */
    private func videoInputFor(session: AVCaptureSession, device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            throw CelluloidError.inputCreationFailed
        }
        
        session.addInput(input)

        return input
    }
    
    /**
     Create a movie output for the camera
     
     Throws:
     - MovieOutputCreationFailed
     
     ---
     
     - paramater **session**: A capture session to create the output for.
     - returns: A new `AVCaptureMovieFileOutput` for the session and delegate
     */
    private func movieOutputFor(session: AVCaptureSession) throws -> AVCaptureMovieFileOutput {
        let output = AVCaptureMovieFileOutput()
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.movieOutputCreationFailed
        }
        
        session.addOutput(output)
        
        return output
    }
    
    /**
     Create an image output for the camera
     
     Throws:
     - ImageOutputCreationFailed
     
     ---
     
     - paramater **session**: A capture session to create the output for.
     - returns: A new `AVCaptureStillImageOutput` for the session and device
     */
    private func photoOutputFor(session: AVCaptureSession) throws -> AVCapturePhotoOutput {
        let output = AVCapturePhotoOutput()

        guard session.canAddOutput(output) else {
            throw CelluloidError.imageOutputCreationFailed
        }
        
        return output
    }
}

private extension CelluloidSessionController {
    /**
     Helper for configuring the device
     
     Throws:
     - DeviceNotSet
     - DeviceLockFailed
     
     ---
     
     - paramater **closure**: A throwable closure to call between device configuration locks.
     */
    private func configureDevice(closure: (AVCaptureDevice) throws -> Void ) throws {
        
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
