//
//  VisionFaceFeatureViewController.swift
//  MediaCatalog
//
//  Created by k2o on 2017/11/08.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionFaceFeatureViewController: UIViewController {

    @IBOutlet weak var previewView: CoreImageView!
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.

    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewView.context = EAGLContext(api: .openGLES2)!
        
        // カメラのセットアップ
        self.setCameraFace(.back)
        self.setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.captureSession.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate var captureImage: CIImage?
    fileprivate var capturingImageSize = CGSize.zero
    
    lazy var faceRectanglesRequest: VNDetectFaceRectanglesRequest = {
        return VNDetectFaceRectanglesRequest(completionHandler: self.handleFaceRectangles)
    }()
    
    func handleFaceRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation]
            else { fatalError("unexpected result type from VNDetectRectanglesRequest") }
        guard let detectedRectangle = observations.first else {
            print("no face rectangle")
            return
        }
        let imageSize = self.capturingImageSize
        
        // Rectify the detected image and reduce it to inverted grayscale for applying model.
        let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
        let topRight = detectedRectangle.topRight.scaled(to: imageSize)
        let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
        let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let markerImage = renderer.image { (context) in
            UIColor.yellow.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 3
            path.move(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: bottomLeft)
            path.addLine(to: bottomRight)
            path.close()
            path.stroke()
        }
        
        if
            let captureImage = self.captureImage,
            let cgMarkerImage = markerImage.cgImage
        {
            let ciMarkerImage = CIImage(cgImage: cgMarkerImage)
            
            let compositeFilter = CIFilter(
                name: "CISourceOverCompositing",
                withInputParameters: [
                    kCIInputImageKey: ciMarkerImage,
                    kCIInputBackgroundImageKey: captureImage
                ]
            )
            
            self.previewView.image = compositeFilter?.outputImage
        }
        
//        let cosrectedImage = inputImage
//            .cropped(to: boundingBox)
//            .applyingFilter("CIPerspectiveCorrection", parameters: [
//                "inputTopLeft": CIVector(cgPoint: topLeft),
//                "inputTopRight": CIVector(cgPoint: topRight),
//                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
//                "inputBottomRight": CIVector(cgPoint: bottomRight)
//                ])
//            .applyingFilter("CIColorControls", parameters: [
//                kCIInputSaturationKey: 0,
//                kCIInputContrastKey: 32
//                ])
//            .applyingFilter("CIColorInvert")
        
//        // Show the pre-processed image
//        DispatchQueue.main.async {
//            self.correctedImageView.image = UIImage(ciImage: correctedImage)
//        }
//
//        // Run the Core ML MNIST classifier -- results in handleClassification method
//        let handler = VNImageRequestHandler(ciImage: correctedImage)
//        do {
//            try handler.perform([classificationRequest])
//        } catch {
//            print(error)
//        }
    }
}

fileprivate extension VisionFaceFeatureViewController {
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
extension VisionFaceFeatureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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

        self.captureImage = croppedImage
        self.capturingImageSize = croppedImage.extent.size
        let handler = VNImageRequestHandler(ciImage: croppedImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.faceRectanglesRequest])
            } catch {
                print(error)
            }
        }
    }
}

private extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
private extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}

