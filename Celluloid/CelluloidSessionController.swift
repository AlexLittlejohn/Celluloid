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
 Supported media types, currently only Video/Photo
 */
enum CelluloidMediaType: CustomStringConvertible {
    case Video
    
    var description: String {
        switch self {
        case .Video:
            return AVMediaTypeVideo
        }
    }
}

/**
 Closure signature for camera startup
 */
public typealias CelluloidSessionStartupComplete = AuthorizeCameraComplete

/**
 The camera session controller. Controls the finer aspects of a camera device.
 */
public class CelluloidSessionController {
    /**
     The session object that manages the camera
     */
    public let session = AVCaptureSession()
    
    /**
     The session dispath queue named **com.zero.CelluloidSessionController.Queue**
     */
    let sessionQueue = dispatch_queue_create("com.zero.CelluloidSessionController.Queue", DISPATCH_QUEUE_SERIAL)
    
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
    var imageOutput: AVCaptureStillImageOutput!
    /**
     The current camera device
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var device: AVCaptureDevice!
    /**
     Session configuration object, set on initialization
     */
    let configuration: CelluloidConfiguration
    
    /**
     Create a new session controller with a video ouput delegate and a configuration object.
     
     - paramater **delegate**: The camera video ouput delegate
     - paramater **configuration**: A configuration object
     */
    public init(configuration: CelluloidConfiguration = CelluloidConfiguration()) {
        self.configuration = configuration
    }
    
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
    public func start(closure: CelluloidSessionStartupComplete) throws {
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
    public func stop() {
        async(sessionQueue) {
            self.session.stopRunning()
        }
    }
}

public extension CelluloidSessionController {
    /**
     The current flash mode.
     
     Will be nil if the session controller has not yet been started with `start(_:)`
     */
    var flashMode: AVCaptureFlashMode? {
        return device.flashMode
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
     
     Throws:
     - CelluloidError.FlashNotSupported
     - CelluloidError.DeviceNotSet
     - CelluloidError.DeviceLockFailed
     
     */
    public func setFlash(mode mode: AVCaptureFlashMode) throws {
        try configureDevice { device in
            guard device.hasFlash && device.isFlashModeSupported(mode) else {
                throw CelluloidError.FlashNotSupported
            }
            
            device.flashMode = mode
        }
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
    public func setFocus(toPoint toPoint: CGPoint) throws {
        try configureDevice { device in
            guard device.isFocusModeSupported(.ContinuousAutoFocus) else {
                throw CelluloidError.FocusNotSupported
            }
            
            device.focusMode = .ContinuousAutoFocus
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
    public func setExposue(toPoint toPoint: CGPoint) throws {
        try configureDevice { device in
            guard device.isExposureModeSupported(.ContinuousAutoExposure) else {
                throw CelluloidError.ExposureNotSupported
            }
            
            device.exposureMode = .ContinuousAutoExposure
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
    public func setCamera(position position: AVCaptureDevicePosition) throws {
        guard let oldInput = input else {
            throw CelluloidError.InputNotSet
        }
        
        session.beginConfiguration()
        session.removeInput(oldInput)
        
        let newDevice = try deviceWith(type: .Video, position: position)
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
    public func setCamera(zoom zoom: CGFloat) throws {
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
     - MovieOutputCreationFailed
     */
    private func setup() throws {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetHigh
        device = try deviceWith(type: .Video, position: configuration.startingCameraPosition)
        input = try videoInputFor(session: session, device: device)
        movieOutput = try movieOutputFor(session: session)
        imageOutput = try imageOutputFor(session: session)
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
    private func deviceWith(type type: CelluloidMediaType, position: AVCaptureDevicePosition) throws -> AVCaptureDevice {
        guard let devices = AVCaptureDevice.devicesWithMediaType(type.description) as? [AVCaptureDevice], device = devices.filter({ $0.position == position }).first else {
            throw CelluloidError.DeviceCreationFailed
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
    private func videoInputFor(session session: AVCaptureSession, device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        guard let input = try? AVCaptureDeviceInput(device: device) where session.canAddInput(input) else {
            throw CelluloidError.InputCreationFailed
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
    private func movieOutputFor(session session: AVCaptureSession) throws -> AVCaptureMovieFileOutput {
        let output = AVCaptureMovieFileOutput()
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.MovieOutputCreationFailed
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
    private func imageOutputFor(session session: AVCaptureSession) throws -> AVCaptureStillImageOutput {
        let output = AVCaptureStillImageOutput()
        output.outputSettings = configuration.imageOutputSettings
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.ImageOutputCreationFailed
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
            throw CelluloidError.DeviceNotSet
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }
        try closure(device)
        device.unlockForConfiguration()
    }
}
