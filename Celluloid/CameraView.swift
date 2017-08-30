//
//  CameraView.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/03.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

public class CameraView: UIView {

    public let controller = SessionController()
    
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
        setupGestures()
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
}
