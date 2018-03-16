//
//  ViewController.swift
//  QRCode
//
//  Created by zhouqi on 2018/3/16.
//  Copyright © 2018年 zhouqi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func turnQRCode(_ sender: UIButton) {
        authorizeCameraWith { [weak self] (reslut) in
            if reslut {
                self?.navigationController?.pushViewController(QRCodeViewController(), animated: true)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                    self?.jumpToSystemPrivacySetting()
                })
            }
        }
    }
    
    //MARK: ---相机权限
    func authorizeCameraWith(comletion:@escaping(Bool)-> Void) {
        let granted = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch granted {
        case AVAuthorizationStatus.authorized:
            comletion(true)
            break
        case AVAuthorizationStatus.denied:
            comletion(false)
            break
        case AVAuthorizationStatus.restricted:
            comletion(false)
            break
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted:Bool) in
                comletion(granted)
            })
        }
    }
    
    //MARK:跳转到APP系统设置权限界面
    func jumpToSystemPrivacySetting() {
        let appSetting = URL(string:UIApplicationOpenSettingsURLString)
        if appSetting != nil {
            if #available(iOS 10, *) {
                UIApplication.shared.open(appSetting!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(appSetting!)
            }
        }
    }
}

