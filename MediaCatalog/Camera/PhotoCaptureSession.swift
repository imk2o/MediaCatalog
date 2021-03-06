//
//  PhotoCaptureSession.swift
//  MediaCatalog
//
//  Created by k2o on 2017/09/26.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import AVFoundation

/// カメラ撮影と、関連コールバックのハンドリングを行う。
class PhotoCaptureSession: NSObject, AVCapturePhotoCaptureDelegate {
    typealias WillCapturePhotoHandler = () -> Void
    typealias CapturingLivePhotoHandler = (Bool) -> Void
    typealias DidCapturePhotoHandler = (AVCapturePhoto, URL?) -> Void
    typealias ErrorHandler = (Error) -> Void
    
    private(set) var photoSettings: AVCapturePhotoSettings
    
    private var willCapturePhotoHandler: WillCapturePhotoHandler?
    private var capturingLivePhotoHandler: CapturingLivePhotoHandler?
    private var didCapturePhotoHandler: DidCapturePhotoHandler?
    private var errorHandler: ErrorHandler?
    
    private var capturePhoto: AVCapturePhoto? = nil
    
    private var livePhotoCompanionMovieURL: URL? = nil
    
    static private var inProgressSessions = Set<PhotoCaptureSession>()
    
    var identifier: Int64 {
        return self.photoSettings.uniqueID
    }
    
    init(with photoSettings: AVCapturePhotoSettings) {
        self.photoSettings = photoSettings
    }
    
    func start(in photoOutput: AVCapturePhotoOutput) {
        photoOutput.capturePhoto(with: self.photoSettings, delegate: self)
        // 呼び出し側でセッションを握っていないとdelegateにコールバックされないため、参照を握っておく
        type(of: self).inProgressSessions.insert(self)
    }
    
    @discardableResult
    func willCapturePhoto(_ handler: @escaping WillCapturePhotoHandler) -> Self {
        self.willCapturePhotoHandler = handler
        
        return self
    }
    
    @discardableResult
    func capturingLivePhoto(_ handler: @escaping CapturingLivePhotoHandler) -> Self {
        self.capturingLivePhotoHandler = handler
        
        return self
    }
    
    @discardableResult
    func didCapturePhoto(_ handler: @escaping DidCapturePhotoHandler) -> Self {
        self.didCapturePhotoHandler = handler
        
        return self
    }

    @discardableResult
    func error(_ handler: @escaping ErrorHandler) -> Self {
        self.errorHandler = handler
        
        return self
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.willCapturePhotoHandler?()
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
            self.capturingLivePhotoHandler?(true)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            self.errorHandler?(error)
            return
        }
        
        self.capturePhoto = photo
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.capturingLivePhotoHandler?(false)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            self.errorHandler?(error)
            return
        }
        
        self.livePhotoCompanionMovieURL = outputFileURL
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        func didFinish() {
            if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
                if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
                    do {
                        try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
                    }
                    catch {
                        print("Could not remove file at url: \(livePhotoCompanionMoviePath)")
                    }
                }
            }
        }
        
        if let error = error {
            self.errorHandler?(error)
            didFinish()
            return
        }
        
        guard let capturePhoto = self.capturePhoto else {
            didFinish()
            return
        }
        
        self.didCapturePhotoHandler?(capturePhoto, self.livePhotoCompanionMovieURL)
        
        // 握っていた参照を解放
        type(of: self).inProgressSessions.remove(self)
    }
}
