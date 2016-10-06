//
//  SessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/06.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public typealias SessionStartComplete = AuthorizeComplete
public typealias SessionStopComplete = () -> Void

public class SessionController {

    public let session = AVCaptureSession()
    public let captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
    public var availableDevices: [AVCaptureDevice] {
        return discovery?.devices ?? []
    }
    public var flashMode: AVCaptureFlashMode = .off
    public var isLensStabilizationEnabled: Bool = false

    let sessionQueue = DispatchQueue(label: "com.Celluloid.SessionController.Queue")
    
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var device: AVCaptureDevice!

    let discovery = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera, .builtInTelephotoCamera], mediaType: AVMediaTypeVideo, position: .unspecified)

    public func start(completion: @escaping SessionStartComplete) throws {
        authorizeCamera { success in
            if success {
                self.sessionQueue.sync {
                    self.session.startRunning()

                    DispatchQueue.main.async {
                        completion(success)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }
    
    public func stop() {
        sessionQueue.sync {
            self.session.stopRunning()
        }
    }

    func resetToDefaults() {
        let autoValue = NSNumber(integerLiteral: AVCaptureFlashMode.auto.rawValue)
        let autoAvailable: Bool = device.isFlashAvailable && output.supportedFlashModes.contains(autoValue)

        flashMode = autoAvailable ? .auto : .off

        isLensStabilizationEnabled = false
    }
}

public extension SessionController {

    public func setFlash(mode: AVCaptureFlashMode) {
        captureSettings.flashMode = mode
    }

    public func zoom(to level: CGFloat) throws {
        try configureDevice { device in
            device.videoZoomFactor = max(1.0, min(level, device.activeFormat.videoMaxZoomFactor))
        }
    }
}

internal extension SessionController {

    internal func setup() throws {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto

        guard let videoDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .unspecified) else {
            throw CelluloidError.deviceConfigurationFailed
        }

        guard let audioDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInMicrophone, mediaType: AVMediaTypeAudio, position: .unspecified) else {
            throw CelluloidError.deviceConfigurationFailed
        }

        input = try addInputFor(session: session, device: videoDevice)
        let _ = try addInputFor(session: session, device: audioDevice)

        device = videoDevice
        output = try outputFor(session: session)
        session.commitConfiguration()
    }
    
    internal func deviceWith(position: AVCaptureDevicePosition) throws -> AVCaptureDevice {

        guard let device = availableDevices.filter({ $0.position == position }).first else {
            throw CelluloidError.deviceConfigurationFailed
        }

        return device
    }
    
    internal func addInputFor(session: AVCaptureSession, device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
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
