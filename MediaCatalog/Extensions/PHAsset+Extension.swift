//
//  PHAsset+Extension.swift
//  MediaCatalog
//
//  Created by k2o on 2017/09/27.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import Foundation
import Photos

extension PHAsset {
    enum LoadImageError: Swift.Error {
        case systemError(Error)
        case cancelled
        case unknown
    }
    
    enum LoadImageResult {
        case success(UIImage, isThumbnail: Bool)
        case failure(Error)
    }
    func loadImage(
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions? = nil,
        completion handler: ((LoadImageResult) -> Void)? = nil
    ) {
        PHImageManager.default().requestImage(
            for: self,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { (image, info) in
            if let image = image {
                let isThumbnail = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                DispatchQueue.main.async {
                    handler?(.success(image, isThumbnail: isThumbnail))
                }
            } else {
                let error = { () -> LoadImageError in
                    if let error = info?[PHImageErrorKey] as? Error {
                        return .systemError(error)
                    } else if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                        return .cancelled
                    } else {
                        return .unknown
                    }
                }()

                DispatchQueue.main.async {
                    handler?(.failure(error))
                }
            }
        }
    }
}
