//
//  CelluloidView.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public class CelluloidView: UIView {

    lazy var controller = SessionController()
    
    var preview: AVCaptureVideoPreviewLayer?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        setup()
    }

    public func start(_ closure: @escaping SessionStartComplete) throws {
        

        try controller.start { success in
            if success {
                self.preview = self.createPreview(session: self.controller.session)
            }

            closure(success)
        }
    }

    public func stop() {
        controller.stop()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = bounds
    }

    open func animateCapture() {
        alpha = 0
        UIView.animate(withDuration: 0.25) { 
            self.alpha = 1
        }
    }
}

public extension CelluloidView {

    public func cycleFlash() -> AVCaptureFlashMode {
        let mode = nextFlash(mode: controller.flashMode)
        controller.setFlash(mode: mode)
        return mode
    }

    internal func nextFlash(mode: AVCaptureFlashMode) -> AVCaptureFlashMode {

        guard let device = controller.device, device.isFlashAvailable else {
            return .off
        }

        let availableModes = controller.output.supportedFlashModes

        let newMode: AVCaptureFlashMode

        switch mode {
        case .on:
            newMode = .off
        case .off:
            newMode = .auto
        case .auto:
            newMode = .on
        }

        guard availableModes.contains(NSNumber(integerLiteral: newMode.rawValue)) else {
            return mode
        }

        return newMode
    }

    public func setPointOfInterest(toPoint: CGPoint) throws {

        // points of interest are in 0...1, not screen pixels
        let point = CGPoint(x: toPoint.x / frame.width, y: toPoint.y / frame.height)
        try controller.setPointOfInterest(toPoint: point)
    }

    public func cycleCamera() throws {

        guard let device = controller.device,
            let newDevice = controller.availableDevices.nextOrFirst(after: device) else {
            throw CelluloidError.deviceConfigurationFailed
        }

        try controller.switchTo(newDevice: newDevice)
    }

    public func zoomWith(velocity: CGFloat) throws {

        guard let device = controller.device else {
            throw CelluloidError.deviceConfigurationFailed
        }

        guard !velocity.isNaN else {
            return
        }

        let velocityFactor: CGFloat = 5.0
        let desiredZoomFactor = device.videoZoomFactor + atan2(velocity, velocityFactor)

        try controller.zoom(to: desiredZoomFactor)
    }
}

extension CelluloidView {

    func setup() {
        let zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoom(gesture:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))
        let doubleTapGesture = UITapGestureRecognizer(target: self, action:#selector(doubleTap(gesture:)))

        doubleTapGesture.numberOfTapsRequired = 2

        addGestureRecognizer(zoomGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(doubleTapGesture)

        isUserInteractionEnabled = true
    }

    func zoom(gesture: UIPinchGestureRecognizer) {
        let velocity = gesture.velocity
        try? zoomWith(velocity: velocity)
    }

    func tap(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        try? setPointOfInterest(toPoint: point)
    }

    func doubleTap(gesture: UITapGestureRecognizer) {
        guard let orientation = preview?.connection.videoOrientation else {
            return
        }

        controller.capturePhoto(previewOrientation: orientation, willCapture: animateCapture) { asset in

        }
    }

    func createPreview(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer? {
        guard let preview = AVCaptureVideoPreviewLayer(session: session) else {
            return nil
        }

        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = bounds
        
        layer.addSublayer(preview)
        
        return preview
    }
}

