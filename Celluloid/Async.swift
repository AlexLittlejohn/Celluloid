//
//  Async.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/14.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

/// dispatch_async wrapper utility
func async(_ queue: DispatchQueue = DispatchQueue.main, closure: () -> Void) {
    queue.async(execute: closure)
}
