//
//  CelluloidView.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public typealias CelluloidStartUpComplete = (success: Bool) -> Void

public class CelluloidView: UIView {

    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var device: AVCaptureDevice!
    var output: AVCaptureStillImageOutput!
    var preview: AVCaptureVideoPreviewLayer!
    
    var position = AVCaptureDevicePosition.Back
    
    public func startCamera(completion: CelluloidStartUpComplete) throws {
        session = createSession()
        preview = try createPreview(session: session)
        
        layer.addSublayer(preview)
        
        session.startRunning()
    }
    
    public func stopCamera() {
        session.stopRunning()
        preview?.removeFromSuperlayer()
        
        session = nil
        input = nil
        output = nil
        preview = nil
        device = nil
    }
}

public extension CelluloidView {
    var flashMode: AVCaptureFlashMode {
        return device.flashMode ?? .Off
    }
    var focusMode: AVCaptureFocusMode {
        return device.focusMode ?? .Locked
    }
    var exposureMode: AVCaptureExposureMode {
        return device.exposureMode ?? .Locked
    }
}

public extension CelluloidView {
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
    
    public func cycleFlash() throws {
        guard let device = device where device.hasFlash else {
            throw CelluloidError.DeviceNotSet
        }
        
        let mode = nextFlashMode(device.flashMode)
        try setFlash(mode: mode)
    }
    
    public func nextFlashMode(mode: AVCaptureFlashMode) -> AVCaptureFlashMode {
        let flashMode: AVCaptureFlashMode
        
        if mode == .On {
            flashMode = .Off
        } else if mode == .Off {
            flashMode = .Auto
        } else {
            flashMode = .On
        }
        
        return flashMode
    }
}

public extension CelluloidView {
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
        
        // focus points are in the range of 0...1, not screen pixels
        let focusPoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        
        device.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
        device.focusPointOfInterest = focusPoint
        device.unlockForConfiguration()
    }
}

public extension CelluloidView {
    public func setExposueReference(toPoint toPoint: CGPoint) throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        guard device.isExposureModeSupported(.ContinuousAutoExposure) else {
            throw CelluloidError.ExposureNotSupported
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }

        // exposure points are in the range of 0...1, not screen pixels
        let focusPoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        
        device.exposureMode = .ContinuousAutoExposure
        device.exposurePointOfInterest = focusPoint
        device.unlockForConfiguration()
    }
}

public extension CelluloidView {
    public func setCamera(position position: AVCaptureDevicePosition) throws {
        guard let session = session, input = input else {
            throw CelluloidError.SessionNotSet
        }
        
        session.beginConfiguration()
        session.removeInput(input)
        
        let device = try createDevice(position: position)
        let newInput = try createInput(device: device)
        
        session.addInput(newInput)
        session.commitConfiguration()
    }
    
    public func swapCameraPosition() throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        guard device.isExposureModeSupported(.ContinuousAutoExposure) else {
            throw CelluloidError.ExposureNotSupported
        }
        
        let position = nextCamera(position: device.position)
        
        try setCamera(position: position)
    }
    
    public func nextCamera(position position: AVCaptureDevicePosition) -> AVCaptureDevicePosition {
        
        let newPosition: AVCaptureDevicePosition
        
        if position == .Front {
            newPosition = .Back
        } else {
            newPosition = .Front
        }
        
        return newPosition
    }
}

public extension CelluloidView {
    public func setCamera(zoom zoom: CGFloat) throws {
        guard let device = device else {
            throw CelluloidError.DeviceNotSet
        }
        
        do { try device.lockForConfiguration() } catch {
            throw CelluloidError.DeviceLockFailed
        }
        
        let desiredZoomFactor = device.videoZoomFactor + atan2f(pinchGR.velocity, pinchVelocityDividerFactor)
        device.videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor));

    }
}

private extension CelluloidView {
    private func createSession() -> AVCaptureSession {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        session.startRunning()
        return session
    }
    
    private func createPreview(session session: AVCaptureSession) throws -> AVCaptureVideoPreviewLayer {
        let device = try createDevice(position: position)
        let input = try createInput(device: device)
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
    
        let output = createOutput()
        
        session.addOutput(output)
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = bounds
        
        return preview
    }
    
    private func createDevice(position position: AVCaptureDevicePosition) throws -> AVCaptureDevice {
        guard let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice], device = devices.filter({ $0.position == position }).first else {
            throw CelluloidError.DeviceCreationFailed
        }
        
        if device.hasFlash && device.isFlashModeSupported(.Auto) {
            do { try device.lockForConfiguration() } catch {
                throw CelluloidError.DeviceLockFailed
            }
            
            device.flashMode = .Auto
            device.unlockForConfiguration()
        }
        
        self.device = device
        
        return device
    }
    
    private func createInput(device device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            throw CelluloidError.InputCreationFailed
        }
        
        self.input = input
        
        return input
    }
    
    private func createOutput() -> AVCaptureOutput {
        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        let output = AVCaptureStillImageOutput()
        output.outputSettings = outputSettings
        
        self.output = output
        
        return output
    }
}

