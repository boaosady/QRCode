//
//  QRCodeViewController.swift
//  caizhu
//
//  Created by zhouqi on 2017/12/29.
//  Copyright © 2017年 zhouqi. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

public protocol QRCodeReslutDelegate {
    func scanFinished(scanResult: QRCodeResult, error: String?)
}

class QRCodeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    open var scanResultDelegate: QRCodeReslutDelegate?
    open var scanObj: QRCodeWrapper?
    open var qRScanView: QRCodeView?
    public var arrayCodeType:[AVMetadataObject.ObjectType]?
    public  var isNeedCodeImage = true
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = "扫一扫"
        self.view.backgroundColor = UIColor.black
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
    }
    
    open func setNeedCodeImage(needCodeImg:Bool) {
        isNeedCodeImage = needCodeImg;
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawScanView()
        perform(#selector(QRCodeViewController.startScan), with: nil, afterDelay: 0.3)
    }
    
    @objc open func startScan() {
        UserDefaults.standard.set(true, forKey: "HasOpendQRCode")
        if (scanObj == nil) {
            let cropRect = QRCodeView.getScanRectWithPreView(preView: self.view)
            if arrayCodeType == nil {
                arrayCodeType = [AVMetadataObject.ObjectType.qr,AVMetadataObject.ObjectType.ean13,AVMetadataObject.ObjectType.code128]
            }
            
            scanObj = QRCodeWrapper.init(videoPreView: view, objType: arrayCodeType!, isCaptureImg: isNeedCodeImage, cropRect: cropRect, brightness: { [weak self] (value) in
                self?.qRScanView?.showTorchView(brightnessValue: value)
            }, success: { [weak self] (arrayResult) -> Void in
                if let strongSelf = self {
                    strongSelf.qRScanView?.stopScanAnimation()
                    strongSelf.handleCodeResult(arrayResult: arrayResult)
                }
            })
        }
        
        qRScanView?.startScanAnimation()
        
        scanObj?.start()
    }
    
    open func stopScan() {
        qRScanView?.stopScanAnimation()
        scanObj?.stop()
    }
    
    open func drawScanView() {
        if qRScanView == nil {
            qRScanView = QRCodeView(frame: self.view.frame)
            self.view.addSubview(qRScanView!)
        }
    }
    
    open func handleCodeResult(arrayResult:[QRCodeResult]) {
        if let delegate = scanResultDelegate  {
            let result:QRCodeResult = arrayResult[0]
            delegate.scanFinished(scanResult: result, error: nil)
        } else {
            for result:QRCodeResult in arrayResult {
                print(result.strScanned ?? "")
            }
            let result:QRCodeResult = arrayResult[0]
            if let code = result.strScanned {
                showMsg(title: "扫描结果", message: code)
            }
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        stopScan()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        var image:UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage
        if (image == nil ) {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        if(image != nil) {
            let arrayResult = QRCodeWrapper.recognizeQRImage(image: image!)
            if arrayResult.count > 0 {
                handleCodeResult(arrayResult: arrayResult)
                return
            }
        }
        
    }
    
    func showMsg(title:String?,message:String?) {
        
        let alertController = UIAlertController(title: nil, message:message, preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (alertAction) in
            self.startScan()
        }
        
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
}





