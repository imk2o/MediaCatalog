//
//  CIImage+Extension.swift
//  MediaCatalog
//
//  Created by k2o on 2017/11/16.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import Foundation
import CoreImage

extension CIImage {
    func rotated90() -> CIImage {
        let transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2))
        
        return self.transformed(by: transform)
    }

    func rotated90CCW() -> CIImage {
        let transform = CGAffineTransform(rotationAngle: -(CGFloat.pi / 2))
        
        return self.transformed(by: transform)
    }
    
    func minMaxFromDisparity() -> (CGFloat, CGFloat) {
        let minMaxImage = self.applyingFilter("CIAreaMinMaxRed", parameters: [
            kCIInputExtentKey: CIVector(cgRect: self.extent)
            ])
        
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(
            minMaxImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: kCIFormatRGBA8,
            colorSpace: nil
        )

        return (
            CGFloat(pixel[0]) / 255,
            CGFloat(pixel[1]) / 255
        )
    }
}
