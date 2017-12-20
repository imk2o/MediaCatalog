//
//  UIViewController+Alert.swift
//  MediaCatalog
//
//  Created by k2o on 2017/12/20.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlert(
        title: String? = nil,
        message: String? = nil,
        buttonTitle: String = "OK",
        completion handler: @escaping (() -> Void) = {}
        ) {
        self.presentAlert(
            title: title,
            message: message,
            defaultButtonTitle: buttonTitle,
            cancelButtonTitle: nil
        ) { (ok) in
            handler()
        }
    }
    
    func presentAlert(
        title: String? = nil,
        message: String? = nil,
        defaultButtonTitle: String = "OK",
        cancelButtonTitle: String? = "Cancel",
        completion handler: @escaping ((Bool) -> Void)
        ) {
        self.presentAlert(
            title: title,
            message: message,
            defaultButtonTitle: defaultButtonTitle,
            cancelButtonTitle: cancelButtonTitle,
            configureTextFields: []
        ) { (textValues) in
            handler(textValues != nil)
        }
    }
    
    func presentAlert(
        title: String? = nil,
        message: String? = nil,
        defaultButtonTitle: String = "OK",
        cancelButtonTitle: String? = "Cancel",
        configureTextFields: [((UITextField) -> Void)],
        completion handler: @escaping (([String]?) -> Void)
        ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for configureTextField in configureTextFields {
            alert.addTextField { (textField) in
                configureTextField(textField)
            }
        }
        
        let action: UIAlertAction = UIAlertAction(title: defaultButtonTitle, style: .default) { (_) in
            let textValues: [String]
            if let textFields = alert.textFields {
                textValues = textFields.map { $0.text ?? "" }
            } else {
                textValues = []
            }
            handler(textValues)
        }
        alert.addAction(action)
        alert.preferredAction = action
        
        if let cancelButtonTitle = cancelButtonTitle {
            alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel) { (_) in
                handler(nil)
            })
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}

