//
//  WUUIImageExt.swift
//  Coredy
//
//  Created by WuJunjie on 2017/11/28.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    /// 给图片上色
    ///
    func add(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.translateBy(x: 0, y: self.size.height)
            context.scaleBy(x: 1, y: -1)
            context.setBlendMode(.normal)
            
            let rect = CGRect.init(origin: .zero, size: self.size)
            context.clip(to: rect, mask: self.cgImage!)
            color.setFill()
            context.fill(rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        return self
    }
    
    /// 返回圆形图片
    func circleImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1)
        if let context = UIGraphicsGetCurrentContext() {
            let rect = CGRect.init(origin: .zero, size: size)
            context.addEllipse(in: rect)
            context.clip()
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        return self
    }
    
    func add(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect.init(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func add(_ rect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        if let _ = UIGraphicsGetCurrentContext() {
            let x = rect.width/2 - self.size.width/2
            let y = rect.height/2 - self.size.height/2
            self.draw(at: CGPoint.init(x: x, y: y))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        return self
    }
    
    func cornerImage(with radius: CGFloat) -> UIImage? {
        //1.建立上下文
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            let rect = CGRect.init(origin: .zero, size: size)
            //2.创建椭圆path,宽、高一致返回的就是圆形路径
            let path = UIBezierPath.init(roundedRect: rect, cornerRadius: radius)
            context.addPath(path.cgPath)
            context.clip()
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        return self
    }
    
    func cornerImage1(with radius: CGFloat) -> UIImage? {
        //1.建立上下文
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            let rect = CGRect.init(origin: .zero, size: size)
            //2.创建椭圆path,宽、高一致返回的就是圆形路径
            let path = UIBezierPath.init(roundedRect: CGRect.init(x: 16, y: 6, width: rect.width - 32, height: rect.height - 12), cornerRadius: radius)
            context.addPath(path.cgPath)
            context.clip()
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        return self
    }
}
