//
//  PhotoCaptureDelegate.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 06/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

public class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    let willCapture: (Void) -> Void
    let completion: (PHAsset?) -> Void
    public let settings: AVCapturePhotoSettings

    var JPEGData: Data?
    var RAWData: Data?
    var liveMovieURL: URL?

    init(settings: AVCapturePhotoSettings, willCapture: @escaping (Void) -> Void, completion: @escaping (PHAsset?) -> Void) {
        self.settings = settings
        self.willCapture = willCapture
        self.completion = completion
        super.init()
    }

    public func capture(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapture()
    }

    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {

        guard let photoBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer else {
            return
        }

        JPEGData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoBuffer, previewPhotoSampleBuffer: previewBuffer)
    }

    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard let rawBuffer = rawSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer else {
                return
        }

        RAWData = AVCapturePhotoOutput.dngPhotoDataRepresentation(forRawSampleBuffer: rawBuffer, previewPhotoSampleBuffer: previewBuffer)
    }

    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        liveMovieURL = outputFileURL
    }

    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {

        guard error == nil else {
            completion(nil)
            return
        }

        guard JPEGData != nil || RAWData != nil || liveMovieURL != nil else {
            completion(nil)
            return
        }

        PHPhotoLibrary.requestAuthorization { status in
            guard status ==  .authorized else {
                self.completion(nil)
                return
            }

            if let RAWData = self.RAWData {
                let urlString = NSTemporaryDirectory() + String(format: "%lld", resolvedSettings.uniqueID)
                let url = URL(fileURLWithPath: urlString)
                try? RAWData.write(to: url, options: .atomic)

                createAsset(JPEGData: self.JPEGData, RAWDataURL: url, livePhotoURL: self.liveMovieURL, completion: self.completion)
            }

            createAsset(JPEGData: self.JPEGData, RAWDataURL: nil, livePhotoURL: self.liveMovieURL, completion: self.completion)
        }
    }
}

fileprivate func createAsset(JPEGData: Data?, RAWDataURL: URL?, livePhotoURL: URL?, completion: @escaping (PHAsset?) -> Void) {

    var placeholder: PHObjectPlaceholder?

    PHPhotoLibrary.shared().performChanges({

        let request = PHAssetCreationRequest.forAsset()

        if let data = JPEGData {
            request.addResource(with: .photo, data: data, options: nil)

            if let url = RAWDataURL {
                request.addResource(url: url, moveFile: true)
            }
            if let url = livePhotoURL {
                request.addResource(url: url, moveFile: true)
            }
        } else if let url = RAWDataURL {
            request.addResource(url: url, moveFile: true)

            if let lurl = livePhotoURL {
                request.addResource(url: lurl, moveFile: true)
            }
        } else if let url = livePhotoURL {
            request.addResource(url: url, moveFile: true)
        }

        placeholder = request.placeholderForCreatedAsset

    }, completionHandler: { success, error in

        guard let placeholder = placeholder, success, let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject else {
            completion(nil)
            return
        }

        completion(asset)
    })
}

fileprivate extension PHAssetCreationRequest {
    func addResource(url: URL, moveFile: Bool) {
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = moveFile
        addResource(with: .fullSizePairedVideo, fileURL: url, options: options)
    }
}


