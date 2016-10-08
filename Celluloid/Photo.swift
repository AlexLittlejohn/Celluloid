//
//  Photo.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 27/08/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import Photos

struct Photo {
    let image: UIImage
    let asset: PHAsset
}

struct LivePhoto {
    let image: UIImage
    let asset: UIImage
    let livePhoto: UIImage
}
