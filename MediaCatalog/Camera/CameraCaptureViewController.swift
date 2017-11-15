//
//  CameraCaptureViewController.swift
//  MediaCatalog
//
//  Created by k2o on 2017/09/26.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraCaptureViewController: UIViewController {

    @IBOutlet weak var previewView: CoreImageView!
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var depthImageView: UIImageView!
    
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.

    private var deviceOrientationMonitor: DeviceOrientationMonitor?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewView.context = EAGLContext(api: .openGLES2)!
        
        // カメラのセットアップ
        self.setCameraFace(.back)
        self.setupCamera()
        
        self.deviceOrientationMonitor = DeviceOrientationMonitor()
        
//        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(self.deviceOrientationDidChangeNotification(_:)),
//            name: Notification.Name.UIDeviceOrientationDidChange,
//            object: nil
//        )
    }

//    @objc func deviceOrientationDidChangeNotification(_ notification: Notification) {
//        print(UIDevice.current.orientation.rawValue)
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.captureSession.startRunning()
        self.deviceOrientationMonitor?.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.captureSession.stopRunning()
        self.deviceOrientationMonitor?.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func shotButtonDidTap(_ sender: Any) {
        self.shot()
    }
}

fileprivate extension CameraCaptureViewController {
//    func proposeFilter() {
//        let actionSheet = UIAlertController(title: "Filter", message: nil, preferredStyle: .actionSheet)
//
//        let filters: [SimpleFilter] = [
//            .sepia,
//            .mosaic(40),
//            .blur(20),
//            .twist(100, CGFloat.pi * 50.0)
//        ]
//        for filter in filters {
//            actionSheet.addAction(UIAlertAction(title: filter.name, style: .default) { (action) in
//                self.filter = filter
//            })
//        }
//
//        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
//        self.present(actionSheet, animated: true, completion: nil)
//    }
    
    func setCameraFace(_ position: AVCaptureDevice.Position) -> Bool {
        // position に対するカメラを探す
        guard
            let videoDevice = (
                AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) ??
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
        else {
            return false
        }
        
        // キャプチャセッションの入力を入れ替え
        if self.captureSession.isRunning {
            self.captureSession.beginConfiguration()
        }
        defer {
            if self.captureSession.isRunning {
                self.captureSession.commitConfiguration()
            }
        }
        
        let installedVideoInputDevice = self.captureSession.installedCaptureDeviceInputs().first
        
        // 既にデバイスが設定されている場合は入れ替え
        if let videoInputDevice = installedVideoInputDevice {
            self.captureSession.removeInput(videoInputDevice)
        }
        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput)
            
            return true
        } else {
            if let videoInputDevice = installedVideoInputDevice {
                self.captureSession.addInput(videoInputDevice)
            }
            
            return false
        }
    }
    
    func setupCamera() {
        self.captureSession.sessionPreset = .photo
//        if self.captureSession.canSetSessionPreset(.medium) {
//            self.captureSession.sessionPreset = .medium
//        }
        
        // ビデオキャプチャ
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "", attributes: []))
        self.captureSession.addOutput(videoOutput)
        
        // 撮影用出力を追加
        if self.captureSession.canAddOutput(self.photoOutput) {
            self.captureSession.addOutput(self.photoOutput)
            
            self.photoOutput.isHighResolutionCaptureEnabled = true
            // Live Photos
            self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
            // Depth
            self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
            
        }
    }
    
    func updateCapturedImageView(with asset: PHAsset?) {
        guard let asset = asset else {
            self.capturedImageView.image = nil
            return
        }
        
        let size = self.capturedImageView.bounds.size.screenScaled()
        asset.loadImage(targetSize: size, contentMode: .aspectFill) { [weak self] (result) in
            switch result {
            case .success(let image, let isThunbmail):
                self?.capturedImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateDepthImageView(with photo: AVCapturePhoto) {
        guard let depthDataMap = photo.depthData?.depthDataMap else {
            self.depthImageView.image = nil
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: depthDataMap)
        guard let cgImage = ciImage.cgImage else {
            return
        }
        
        self.depthImageView.image = UIImage(cgImage: cgImage)
    }
}

fileprivate extension AVCaptureDevice {
    static func captureDevices(for position: AVCaptureDevice.Position) -> [AVCaptureDevice] {
        return self.devices(for: .video).flatMap({ (captureDevice) -> AVCaptureDevice? in
            return captureDevice.position == position ? captureDevice : nil
        })
    }
}

fileprivate extension AVCaptureSession {
    func installedCaptureDeviceInputs() -> [AVCaptureDeviceInput] {
        return self.inputs.flatMap({ (input) -> AVCaptureDeviceInput? in
            return input as? AVCaptureDeviceInput
        })
    }
}

// ビデオキャプチャ
extension CameraCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let captureImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // カメラに応じた回転補正をかける(Portraitに合わせている)
        let transform = CGAffineTransform(rotationAngle: -CGFloat(M_PI_2))        // Back camera
        //transform = CGAffineTransformScale(transform, 1, -1)                // Front camera
        let transformedImage = captureImage.transformed(by: transform)
        
//        // Core Imageでフィルタを適用
//        let ciFilter = self.filter.ciFilter(
//            center: CGPoint(x: transformedImage.extent.midX, y: transformedImage.extent.midY),
//            intensity: CGFloat(self.slider.value)
//        )
//        ciFilter.setValue(transformedImage, forKey: kCIInputImageKey)
//
//        // 元の画像サイズでcrop
//        let croppedImage = ciFilter.outputImage?.cropping(to: transformedImage.extent)
        let croppedImage = transformedImage.cropped(to: transformedImage.extent)

        // UIImageを出力してUIImageViewに表示することもできるが、OpenGLを使うほうが軽量で高速
        self.previewView.image = croppedImage
    }
}

