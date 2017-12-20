//
//  ImageCompositor.swift
//  MediaCatalog
//
//  Created by k2o on 2017/12/19.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation

struct ImageCompositor {
    enum Source {
        case url(URL)
    }
    let source: Source

    var slope: CGFloat
    var focus: CGFloat
    var range: CGFloat
    
    init(source: Source) {
        self.source = source
        self.slope = 3.0
        self.focus = 0.5
        self.range = 0.1
    }
    
    func colorImage() -> CIImage? {
        switch self.source {
        case .url(let url):
            return CIImage(contentsOf: url, options: [
                kCIImageApplyOrientationProperty: true
            ])
        }
    }
    
    func depthImage() -> CIImage? {
//        return CIFilter(name: "CILinearGradient", withInputParameters: [
//            "inputPoint0": CIVector(cgPoint: CGPoint(x: 0, y: 0)),
//            "inputPoint1": CIVector(cgPoint: CGPoint(x: 200, y: 0)),
//            "inputColor0": CIColor(red: 0, green: 0, blue: 0),
//            "inputColor1": CIColor(red: 1, green: 1, blue: 1)
//            ])?.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))
        switch self.source {
        case .url(let url):
            return CIImage(contentsOf: url, options: [
                kCIImageApplyOrientationProperty: true,
                kCIImageAuxiliaryDepth: true
            ])
        }
    }

    func disparityImage() -> CIImage? {
        return self.depthImage()?.applyingFilter("CIDepthToDisparity")
//        if let d = d {
//            let minMaxImage = d.applyingFilter("CIAreaMinMaxRed", parameters: [kCIInputExtentKey : CIVector(cgRect:d.extent)])
//
//            var pixel = [UInt8](repeating: 0, count: 4)
//            CIContext().render(minMaxImage, toBitmap: &pixel, rowBytes: 4,
//                           bounds: CGRect(x:0, y:0, width:1, height:1), format: kCIFormatRGBA8, colorSpace: nil)
//            let dMin = Float(pixel[0]) / 255.0
//            let dMax = Float(pixel[1]) / 255.0
//            print("dMin = \(dMin), dMax = \(dMax)")
//        }
//
//        return d
    }

    func composedImage() -> CIImage? {
        guard
            let colorImage = self.colorImage(),
            let alphaMaskImage = self.alphaMaskImage()
        else {
            return nil
        }
        
        let backgroundImage = CIImage(color: CIColor(
            red: 0,
            green: 0,
            blue: 1,
            alpha: 1
        )).cropped(to: colorImage.extent)

        return colorImage.applyingFilter(
            "CIBlendWithAlphaMask",
            parameters: [
                kCIInputBackgroundImageKey: backgroundImage,
                kCIInputMaskImageKey: alphaMaskImage
            ]
        )
    }
    
    func calibratedDisparityImage() -> CIImage? {
        guard let disparityImage = self.disparityImage() else {
            return nil
        }
        
        let s1 = self.slope		// 上りの斜度
        let s2 = -self.slope	// 下りの斜度
        let filterRange = (2 / self.slope) + self.range		// 傾斜部分を含む抽出範囲
        let b1 = -s1 * (self.focus - (filterRange / 2))	// バイアス1
        let b2 = -s2 * (self.focus + (filterRange / 2))	// バイアス2

        let mask0 = disparityImage.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: s1, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: b1, y: 0, z: 0, w: 0)
        ]).applyingFilter("CIColorClamp")
        let mask1 = disparityImage.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: s2, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: b2, y: 0, z: 0, w: 0)
        ]).applyingFilter("CIColorClamp")
        
        return mask0.applyingFilter("CIDarkenBlendMode", parameters: ["inputBackgroundImage" : mask1])
    }
    
    func alphaMaskImage(grayscaled: Bool = false) -> CIImage? {
        guard
            let colorImage = self.colorImage(),
            let calibratedDisparityImage = self.calibratedDisparityImage()
        else {
            return nil
        }

        let parameters: [String: Any] = grayscaled ? [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 1, y: 0, z: 0, w: 0)
        ] : [
            "inputAVector": CIVector(x: 1, y: 0, z: 0, w: 0)
        ]

        let alphaMaskImage = calibratedDisparityImage.applyingFilter(
            "CIColorMatrix",
            parameters: parameters
        ).applyingFilter("CIColorClamp")
        
        // colorImage()にサイズを合わせる
        let transform = CGAffineTransform(
            scaleX: colorImage.extent.width / alphaMaskImage.extent.width,
            y: colorImage.extent.height / alphaMaskImage.extent.height
        )
        
        return alphaMaskImage.transformed(by: transform)
    }
}
