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

struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

public class SessionController {

    public let session = AVCaptureSession()
    public var availableDevices: [AVCaptureDevice] {
        return discovery.devices
    }

    var flashMode: AVCaptureDevice.FlashMode = .off
    var lensStabilizationEnabled: Bool = false
    var rawCaptureEnabled: Bool = false
    var livePhotoEnabled: Bool = true

    let sessionQueue = DispatchQueue(label: "com.zero.celluloid.sessionController.queue")
    
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var device: AVCaptureDevice!

    let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInDuoCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera], mediaType: AVMediaType.video, position: .unspecified)

    var photoCaptureDelegates: [Int64: PhotoCaptureDelegate] = [:]

    public func start(completion: @escaping SessionStartComplete) throws {
        try self.setup()
        authorizeCamera { success in
            if success {
                self.sessionQueue.sync {
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
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
        guard session.isRunning else {
            return
        }

        sessionQueue.sync {
            self.session.stopRunning()
        }
    }

    func resetToDefaults() {
        let autoValue = AVCaptureDevice.FlashMode.auto
        let autoAvailable: Bool = device.isFlashAvailable && output.supportedFlashModes.contains(autoValue)

        flashMode = autoAvailable ? .auto : .off

        lensStabilizationEnabled = false
    }
}

public extension SessionController {

    public func setFlash(mode: AVCaptureDevice.FlashMode) {
        flashMode = mode
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
        session.sessionPreset = AVCaptureSession.Preset.photo

        guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .unspecified) else {
            throw CelluloidError.deviceConfigurationFailed
        }

        guard let audioDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInMicrophone, for: AVMediaType.audio, position: .unspecified) else {
            throw CelluloidError.deviceConfigurationFailed
        }

        input = try addInputFor(session: session, device: videoDevice)
        let _ = try addInputFor(session: session, device: audioDevice)

        device = videoDevice
        output = try outputFor(session: session)
        session.commitConfiguration()
    }
    
    internal func deviceWith(position: AVCaptureDevice.Position) throws -> AVCaptureDevice {

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

        session.addOutput(output)
        
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
