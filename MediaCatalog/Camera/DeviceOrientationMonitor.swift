//
//  DeviceOrientationMonitor.swift
//  MediaCatalog
//
//  Created by k2o on 2017/11/15.
//  Copyright © 2017年 imk2o. All rights reserved.
//

import UIKit
import CoreMotion

/// 端末の傾きを監視する。
/// 回転ロックしている場合UIDevice#orientationがアテにならないため、加速度センサを参照して独自に取得する。
class DeviceOrientationMonitor {
    fileprivate(set) var orientation: UIDeviceOrientation = .unknown
    
    fileprivate let motionManager = CMMotionManager()
    
    init?(updateInterval: TimeInterval = 0.2) {
        guard self.motionManager.isAccelerometerAvailable else {
            return nil
        }
        
        self.motionManager.accelerometerUpdateInterval = updateInterval
    }

    deinit {
        self.stop()
    }
    
    func start() {
        guard !self.motionManager.isAccelerometerActive else {
            return
        }
        
        self.motionManager.startAccelerometerUpdates(to: OperationQueue()) { [unowned self] (data, error) in
            self.updateOrientation(by: data)
        }
    }
    
    func stop() {
        guard self.motionManager.isAccelerometerActive else {
            return
        }
        
        self.motionManager.stopAccelerometerUpdates()
    }
    
    private func updateOrientation(by data: CMAccelerometerData?) {
        if let data = data {
            //print("\(data.acceleration)")

            // FIXME: 簡素は判別方法のため、UIDevice#orientationとは微妙に結果が異なる...
            let absAccelerationX = abs(data.acceleration.x)
            let absAccelerationY = abs(data.acceleration.y)
            let absAccelerationZ = abs(data.acceleration.z)
            
            if absAccelerationZ > max(absAccelerationX, absAccelerationY) {
                // Face
                self.orientation = data.acceleration.z < 0 ? .faceUp : .faceDown
            } else if absAccelerationX > absAccelerationY {
                // Landscape
                self.orientation = data.acceleration.x > 0 ? .landscapeRight : .landscapeLeft
            } else if absAccelerationX < absAccelerationY {
                // Portrait
                self.orientation = data.acceleration.y < 0 ? .portrait : .portraitUpsideDown
            } else {
                self.orientation = .unknown
            }
        } else {
            self.orientation = .unknown
        }
    }
}

extension UIDeviceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .faceDown:
            return "faceDown"
        case .faceUp:
            return "faceUp"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .unknown:
            return "unknown"
        }
    }
}
