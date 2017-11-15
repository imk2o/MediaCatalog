//
//  CGSize+Extension.swift
//  MediaCatalog
//
//  Created by k2o on 2017/09/27.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit

extension CGSize {
    var aspectRatio: CGFloat {
        return self.width / self.height
    }
    
    func sizeForAspectFit(targetSize: CGSize) -> CGSize {
        return self.aspectRatio > targetSize.aspectRatio ?
            CGSize(width: targetSize.width, height: targetSize.width / self.width * self.height) :
            CGSize(width: targetSize.height / self.height * self.width, height: targetSize.height)
    }
    
    func sizeForAspectFill(targetSize: CGSize) -> CGSize {
        return self.aspectRatio > targetSize.aspectRatio ?
            CGSize(width: targetSize.height / self.height * self.width, height: targetSize.height) :
            CGSize(width: targetSize.width, height: targetSize.width / self.width * self.height)
    }
    
    func scaleForAspectFit(targetSize: CGSize) -> CGFloat {
        return self.aspectRatio > targetSize.aspectRatio ?
            targetSize.width / self.width :
            targetSize.height / self.height
    }
    
    func scaleForAspectFill(targetSize: CGSize) -> CGFloat {
        return self.aspectRatio > targetSize.aspectRatio ?
            targetSize.height / self.height :
            targetSize.width / self.width
    }
    
    func screenScaled() -> CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
    
    static func * (size: CGSize, factor: CGFloat) -> CGSize {
        return CGSize(
            width: size.width * factor,
            height: size.height * factor
        )
    }
}

