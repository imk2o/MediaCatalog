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
    
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    
    private var deviceOrientationMonitor: DeviceOrientationMonitor?

    fileprivate var ciPhotoImage: CIImage?
    fileprivate var ciBackgroundImage: CIImage?
    fileprivate var ciDepthDisparityImage: CIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewView.context = EAGLContext(api: .openGLES3)!
        
        // カメラのセットアップ
        self.setCameraFace(.back)
        self.setupCamera()
        
        self.deviceOrientationMonitor = DeviceOrientationMonitor()
    }

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "previewPhoto"?:
            let previewPhotoViewController = segue.destination as! PreviewPhotoViewController
            
            previewPhotoViewController.photoURL = sender as! URL
        default:
            break
        }
    }
    
    @IBAction func shotButtonDidTap(_ sender: Any) {
        self.shot()
    }
    
    func previewPhoto(with url: URL) {
        self.performSegue(withIdentifier: "previewPhoto", sender: url)
    }
    
    func alert(title: String, description: String) {
        self.presentAlert(title: title, message: description)
    }
}

fileprivate extension CameraCaptureViewController {
    @discardableResult
    func setCameraFace(_ position: AVCaptureDevice.Position) -> Bool {
        func findVideoDevice(_ devices: [AVCaptureDevice.DeviceType]) -> AVCaptureDevice? {
            for device in devices {
                if let captureDevice = AVCaptureDevice.default(device, for: .video, position: position) {
                    return captureDevice
                }
            }
            
            return nil
        }
        
        // position に対するカメラを探す
        var devices: [AVCaptureDevice.DeviceType] = []
        if #available(iOS 11.1, *) {
            devices += [.builtInTrueDepthCamera]
        }
        devices += [.builtInDualCamera, .builtInWideAngleCamera]
        
        guard
            let videoDevice = findVideoDevice(devices),
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
        
        // ビデオキャプチャ
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "", attributes: []))
        self.captureSession.addOutput(videoOutput)
        
        // 撮影用出力を追加
        if self.captureSession.canAddOutput(self.photoOutput) {
            self.captureSession.addOutput(self.photoOutput)
            
            self.photoOutput.isHighResolutionCaptureEnabled = true
            // Live Photos
//            self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
            // Depth
            self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
            
        }
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
        let transform = CGAffineTransform(rotationAngle: -(CGFloat.pi / 2))        // Back camera
        //transform = CGAffineTransformScale(transform, 1, -1)                // Front camera
        let transformedImage = captureImage.transformed(by: transform)
        
        let croppedImage = transformedImage.cropped(to: transformedImage.extent)

        // UIImageを出力してUIImageViewに表示することもできるが、OpenGLを使うほうが軽量で高速
        self.previewView.image = croppedImage
    }
}

private extension CameraCaptureViewController {
    func shot() {
        // NOTE: AVCaptureVideoPreviewLayerを使っている場合、以下の方法で端末の傾きを取得できる
        //let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection.videoOrientation
        
        sessionQueue.async {
            let photoSettings = AVCapturePhotoSettings()
            
            photoSettings.flashMode = .auto
            photoSettings.isHighResolutionPhotoEnabled = true
            if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
            }
            if self.photoOutput.isLivePhotoCaptureEnabled { // Live Photo capture is not supported in movie mode.
                let livePhotoMovieFileName = NSUUID().uuidString
                let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
            }
            if self.photoOutput.isDepthDataDeliveryEnabled {
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
                }
                .didCapturePhoto { (photo, livePhotoMovieURL) in
                    self.handleCapturedPhoto(photo, livePhotoMovieURL: livePhotoMovieURL)
                }
                .error { (error) in
                    print(error)
                }
                .start(in: self.photoOutput)
        }
    }

    /// 撮影した写真を表示、保存
    func handleCapturedPhoto(_ photo: AVCapturePhoto, livePhotoMovieURL: URL?) {
        func saveToTemporaryAndPreview() {
            let storeURL = FileManager.default
                .temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            
            guard let photoData = photo.fileDataRepresentation() else {
                return self.alert(
                    title: "Error",
                    description: "Failed to get photo data"
                )
            }

            do {
                let _ = try photoData.write(to: storeURL)
            } catch {
                return self.alert(
                    title: "Error",
                    description: error.localizedDescription
                )
            }
            
            self.previewPhoto(with: storeURL)
        }
        
        func saveToPhotoLibrary() {
            guard let photoData = photo.fileDataRepresentation() else {
                return self.alert(
                    title: "Error",
                    description: "Failed to get photo data"
                )
            }
            
            PHPhotoLibrary.shared().save(
                photoData: photoData,
                livePhotoMovieURL: livePhotoMovieURL
            ) { (result) in
                switch result {
                case .success(let asset):
                    break
                case .failure(let error):
                    self.alert(
                        title: "Error",
                        description: error.localizedDescription
                    )
                }
            }
        }
        
        self.presentActionSheet(items: [
            ("写真をプレビュー", "preview"),
            ("写真ライブラリに保存", "save")
        ]) { (result) in
            switch result {
            case "preview"?:
                saveToTemporaryAndPreview()
            case "save"?:
                saveToPhotoLibrary()
            default:
                break
            }
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

