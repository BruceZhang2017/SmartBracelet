//
//  NSObject+MBProgressHUD.swift
//  WUProduct
//
//  Created by WuJunjie on 2017/11/7.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import Foundation
//import MBProgressHUD

//MARK: show text with MBProgressHUD (提示框)
extension NSObject {
    
    func showHud(_ text: String? = nil, duration: Double? = 1.5) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        MBProgressHUD.hide(for: window, animated: false)
        
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        if text == nil {
            hud.mode = .indeterminate
            hud.bezelView.color = UIColor.clear
        }
        else {
            hud.mode = .text
            hud.label.text = text
        }
        hud.label.text = text
        hud.label.numberOfLines = 0
        hud.label.lineBreakMode = .byCharWrapping
        hud.label.textColor = UIColor.gray
        hud.removeFromSuperViewOnHide = true
        
//        hud.backgroundView.style = MBProgressHUDBackgroundStyle.solidColor
//        hud.backgroundView.color = UIColor.Common.black.withAlphaComponent(0.35)
        if let temp = duration {
            hud.hide(animated: true, afterDelay: temp)
        }
        else {
            hud.hide(animated: true, afterDelay: 1.5)
        }
    }
    
    func showHudForever(_ text: String? = nil) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        MBProgressHUD.hide(for: window, animated: false)
        
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        if text == nil {
            hud.bezelView.color = UIColor.clear
        }
        else {
            hud.label.text = text
        }
        hud.mode = .indeterminate
        hud.label.text = text
        hud.label.numberOfLines = 0
        hud.label.lineBreakMode = .byCharWrapping
        hud.label.textColor = UIColor.gray
        hud.removeFromSuperViewOnHide = true
        
        hud.backgroundView.style = MBProgressHUDBackgroundStyle.solidColor
        hud.backgroundView.color = UIColor.black.withAlphaComponent(0.35)
    }
    
    func hideHud() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        MBProgressHUD.hide(for: window, animated: false)
    }
    
    func showSaveState(_ isSuccess: Bool) {
        if isSuccess {
            self.showHud(NSLocalizedString("设置成功", comment: ""))
        }
        else {
            self.showHud(NSLocalizedString("设置失败", comment: ""))
        }
    }
    
    @discardableResult
    func showDeterminateHud(_ text: String? = nil) -> MBProgressHUD? {
        guard let window = UIApplication.shared.keyWindow else {
            return nil
        }
        MBProgressHUD.hide(for: window, animated: false)
        
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .determinate
        hud.label.text = text
        hud.label.numberOfLines = 0
        hud.label.lineBreakMode = .byCharWrapping
        hud.label.textColor = UIColor.gray
        hud.removeFromSuperViewOnHide = true
        
        //        hud.backgroundView.style = MBProgressHUDBackgroundStyle.solidColor
        //        hud.backgroundView.color = UIColor.Common.black.withAlphaComponent(0.35)
        return hud
    }
}
