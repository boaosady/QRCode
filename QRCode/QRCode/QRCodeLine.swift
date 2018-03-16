//
//  QRCodeView.swift
//  zhouqi
//
//  Created by zhouqi on 2017/12/29.
//  Copyright © 2017年 zhouqi. All rights reserved.
//

import UIKit

class QRCodeLine: UIImageView {

    var isAnimationing = false
    var animationRect: CGRect = CGRect.zero
    
    func startAnimatingWithRect(animationRect: CGRect, parentView: UIView, image: UIImage?) {
        self.image = image
        self.animationRect = animationRect
        parentView.addSubview(self)
        self.isHidden = false
        isAnimationing = true
        if image != nil {
            stepAnimation()
        }
    }
    
    @objc func stepAnimation() {
        if (!isAnimationing) { return }
        var frame:CGRect = animationRect
        let hImg = self.image!.size.height * animationRect.size.width / self.image!.size.width
        frame.origin.y -= hImg
        frame.size.height = hImg
        self.frame = frame
        UIView.animate(withDuration: 1.4, animations: { () -> Void in
            var frame = self.animationRect
            let hImg = self.image!.size.height * self.animationRect.size.width / self.image!.size.width
            frame.origin.y += (frame.size.height -  hImg)
            frame.size.height = hImg
            self.frame = frame
        }, completion:{ (value: Bool) -> Void in
            self.perform(#selector(QRCodeLine.stepAnimation), with: nil, afterDelay: 0.3)
        })
    }
    
    func stopStepAnimating() {
        self.isHidden = true
        isAnimationing = false
    }
    
    static public func instance()->QRCodeLine {
        return QRCodeLine()
    }
    
    deinit {
        stopStepAnimating()
    }

}

