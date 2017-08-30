//
//  CameraView+Gestures.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation

extension CameraView {
    internal func setupGestures() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))

        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)

        isUserInteractionEnabled = true
    }

    @objc open func pinch(gesture: UIPinchGestureRecognizer) {
        let velocity = gesture.velocity
        try? zoom(with: velocity)
    }

    @objc open func tap(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        try? setPointOfInterest(to: point)
    }
}
