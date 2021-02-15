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
    var lineImageView: UIImageView!
    var deleteButton: UIButton!
    weak var delegate: AlarmHeaderViewDelegate?
    
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
        lineImageView = UIImageView().then {
            $0.backgroundColor = UIColor.kDDDDDD
        }
        conView.addSubview(lineImageView)
        lineImageView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        deleteButton = UIButton(type: .custom).then {
            $0.backgroundColor = UIColor.kFF5E46
            $0.setTitle("删除", for: .normal)
            $0.layer.cornerRadius = 2
            $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            $0.setTitleColor(UIColor.white, for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            $0.addTarget(self, action: #selector(handleDeleteEvent(_:)), for: .touchUpInside)
        }
        conView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.equalTo(24)
            $0.right.equalTo(-26)
        }
    }
    
    @objc private func handleDeleteEvent(_ sender: Any) {
        delegate?.handleDeleteEvent(tag: tag)
    }
}

protocol AlarmHeaderViewDelegate: NSObjectProtocol {
    func handleDeleteEvent(tag: Int)
}
