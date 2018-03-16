//
//  QRCodeWrapper.swift
//  zhouqi
//
//  Created by zhouqi on 2017/12/29.
//  Copyright © 2017年 zhouqi. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO

public struct QRCodeResult {
    
    public var strScanned:String? = ""
    public var imgScanned:UIImage?
    public var strBarCodeType:String? = ""
    public var arrayCorner:[AnyObject]?
    
    public init(str:String?,img:UIImage?,barCodeType:String?,corner:[AnyObject]?) {
        self.strScanned = str
        self.imgScanned = img
        self.strBarCodeType = barCodeType
        self.arrayCorner = corner
    }
}

open class QRCodeWrapper: NSObject,AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let device = AVCaptureDevice.default(for: AVMediaType.video)
    var input:AVCaptureDeviceInput?
    var output:AVCaptureMetadataOutput
    
    let session = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer?
    var stillImageOutput:AVCaptureStillImageOutput?
    var arrayResult:[QRCodeResult] = []
    var successBlock:([QRCodeResult]) -> Void
    var brightnessBlock:(Float) -> Void
    var isNeedCaptureImage:Bool
    var isNeedScanResult:Bool = true
    
    init( videoPreView:UIView,objType:[AVMetadataObject.ObjectType] = [AVMetadataObject.ObjectType.qr],isCaptureImg:Bool,cropRect:CGRect=CGRect.zero, brightness:@escaping ( (Float) -> Void), success:@escaping ( ([QRCodeResult]) -> Void) )
    {
        do {
            input = try AVCaptureDeviceInput(device: device!)
        } catch let error as NSError {
            print("AVCaptureDeviceInput(): \(error)")
        }
        brightnessBlock = brightness
        successBlock = success
        output = AVCaptureMetadataOutput()

        isNeedCaptureImage = isCaptureImg
        stillImageOutput = AVCaptureStillImageOutput()
        super.init()

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if device == nil { return }
        if session.canAddInput(input!) {
            session.addInput(input!)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        if session.canAddOutput(stillImageOutput!) {
            session.addOutput(stillImageOutput!)
        }
        
        let outputSettings:Dictionary = [AVVideoCodecJPEG:AVVideoCodecKey]
        stillImageOutput?.outputSettings = outputSettings
        session.sessionPreset = AVCaptureSession.Preset.high
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = objType
        if !cropRect.equalTo(CGRect.zero) {
            output.rectOfInterest = cropRect
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        var frame:CGRect = videoPreView.frame
        frame.origin = CGPoint.zero
        previewLayer?.frame = frame
        
        videoPreView.layer.insertSublayer(previewLayer!, at: 0)
        
        if ( device!.isFocusPointOfInterestSupported && device!.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) ) {
            do {
                try input?.device.lockForConfiguration()
                input?.device.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                input?.device.unlockForConfiguration()
            }
            catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
            }
        }
        
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureOutput(output, didOutputMetadataObjects: metadataObjects, from: connection)
    }
    
    func start() {
        if !session.isRunning {
            isNeedScanResult = true
            session.startRunning()
        }
    }
    func stop() {
        if session.isRunning {
            isNeedScanResult = false
            session.stopRunning()
        }
    }
    
    open func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if !isNeedScanResult {
            return
        }
        isNeedScanResult = false
        arrayResult.removeAll()
        for current:Any in metadataObjects {
            if (current as AnyObject).isKind(of: AVMetadataMachineReadableCodeObject.self) {
                let code = current as! AVMetadataMachineReadableCodeObject
                let codeType = code.type
                let codeContent = code.stringValue
                arrayResult.append(QRCodeResult(str: codeContent, img: UIImage(), barCodeType: codeType.rawValue, corner: code.corners as [AnyObject]?))
            }
        }
        
        if arrayResult.count > 0 {
            if isNeedCaptureImage {
                captureImage()
            }  else {
                stop()
                successBlock(arrayResult)
            } 
        } else {
            isNeedScanResult = true
        }
    }
    
    open func captureImage() {
        let stillImageConnection:AVCaptureConnection? = connectionWithMediaType(mediaType: AVMediaType.video, connections: (stillImageOutput?.connections)! as [AnyObject])
        stillImageOutput?.captureStillImageAsynchronously(from: stillImageConnection!, completionHandler: { (imageDataSampleBuffer, error) -> Void in
            self.stop()
            if imageDataSampleBuffer != nil {
                let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)!
                let scanImg:UIImage? = UIImage(data: imageData)
                for idx in 0...self.arrayResult.count-1 {
                    self.arrayResult[idx].imgScanned = scanImg
                }
            }
            self.successBlock(self.arrayResult)
        })
    }
    
    open func connectionWithMediaType(mediaType:AVMediaType,connections:[AnyObject]) -> AVCaptureConnection? {
        for connection:AnyObject in connections {
            let connectionTmp:AVCaptureConnection = connection as! AVCaptureConnection
            
            for port:Any in connectionTmp.inputPorts {
                if (port as AnyObject).isKind(of: AVCaptureInput.Port.self) {
                    let portTmp:AVCaptureInput.Port = port as! AVCaptureInput.Port
                    if portTmp.mediaType == mediaType {
                        return connectionTmp
                    }
                }
            }
        }
        return nil
    }
    
    open func isGetFlash()->Bool {
        if (device != nil &&  device!.hasFlash && device!.hasTorch) {
            return true
        }
        return false
    }

    open class func setTorch(torch:Bool)
    {
        let device = AVCaptureDevice.default(for: .video)
        if device?.hasTorch == true {
            do {
                try device?.lockForConfiguration()
                
                device?.torchMode = torch ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
                
                device?.unlockForConfiguration()
            } catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
            }
        }
    }
    
    static open func recognizeQRImage(image:UIImage) ->[QRCodeResult] {
        var returnResult:[QRCodeResult]=[]
        let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
        let img = CIImage(cgImage: (image.cgImage)!)
        let features:[CIFeature]? = detector.features(in: img, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        if ( features != nil && (features?.count)! > 0) {
            let feature = features![0]
            if feature.isKind(of: CIQRCodeFeature.self)  {
                let featureTmp:CIQRCodeFeature = feature as! CIQRCodeFeature
                let scanResult = featureTmp.messageString
                let result = QRCodeResult(str: scanResult, img: image, barCodeType: AVMetadataObject.ObjectType.qr.rawValue,corner: nil)
                
                returnResult.append(result)
            }
        }
        return returnResult
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let metadataDict: CFDictionary = CMCopyDictionaryOfAttachments(nil, sampleBuffer, kCMAttachmentMode_ShouldPropagate)!
        let metadata = metadataDict as? [AnyHashable: Any]
        var brightnessValue: Float = 0

        if let exifMetadata = (metadata![(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any] {
            if let brightness = exifMetadata["BrightnessValue"] as? Float {
                brightnessValue = brightness
            }
        }
        print("\(brightnessValue)")
        brightnessBlock(brightnessValue)
    }
}
