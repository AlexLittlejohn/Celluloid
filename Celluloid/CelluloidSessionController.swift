//
//  CelluloidSessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

enum CelluloidMediaType: CustomStringConvertible {
    case Video
    
    var description: String {
        switch self {
        case .Video:
            return AVMediaTypeVideo
        }
    }
}

public class CelluloidSessionController {
    public let session = AVCaptureSession()
    let sessionQueue = dispatch_queue_create("com.zero.CelluloidSessionController.Queue", DISPATCH_QUEUE_SERIAL)
    
    public var input: AVCaptureDeviceInput!
    public var videoOutput: AVCaptureVideoDataOutput!
    public var imageOutput: AVCaptureStillImageOutput!
    public var device: AVCaptureDevice!
    
    var runtimeErrorHandlingObserver: AnyObject?
    
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    public init(outputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, authorizationCompletion: AuthorizeCameraComplete) throws {
        delegate = outputDelegate
        authorizeCamera(authorizationCompletion)
        try setup()
    }
}

public extension CelluloidSessionController {
    public func setFlash(mode mode: AVCaptureFlashMode) throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        guard device.hasFlash && device.isFlashModeSupported(mode) else {
            throw CelluloidError.FlashNotSupported
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }
        
        device.flashMode = mode
        device.unlockForConfiguration()
    }
    
    public func setFocus(toPoint toPoint: CGPoint) throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        guard device.isFocusModeSupported(.ContinuousAutoFocus) else {
            throw CelluloidError.FocusNotSupported
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }
        
        device.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
        device.focusPointOfInterest = toPoint
        device.unlockForConfiguration()
    }
    
    public func setExposue(toPoint toPoint: CGPoint) throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        guard device.isExposureModeSupported(.ContinuousAutoExposure) else {
            throw CelluloidError.ExposureNotSupported
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }
        
        device.exposureMode = .ContinuousAutoExposure
        device.exposurePointOfInterest = toPoint
        device.unlockForConfiguration()
    }
    
    public func setCamera(position position: AVCaptureDevicePosition) throws {
        guard let input = input else {
            throw CelluloidError.SessionNotSet
        }
        
        session.beginConfiguration()
        session.removeInput(input)
        
        let device = try deviceWith(type: .Video, position: position)
        let newInput = try videoInputFor(session: session, device: device)
        
        session.addInput(newInput)
        session.commitConfiguration()
    }
    
    public func setCamera(zoom zoom: CGFloat) throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }
        
        device.videoZoomFactor = max(1.0, min(zoom, device.activeFormat.videoMaxZoomFactor))
        device.unlockForConfiguration()
    }

}

private extension CelluloidSessionController {
    private func setup() throws {
        guard let delegate = delegate else {
            throw CelluloidError.VideoOutputDelegateDeallocated
        }
        
        session.beginConfiguration()
        device = try deviceWith(type: .Video, position: CelluloidConfiguration.shared.startingCameraPosition)
        input = try videoInputFor(session: session, device: device)
        videoOutput = try videoOutputFor(session: session, delegate: delegate)
        imageOutput = try imageOutputFor(session: session)
        session.commitConfiguration()
    }
    
    private func deviceWith(type type: CelluloidMediaType, position: AVCaptureDevicePosition) throws -> AVCaptureDevice {
        guard let devices = AVCaptureDevice.devicesWithMediaType(type.description) as? [AVCaptureDevice], device = devices.filter({ $0.position == position }).first else {
            throw CelluloidError.DeviceCreationFailed
        }

        return device
    }
    
    private func videoInputFor(session session: AVCaptureSession, device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        guard let input = try? AVCaptureDeviceInput(device: device) where session.canAddInput(input) else {
            throw CelluloidError.InputCreationFailed
        }
        
        session.addInput(input)
        
        return input
    }
    
    private func videoOutputFor(session session: AVCaptureSession, delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws -> AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = CelluloidConfiguration.shared.videoOutputSettings
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(delegate, queue: sessionQueue)
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.VideoOutputCreationFailed
        }
        
        session.addOutput(output)
        
        return videoOutput
    }
    
    private func imageOutputFor(session session: AVCaptureSession) throws -> AVCaptureStillImageOutput {
        let output = AVCaptureStillImageOutput()
        output.outputSettings = CelluloidConfiguration.shared.imageOutputSettings
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.ImageOutputCreationFailed
        }
        
        return output
    }
    
}
