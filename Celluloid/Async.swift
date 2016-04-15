//
//  Async.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/14.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

/// dispatch_async wrapper utility
func async(queue: dispatch_queue_t = dispatch_get_main_queue(), closure: () -> Void) {
    dispatch_async(queue, closure)
}