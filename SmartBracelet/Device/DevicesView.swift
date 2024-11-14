//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DevicesView.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DevicesView: UIView {
    weak var currentModel: BLEModel?
    var index = Int() // 下标
    var bConnected = false
    let cardImgView = UIImageView()
    let btImgView = UIImageView()
    let cardNameLabel = UILabel()
    let macLabel = UILabel() // 蓝牙地址
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupUI() {
        self.addSubview(cardImgView)
        cardImgView.snp.makeConstraints { make in
            make.width.equalTo(88)
            make.height.equalTo(88)
            make.centerX.equalToSuperview()
            make.top.equalTo(20)
        }
        
    
        cardNameLabel.textColor = UIColor.text_primary
        cardNameLabel.font = UIFont.body1()
        cardNameLabel.textAlignment = .left
        cardNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [cardNameLabel])
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        // 设置 stackView 的约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardImgView.bottomAnchor, constant: 10),
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
        
        macLabel.textColor = UIColor.text_primary
        macLabel.font = UIFont.body1()
        macLabel.textAlignment = .left
        macLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(macLabel)
        
        macLabel.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(10)
            make.centerX.equalTo(stackView)
        }
        
        addSubview(btImgView)
        btImgView.image = UIImage(named: "content_blueteeth_unlink")
        btImgView.snp.makeConstraints { make in
            make.width.equalTo(10)
            make.height.equalTo(15)
            make.centerY.equalTo(stackView)
            make.leading.equalTo(stackView.snp.trailing).offset(5)
        }
    }

    public func refreshData() {
        DeviceManager.shared.initializeDevices()
        
        let count = DeviceManager.shared.devices.count
        if count == 0 {
            self.isHidden = true
        } else {
            self.isHidden = false
            currentModel = nil
            if count > 0 {
                for item in DeviceManager.shared.devices {
                    
                    if item.mac == lastestDeviceMac {
                        currentModel = item
                        break
                    }
                }
            }
            if currentModel == nil {
                self.isHidden = true
            } else {
                self.isHidden = false
                cardImgView.image = UIImage(named: AppDelegate.IsDeviceNotRound() ? "icon_ewatch" : "icon_ewatch_2")
                cardNameLabel.text = (currentModel?.name ?? "") + " - \(bleSelf.bleModel.screenWidth)*\(bleSelf.bleModel.screenHeight)"
                if currentModel!.mac == lastestDeviceMac && bleSelf.isConnected {
                    bConnected = true
                    btImgView.image = UIImage(named: "content_blueteeth_link")
                } else {
                    btImgView.image = UIImage(named: "content_blueteeth_unlink")
                }
                macLabel.text = currentModel?.mac ?? ""
            }
        }
    }
}


