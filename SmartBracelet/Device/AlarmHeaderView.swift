//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AlarmHeaderView.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class AlarmHeaderView: UITableViewHeaderFooterView {
    var conView: UIView!
    var titleLabel: UILabel!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initializeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        conView = UIView().then {
            $0.backgroundColor = UIColor.white
        }
        addSubview(conView)
        conView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(15)
            $0.bottom.equalToSuperview()
        }
        
        titleLabel = UILabel().then {
            $0.textColor = UIColor.k343434
            $0.font = UIFont.systemFont(ofSize: 15)
        }
        conView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(20)
            $0.centerY.equalToSuperview()
        }
    }
}
