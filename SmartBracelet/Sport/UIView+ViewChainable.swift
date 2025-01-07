//
//  UIView+ViewChainable.swift
//  WUProduct
//
//  Created by WuJunjie on 2017/11/16.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import Foundation
import SnapKit
import UIKit

protocol ViewChainable {
    
}

extension ViewChainable where Self: UIView {
    @discardableResult
    func config(_ config: (Self)-> Void) -> Self {
        config(self)
        return self
    }
}

// MARK: Jerry
extension UIView: ViewChainable {
    @discardableResult
    func adhere(toSuperView: UIView) -> Self {
        toSuperView.addSubview(self)
        return self
    }
    
    @discardableResult
    func layout(snapKitMaker: (ConstraintMaker) -> Void) -> Self {
        self.snp.makeConstraints { (make) in
            snapKitMaker(make)
        }
        return self
    }
    
    @discardableResult
    func update(snapKitMaker: (ConstraintMaker) -> Void) -> Self {
        self.snp.remakeConstraints { (make) in
            snapKitMaker(make)
        }
        return self
    }
    
    func getViewController() -> UIViewController? {
        var tempSuper = self.superview
        while tempSuper != nil {
            if let tempNext = tempSuper!.next, tempNext is UIViewController {
                return tempNext as? UIViewController
            }
            tempSuper = tempSuper?.superview
        }
        return nil
    }
}
