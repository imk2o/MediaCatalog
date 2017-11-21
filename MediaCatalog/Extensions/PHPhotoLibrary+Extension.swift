//
//  PHPhotoLibrary+Extension.swift
//  MediaCatalog
//
//  Created by k2o on 2017/09/27.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import Foundation
import Photos

extension PHPhotoLibrary {
    enum Result {
        case success(PHAsset?)
        case failure(Error)
    }
    
    func save(
        photoData: Data,
        livePhotoMovieURL: URL?,
        completion handler: ((Result) -> Void)? = nil
    ) {
        func lastCreatedAsset(from: Date, to: Date) -> PHAsset? {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(
                format: "creationDate BETWEEN {%@, %@}",
                from as NSDate,
                to as NSDate
            )
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
            //print(fetchResult.count)
            return fetchResult.firstObject
        }
        
        let beginAt = Date()
        self.performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: photoData, options: nil)
            
            if let livePhotoMovieURL = livePhotoMovieURL {
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)
            }
        }, completionHandler: { (success, error) in
            if let error = error {
                handler?(.failure(error))
            } else {
                let asset = lastCreatedAsset(from: beginAt, to: Date())
                handler?(.success(asset))
            }
        })
    }
}
