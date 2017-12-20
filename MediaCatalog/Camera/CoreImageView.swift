//
//  CoreImageView.swift
//  MediaCatalog
//
//  Created by k2o on 2017/09/26.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

/// CIImageを表示するImage View。
class CoreImageView: GLKView {
    var image: CIImage? {
        didSet {
            DispatchQueue.main.async {
                self.display()
            }
        }
    }
    
    override var context: EAGLContext {
        didSet {
            self.ciContext = CIContext(eaglContext: self.context)
        }
    }
    fileprivate var ciContext: CIContext?
    
    override func draw(_ rect: CGRect) {
        guard
            let image = self.image,
            let ciContext = self.ciContext
        else {
            return
        }
        
        let scale = self.window?.screen.scale ?? 1.0
        let screenScaledBounds = self.bounds.applying(CGAffineTransform(scaleX: scale, y: scale))
        let aspectFitRect = AVMakeRect(aspectRatio: image.extent.size, insideRect: screenScaledBounds)
        ciContext.draw(image, in: aspectFitRect, from: image.extent)
    }
}
