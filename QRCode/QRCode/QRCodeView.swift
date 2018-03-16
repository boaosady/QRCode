//
//  QRCodeView.swift
//  zhouqi
//
//  Created by zhouqi on 2017/12/29.
//  Copyright © 2017年 zhouqi. All rights reserved.
//

import UIKit
import AVFoundation

open class QRCodeView: UIView {
    var scanRetangleRect:CGRect = CGRect.zero
    var scanLineAnimation:QRCodeLine?
    var scanLineStill:UIImageView?
    var labelReadying:UILabel?
    var isAnimationing:Bool = false
    var torchBtn = UIButton()
    var torchLabel = UILabel()

    override init(frame:CGRect) {
        scanLineAnimation = QRCodeLine.instance()
        var frameTmp = frame
        frameTmp.origin = CGPoint.zero
        super.init(frame: frameTmp)
        backgroundColor = UIColor.clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
    deinit {
        if (scanLineAnimation != nil) {
            scanLineAnimation!.stopStepAnimating()
        }
    }
    
    func startScanAnimation()  {
        if isAnimationing { return }
        isAnimationing = true
        let cropRect:CGRect = getScanRectForAnimation()
        scanLineAnimation!.startAnimatingWithRect(animationRect: cropRect, parentView: self, image:UIImage(named: "scanLine") )
        
        self.torchBtn.frame = CGRect(x: (UIScreen.main.bounds.size.width-40)/2, y: cropRect.maxY-90, width: 40, height: 40)
        self.torchLabel.frame = CGRect(x: cropRect.origin.x, y: torchBtn.frame.maxY+10, width: cropRect.size.width, height: 20)
        self.torchBtn.setImage(UIImage(named: "light_off"), for: .normal)
        self.torchBtn.setImage(UIImage(named: "light_on"), for: .selected)
        torchLabel.text = "轻点开启"
        torchLabel.textAlignment = .center
        torchBtn.addTarget(self, action: #selector(openTorch(sender:)), for: .touchUpInside)
        torchLabel.textColor = UIColor.white
        torchLabel.font = UIFont.systemFont(ofSize: 14)
        torchBtn.isHidden = true
        torchLabel.isHidden = true
        self.addSubview(torchLabel)
        self.addSubview(torchBtn)
    }
    
    @objc func openTorch(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        torchLabel.textColor = !sender.isSelected ? UIColor.white : UIColor.hexStringToColor(hexString: "cb925f")
        torchLabel.text = sender.isSelected ? "轻点关闭" : "轻点开启"
        QRCodeWrapper.setTorch(torch: sender.isSelected)
    }
    
    func stopScanAnimation() {
        isAnimationing = false
        scanLineAnimation?.stopStepAnimating()
    }
    
    override open func draw(_ rect: CGRect) {
        drawScanRect()
    }
    
    func drawScanRect() {
        let XRetangleLeft: CGFloat = 60
        let sizeRetangle = CGSize(width: self.frame.size.width - XRetangleLeft*2.0, height: self.frame.size.width - XRetangleLeft*2.0)
        let YMinRetangle = self.frame.size.height / 2.0 - sizeRetangle.height/2.0 - 44
        let YMaxRetangle = YMinRetangle + sizeRetangle.height
        let XRetangleRight = self.frame.size.width - XRetangleLeft
        
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor)
        var rect = CGRect(x: 0, y: 0, width: self.frame.size.width, height: YMinRetangle)
        context.fill(rect)
        
        rect = CGRect(x: 0, y: YMinRetangle, width: XRetangleLeft, height: sizeRetangle.height)
        context.fill(rect)
        rect = CGRect(x: XRetangleRight, y: YMinRetangle, width: XRetangleLeft,height: sizeRetangle.height)
        context.fill(rect)
        rect = CGRect(x: 0, y: YMaxRetangle, width: self.frame.size.width,height: self.frame.size.height - YMaxRetangle)
        context.fill(rect)
        context.strokePath()
        
        scanRetangleRect = CGRect(x: XRetangleLeft, y:  YMinRetangle, width: sizeRetangle.width, height: sizeRetangle.height)
        
        let wAngle: CGFloat = 24.0
        let hAngle: CGFloat = 24.0
        
        let linewidthAngle: CGFloat = 4
        
        var diffAngle = linewidthAngle/3
        diffAngle = linewidthAngle / 2
        diffAngle = linewidthAngle/2
        diffAngle = 0
        diffAngle = -4/2
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.setLineWidth(linewidthAngle)
        
        let leftX = XRetangleLeft - diffAngle
        let topY = YMinRetangle - diffAngle
        let rightX = XRetangleRight + diffAngle
        let bottomY = YMaxRetangle + diffAngle
        
        context.move(to: CGPoint(x: leftX-linewidthAngle/2, y: topY))
        context.addLine(to: CGPoint(x: leftX + wAngle, y: topY))
        context.move(to: CGPoint(x: leftX, y: topY-linewidthAngle/2))
        context.addLine(to: CGPoint(x: leftX, y: topY+hAngle))
        context.move(to: CGPoint(x: leftX-linewidthAngle/2, y: bottomY))
        context.addLine(to: CGPoint(x: leftX + wAngle, y: bottomY))
        context.move(to: CGPoint(x: leftX, y: bottomY+linewidthAngle/2))
        context.addLine(to: CGPoint(x: leftX, y: bottomY - hAngle))
        context.move(to: CGPoint(x: rightX+linewidthAngle/2, y: topY))
        context.addLine(to: CGPoint(x: rightX - wAngle, y: topY))
        context.move(to: CGPoint(x: rightX, y: topY-linewidthAngle/2))
        context.addLine(to: CGPoint(x: rightX, y: topY + hAngle))
        context.move(to: CGPoint(x: rightX+linewidthAngle/2, y: bottomY))
        context.addLine(to: CGPoint(x: rightX - wAngle, y: bottomY))
        context.move(to: CGPoint(x: rightX, y: bottomY+linewidthAngle/2))
        context.addLine(to: CGPoint(x: rightX, y: bottomY - hAngle))
        context.strokePath()
    }
    
    func getScanRectForAnimation() -> CGRect  {
        let XRetangleLeft: CGFloat = 60
        let sizeRetangle = CGSize(width: self.frame.size.width - XRetangleLeft*2, height: self.frame.size.width - XRetangleLeft*2)
        let YMinRetangle = self.frame.size.height / 2.0 - sizeRetangle.height/2.0 - 44
        //扫码区域坐标
        let cropRect =  CGRect(x: XRetangleLeft, y: YMinRetangle, width: sizeRetangle.width, height: sizeRetangle.height)
        return cropRect
    }
    
    //根据矩形区域，获取识别区域
    static func getScanRectWithPreView(preView:UIView) -> CGRect {
        let XRetangleLeft: CGFloat = 60
        let sizeRetangle = CGSize(width: preView.frame.size.width - XRetangleLeft*2, height: preView.frame.size.width - XRetangleLeft*2)
        
        let YMinRetangle = preView.frame.size.height / 2.0 - sizeRetangle.height/2.0 - 44
        let cropRect =  CGRect(x: XRetangleLeft, y: YMinRetangle, width: sizeRetangle.width, height: sizeRetangle.height)
        
        var rectOfInterest:CGRect
        
        let size = preView.bounds.size
        let p1 = size.height/size.width
        
        let p2:CGFloat = 1920.0/1080.0
        if p1 < p2 {
            let fixHeight = size.width * 1920.0 / 1080.0
            let fixPadding = (fixHeight - size.height)/2
            rectOfInterest = CGRect(x: (cropRect.origin.y + fixPadding)/fixHeight,
                                    y: cropRect.origin.x/size.width,
                                    width: cropRect.size.height/fixHeight,
                                    height: cropRect.size.width/size.width)
        } else {
            let fixWidth = size.height * 1080.0 / 1920.0
            let fixPadding = (fixWidth - size.width)/2
            rectOfInterest = CGRect(x: cropRect.origin.y/size.height,
                                    y: (cropRect.origin.x + fixPadding)/fixWidth,
                                    width: cropRect.size.height/size.height,
                                    height: cropRect.size.width/fixWidth)
        }
        return rectOfInterest
    }
    
    func getRetangeSize()->CGSize {
        let XRetangleLeft: CGFloat = 60
        var sizeRetangle = CGSize(width: self.frame.size.width - XRetangleLeft*2, height: self.frame.size.width - XRetangleLeft*2)
        let w = sizeRetangle.width
        var h = w
        let hInt:Int = Int(h)
        h = CGFloat(hInt)
        sizeRetangle = CGSize(width: w, height:  h)
        return sizeRetangle
    }
    
    func showTorchView(brightnessValue: Float) {
        if self.torchBtn.isSelected {
            return
        }
        if AVCaptureDevice.default(for: .video)?.hasTorch == true {
            self.torchLabel.isHidden = brightnessValue > 0
            self.torchBtn.isHidden = brightnessValue > 0
        }
    }
}
