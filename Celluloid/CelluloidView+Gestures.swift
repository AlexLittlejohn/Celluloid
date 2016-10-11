//
//  CelluloidView+Gestures.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 11/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation

extension CelluloidView {
    internal func setup() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))

        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)

        isUserInteractionEnabled = true
    }

    open func pinch(gesture: UIPinchGestureRecognizer) {
        let velocity = gesture.velocity
        try? zoomWith(velocity: velocity)
    }

    open func tap(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        try? setPointOfInterest(toPoint: point)
    }
}
