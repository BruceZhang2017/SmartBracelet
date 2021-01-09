//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  PopupBViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/11/14.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import Foundation

class PopupBViewController: UIViewController {
    var contentView: UIView!
    var contentLabel: UILabel!
    var iconImageView: UIImageView!
    var callback: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        contentView = UIView().then {
            $0.backgroundColor = UIColor.k373F4F
            $0.layer.cornerRadius = 10
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleEvent))
            $0.addGestureRecognizer(tap)
        }
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.width.equalTo(220)
            $0.height.equalTo(130)
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview()
        }
        iconImageView = UIImageView().then {
            $0.contentMode = .scaleAspectFit
        }
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(20)
            $0.width.height.equalTo(30)
        }
        
        contentLabel = UILabel().then {
            $0.textColor = .white
            $0.font = UIFont.systemFont(ofSize: 13)
            $0.numberOfLines = 0
            $0.contentMode = .center
            
        }
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.right.equalTo(-15)
            $0.top.equalTo(iconImageView.snp.bottom).offset(20)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: view)
            if !contentView.frame.contains(point) {
                dismiss(animated: false, completion: nil)
                break
            }
        }
    }
    
    @objc private func handleEvent() {
        callback?()
        dismiss(animated: false, completion: nil)
    }
}
