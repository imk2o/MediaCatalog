//
//  UIViewController+ActionSheet.swift
//  MediaCatalog
//
//  Created by k2o on 2017/12/19.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentActionSheet<T>(
        title: String? = nil,
        message: String? = nil,
        items: [(String, T)],
        cancelButtonTitle: String? = "Cancel",
        completion handler: @escaping ((T?) -> Void)
    ) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for item in items {
            actionSheet.addAction(UIAlertAction(title: item.0, style: .default) { (_) in
                handler(item.1)
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel) { (_) in
            handler(nil)
        })
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func presentActionSheet<T>(
        title: String? = nil,
        message: String? = nil,
        items: [(String, T, UIAlertActionStyle)],
        cancelButtonTitle: String? = "Cancel",
        completion handler: @escaping ((T?) -> Void)
    ) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for item in items {
            actionSheet.addAction(UIAlertAction(title: item.0, style: item.2) { (_) in
                handler(item.1)
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel) { (_) in
            handler(nil)
        })
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func presentActionSheet(
        title: String? = nil,
        message: String? = nil,
        destructiveButtonTitle: String?,
        cancelButtonTitle: String? = "Cancel",
        completion handler: @escaping ((Bool) -> Void)
    ) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: destructiveButtonTitle, style: .destructive) { (_) in
            handler(true)
        })
        
        actionSheet.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel) { (_) in
            handler(false)
        })
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}

