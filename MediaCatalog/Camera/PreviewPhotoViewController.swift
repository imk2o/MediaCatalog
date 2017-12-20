//
//  PreviewPhotoViewController.swift
//  MediaCatalog
//
//  Created by k2o on 2017/12/19.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit

class PreviewPhotoViewController: UIViewController {
    var photoURL: URL!

    @IBOutlet weak var previewImageView: CoreImageView!
    @IBOutlet weak var viewModeControl: UISegmentedControl!
    
    fileprivate var imageCompositor: ImageCompositor!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewImageView.context = EAGLContext(api: .openGLES3)!
        self.imageCompositor = ImageCompositor(source: .url(self.photoURL))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func viewModeDidChange(_ sender: Any) {
        self.updateView()
    }
    
    @IBAction func rangeSliderDidChange(_ sender: UISlider) {
        self.setFocus(CGFloat(sender.value))
    }
}

private extension PreviewPhotoViewController {
    func setFocus(_ focus: CGFloat) {
        self.imageCompositor.focus = focus
        self.updateView()
    }
    
    func updateView() {
        self.previewImageView.image = {
            switch self.viewModeControl.selectedSegmentIndex {
            case 0:
                return self.imageCompositor.colorImage()
            case 1:
                return self.imageCompositor.depthImage()
            case 2:
                return self.imageCompositor.alphaMaskImage(grayscaled: true)
            case 3:
                return self.imageCompositor.composedImage()
            default:
                return nil
            }
        }()
    }
}
