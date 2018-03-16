//
//  UIColorExtension.swift
//  zhouqi
//
//  Created by zhouqi on 2017/12/7.
//  Copyright © 2017年 zhouqi. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    public class func hexStringToColor(hexString: String) -> UIColor{
        return hexStringToColor(hexString: hexString, alpha: 1.0)
    }
    
    public class func hexStringToColor(hexString: String, alpha: CGFloat) -> UIColor{
        let scanner = Scanner(string: hexString)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        return UIColor.init(red: CGFloat(r) / 0xff, green: CGFloat(g) / 0xff, blue: CGFloat(b) / 0xff, alpha: alpha)
        
    }
}
