//
//  CutDownView.swift
//  LifeFit
//
//  Created by tjd on 2018/11/29.
//  Copyright © 2018年 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK

class CutDownView: UIView {
    var completeBlock: WUOkHandler!
    var count = 0
    var nameLabel = UILabel()
    
    class func showCutDownView(with count: Int, completeBlock: @escaping WUOkHandler) {
        let view = CutDownView.init(with: count, completeBlock: completeBlock)
        if let window = UIApplication.shared.keyWindow {
            view.adhere(toSuperView: window).layout { (make) in
                make.edges.equalToSuperview()
                }
                .config { (make) in
                    make.backgroundColor = UIColor.brand
            }
        }
    }
    
    init(with count: Int, completeBlock: @escaping WUOkHandler) {
        super.init(frame: .zero)
        self.completeBlock = completeBlock
        self.count = count
        
        nameLabel.adhere(toSuperView: self).layout { (make) in
            make.center.equalToSuperview()
            }
            .config { (make) in
                make.text = self.count.description
                make.textColor = UIColor.white
                make.font = UIFont.boldSystemFont(ofSize: 500)
        }
        self.showAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAnimation() {
        if self.count == 0 {
            nameLabel.text = "GO"
            nameLabel.font = UIFont.boldSystemFont(ofSize: 300)
        }
        else {
            nameLabel.text = self.count.description
            nameLabel.font = UIFont.boldSystemFont(ofSize: 500)
        }
        nameLabel.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
        nameLabel.alpha = 1
        UIView.animate(withDuration: 1, animations: {
            self.nameLabel.transform = CGAffineTransform.identity
            self.nameLabel.alpha = 0.2
        }) { (finished) in
            self.count = self.count - 1
            if self.count == -1 {
                self.removeFromSuperview()
                self.completeBlock()
            }
            else {
                self.showAnimation()
            }
        }
    }
    
    deinit {
        wuPrint(#function)
    }
}
