//
//  MovieSessionController.swift
//  Celluloid
//
//  Created by Alex Littlejohn on 2016/04/16.
//  Copyright © 2016 Alex Littlejohn. All rights reserved.
//

import UIKit
import AVFoundation

class MovieSessionController {
    let output: AVCaptureMovieFileOutput
    
    var recordingDelegate: MovieSessionDelegate!
    
    init(session: AVCaptureSession) throws {
        output = AVCaptureMovieFileOutput()
        
        guard session.canAddOutput(output) else {
            throw CelluloidError.MovieOutputCreationFailed
        }
        
        session.addOutput(output)
    }
    
    func startRecording(completion: MovieCaptureCompletion?) {
        
        let documentDirectoryURL =  try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        
        let date = NSDate().description
        let url = documentDirectoryURL.URLByAppendingPathComponent("movie-\(date)")

        if output.recording {
            output.stopRecording()
        }
        
        recordingDelegate = MovieSessionDelegate()
        recordingDelegate.completion = completion
        output.startRecordingToOutputFileURL(url, recordingDelegate: recordingDelegate)
    }
    
    func stopRecording() {
        output.stopRecording()
        recordingDelegate = nil
    }
}

class MovieSessionDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var completion: MovieCaptureCompletion?

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        async {
            self.completion?(outputFileURL)
            self.completion = nil
            
            captureOutput?.stopRecording()
        }
    }
}
