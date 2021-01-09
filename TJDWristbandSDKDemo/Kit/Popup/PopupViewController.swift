//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  PopupViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/9/6.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class PopupViewController: UIViewController {
    var contentView: UIView!
    var contentLabel: UILabel!
    var titleLabel: UILabel!
    var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView = UIView().then {
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 4
        }
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.left.equalTo(27)
            $0.right.equalTo(-27)
            $0.centerY.equalToSuperview()
            $0.height.greaterThanOrEqualTo(200).priority(.low)
        }
        titleLabel = UILabel().then {
            $0.textColor = .k333333
            $0.font = UIFont.systemFont(ofSize: 16)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(20)
        }
        
        contentLabel = UILabel().then {
            $0.textColor = .k333333
            $0.font = UIFont.systemFont(ofSize: 13)
            $0.numberOfLines = 0
        }
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.right.equalTo(-15)
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
            $0.bottom.equalTo(-30)
        }
        button = UIButton(type: .custom).then {
            $0.setImage(UIImage(named: "content_icon_turnoff"), for: .normal)
            $0.addTarget(self, action: #selector(dismissSelf(_:)), for: .touchUpInside)
        }
        contentView.addSubview(button)
        button.snp.makeConstraints {
            $0.width.height.equalTo(44)
            $0.top.equalTo(5)
            $0.right.equalTo(-5)
        }
    }
    
    @objc private func dismissSelf(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }

}
