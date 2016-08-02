//
//  CelluloidView.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

/**
 CelluloidView is the main component of Celluloid. Use it to add camera functionality to your app.
 */
public class CelluloidView: UIView {
    /**
     The session controller is the brains behind the camera and manages all the aspects thereof.
     */
    lazy var sessionController: CelluloidSessionController = CelluloidSessionController()
    
    /**
     The preview layer used by the capture device.
     */
    var preview: AVCaptureVideoPreviewLayer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        preview = createPreview(session: sessionController.session)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        preview = createPreview(session: sessionController.session)
    }
    
    /**
     This is required to start the camera session and preview. If permission is not given by the user to access the camera the closure paramater will be false. If an error occurs the method will throw one of the following `CelluloidError` types.
     
     - DeviceCreationFailed
     - InputCreationFailed
     - ImageOutputCreationFailed
     - MovieOutputCreationFailed
     
     ---
     
     - paramater **closure**: A closure that will be called after the camera starts up and/or authorization fails
     */
    public func startCamera(closure: CelluloidSessionStartComplete) throws {
        try sessionController.start(closure: closure)
    }
    
    /**
     Stops the preview and the session from running. Call this when you remove the camera from the view or in `viewWillDissappear`
     */
    public func stopCamera(closure: CelluloidSessionStopComplete) {
        sessionController.stop(closure: closure)
    }


    public func setCaptureMode(type: CelluloidCaptureType) throws {
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = layer.bounds
    }
}

public extension CelluloidView {
    /**
     The current flash mode.

     Will be nil if the camera has not yet been started with `startCamera(_:)`
     */
    var flashMode: AVCaptureFlashMode? {
        return sessionController.flashMode
    }
    
    /**
     The current focus mode.
     
     Will be nil if the camera has not yet been started with `startCamera(_:)`
     */
    var focusMode: AVCaptureFocusMode? {
        return sessionController.focusMode
    }
    
    /**
     The current exposure mode.
     
     Will be nil if the camera has not yet been started with `startCamera(_:)`
     */
    var exposureMode: AVCaptureExposureMode? {
        return sessionController.exposureMode
    }
    
    /**
     The current camera position.
     
     Will be nil if the camera has not yet been started with `startCamera(_:)`
     */
    var position: AVCaptureDevicePosition? {
        return sessionController.position
    }
}

public extension CelluloidView {
    /**
     Cycles between the possible flash modes specified in `AVCaptureFlashMode`.
     */
    public func cycleFlash() throws -> AVCaptureFlashMode {
        let mode = nextFlash(mode: flashMode ?? .auto)
        sessionController.setFlash(mode: mode)
        return mode
    }
    
    /**
     Chooses the next flash mode based on the current flash mode.
     */
    internal func nextFlash(mode: AVCaptureFlashMode) -> AVCaptureFlashMode {

        guard sessionController.device.isFlashAvailable else {
            return .off
        }

        switch mode {
        case .on:
            return .off
        case .off:
            return .auto
        case .auto:
            return .on
        }
    }

    /**
     Sets the focus point of interest to the point specified

     Throws:
     - CelluloidError.FocusNotSupported
     - CelluloidError.DeviceNotSet
     - CelluloidError.DeviceLockFailed
     
     ---
     
     - paramater **toPoint**: The focus point of interest in screen coordinates.
     
     */
    public func setFocus(toPoint: CGPoint) throws {
        // - focus points are in 0...1, not screen pixels
        let focusPoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try sessionController.setFocus(toPoint: focusPoint)
    }

    /**
     Sets the exposure point of interest to the point specified

     Throws:
     - CelluloidError.ExposureNotSupported
     - CelluloidError.DeviceNotSet
     - CelluloidError.DeviceLockFailed
     
     ---
     
     - paramater **toPoint**: The exposure point of interest in screen coordinates.
     
     */
    public func setExposue(toPoint: CGPoint) throws {
        // - exposure points are in 0...1, not screen pixels
        let exposurePoint = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try sessionController.setExposue(toPoint: exposurePoint)
    }

    /**
     Swaps the camera position based on the current position. 
     
     i.e. front -> back or back -> front.
     
     Throws:
     - CelluloidError.InputNotSet
     - CelluloidError.DeviceCreationFailed
     - CelluloidError.InputCreationFailed
     */
    public func swapCameraPosition() throws {
        let newPosition: AVCaptureDevicePosition = position == .front ? .back : .front
        try sessionController.setCamera(position: newPosition)
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
        try setCamera(zoom: zoom)
    }
}

private extension CelluloidView {
    /**
     Provided an `AVCaptureSession` instance, create a preview layer for display
     
     - paramater **session**: The `AVCaptureSession` to create the preview with
     */
    private func createPreview(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer? {
        guard let preview = AVCaptureVideoPreviewLayer(session: session) else {
            return nil
        }
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = layer.bounds
        
        layer.addSublayer(preview)
        
        return preview
    }
}