private extension CameraCaptureViewController {
    func shot() {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
//        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection.videoOrientation
        
        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
//                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
            }
            
            // Capture a JPEG photo with flash set to auto and high resolution photo enabled.
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            photoSettings.isHighResolutionPhotoEnabled = true
            if photoSettings.__availablePreviewPhotoPixelFormatTypes.count > 0 {		// FIXME: Workaround for Xcode9
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]	// FIXME: Workaround for Xcode9
            }
            if self.photoOutput.isLivePhotoCaptureSupported { // Live Photo capture is not supported in movie mode.
                let livePhotoMovieFileName = NSUUID().uuidString
                let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
            }
            if self.photoOutput.isDepthDataDeliverySupported {
                photoSettings.isDepthDataDeliveryEnabled = true
            }

            // 端末の回転ロック設定に依らず、現在の傾きをカメラに設定
            if
                let orientation = self.deviceOrientationMonitor?.orientation,
                let photoOutputConnection = self.photoOutput.connection(with: .video),
                let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: orientation)
            {
                photoOutputConnection.videoOrientation = videoOrientation
            }

            PhotoCaptureSession(with: photoSettings)
                .willCapturePhoto {
                    // 画面効果
                    DispatchQueue.main.async { [unowned self] in
                        self.previewView.alpha = 0
                        UIView.animate(withDuration: 0.25) { [unowned self] in
                            self.previewView.alpha = 1
                        }
                    }
                }.capturingLivePhoto { (capturing) in
//                    /*
//                     Because Live Photo captures can overlap, we need to keep track of the
//                     number of in progress Live Photo captures to ensure that the
//                     Live Photo label stays visible during these captures.
//                     */
//                    self.sessionQueue.async { [unowned self] in
//                        if capturing {
//                            self.inProgressLivePhotoCapturesCount += 1
//                        }
//                        else {
//                            self.inProgressLivePhotoCapturesCount -= 1
//                        }
//                        
//                        let inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount
//                        DispatchQueue.main.async { [unowned self] in
//                            if inProgressLivePhotoCapturesCount > 0 {
//                                self.capturingLivePhotoLabel.isHidden = false
//                            }
//                            else if inProgressLivePhotoCapturesCount == 0 {
//                                self.capturingLivePhotoLabel.isHidden = true
//                            }
//                            else {
//                                print("Error: In progress live photo capture count is less than 0");
//                            }
//                        }
//                    }
                }
                .didCapturePhoto { (photo, livePhotoMovieURL) -> Bool in
                    DispatchQueue.main.async {
                        self.updateDepthImageView(with: photo)
                    }
                    return false
                }
                .didFinishSaveToPhotoLibrary { [unowned self] (asset) in
                    self.updateCapturedImageView(with: asset)
                }
                .error { (error) in
                    print(error)
                }
                .start(in: self.photoOutput)
        }
    }
}

private extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeRight
        case .landscapeRight:
            self = .landscapeLeft
        default:
            return nil
        }
    }
}
