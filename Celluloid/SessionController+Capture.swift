//
//  SessionController+Capture.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 08/10/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

extension SessionController {
    func currentPhotoSettings() -> AVCapturePhotoSettings? {

        guard let output = output, let device = device else {
            return nil
        }

        let processedFormat = [AVVideoCodecKey : AVVideoCodecJPEG]
        let photoSettings: AVCapturePhotoSettings

        if lensStabilizationEnabled && output.isLensStabilizationDuringBracketedCaptureSupported {
            let bracketedImageSettings: AVCaptureBracketedStillImageSettings
            let bracketedCaptureSettings: AVCapturePhotoBracketSettings

            if device.exposureMode == .custom {
                bracketedImageSettings = AVCaptureManualExposureBracketedStillImageSettings.manualExposureSettings(withExposureDuration: AVCaptureExposureDurationCurrent, iso: AVCaptureISOCurrent)
            } else {
                bracketedImageSettings = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(withExposureTargetBias: AVCaptureExposureTargetBiasCurrent)
            }

            if rawCaptureEnabled && output.availableRawPhotoPixelFormatTypes.count > 0 {
                let rawSetting: OSType = output.availableRawPhotoPixelFormatTypes[0].uint32Value as OSType
                bracketedCaptureSettings = AVCapturePhotoBracketSettings(rawPixelFormatType: rawSetting, processedFormat: nil, bracketedSettings: [bracketedImageSettings])
            } else {
                bracketedCaptureSettings = AVCapturePhotoBracketSettings(rawPixelFormatType: 0, processedFormat: processedFormat, bracketedSettings: [bracketedImageSettings])
            }

            bracketedCaptureSettings.isLensStabilizationEnabled = true

            photoSettings = bracketedCaptureSettings
        } else {
            if rawCaptureEnabled && output.availableRawPhotoPixelFormatTypes.count > 0 {
                let rawSetting: OSType = output.availableRawPhotoPixelFormatTypes[0].uint32Value as OSType
                photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawSetting)
            } else {
                photoSettings = AVCapturePhotoSettings()
            }

            if device.exposureMode == .custom {
                photoSettings.flashMode = .off
            } else {
                photoSettings.flashMode = flashMode
            }
        }

        if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes[0]]
        }

        if device.exposureMode == .custom {
            photoSettings.isAutoStillImageStabilizationEnabled = false
        }

        if livePhotoEnabled {
            let urlString = NSTemporaryDirectory() + "live" + String(format: "%lld", photoSettings.uniqueID)
            let url = URL(fileURLWithPath: urlString)

            photoSettings.livePhotoMovieFileURL = url
        }

        photoSettings.isHighResolutionPhotoEnabled = false

        return photoSettings
    }

    public func capturePhoto(previewOrientation: AVCaptureVideoOrientation, willCapture: @escaping (Void) -> Void, completion: @escaping (PHAsset?) -> Void) {

        guard let output = output, let settings = currentPhotoSettings() else {
            completion(nil)
            return
        }

        sessionQueue.async {
            let connection = output.connection(withMediaType: AVMediaTypeVideo)
            connection?.videoOrientation = previewOrientation

            let captureDelegate = PhotoCaptureDelegate(settings: settings, willCapture: willCapture) { asset in
                self.sessionQueue.async {
                    self.photoCaptureDelegates[settings.uniqueID] = nil

                    DispatchQueue.main.async {
                        completion(asset)
                    }
                }
            }

            self.photoCaptureDelegates[settings.uniqueID] = captureDelegate
            output.capturePhoto(with: settings, delegate: captureDelegate)
        }
    }
}
