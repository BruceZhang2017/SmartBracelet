//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DevicesView.swift
//  SmartBracelet
//
//  Created by bruce on 2020/8/28.
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
    private let statusBadgeLabel = DeviceEdgeInsetLabel()
    private let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupUI() {
        backgroundColor = .white
        
        self.addSubview(cardImgView)
        cardImgView.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(56)
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(18)
        }
        cardImgView.contentMode = .scaleAspectFit
        
        cardNameLabel.textColor = UIColor.text_primary
        cardNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        cardNameLabel.textAlignment = .left
        cardNameLabel.numberOfLines = 1
        cardNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.textColor = UIColor.text_secondary
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [cardNameLabel, subtitleLabel, macLabel])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: cardImgView.trailingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -76),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -60)
        ])
        
        macLabel.textColor = UIColor.text_third
        macLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        macLabel.textAlignment = .left
        macLabel.numberOfLines = 1
        macLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(btImgView)
        btImgView.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(cardImgView)
        }
        
        statusBadgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        statusBadgeLabel.contentInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        statusBadgeLabel.layer.cornerRadius = 11
        statusBadgeLabel.layer.masksToBounds = true
        addSubview(statusBadgeLabel)
        statusBadgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(20)
        }
    }

    private func applyEmptyState() {
        isHidden = false
        bConnected = false
        cardImgView.image = UIImage(named: "icon_add_device") ?? UIImage(named: "icon_ewatch")
        cardNameLabel.text = "device_add".localized()
        subtitleLabel.text = "添加设备后即可进入同步、表盘和设置管理。"
        macLabel.text = "尚未连接设备"
        btImgView.image = UIImage(named: "content_blueteeth_unlink")
        statusBadgeLabel.isHidden = false
        statusBadgeLabel.text = "未添加"
        statusBadgeLabel.textColor = UIColor(hex: 0x7E8A9A)
        statusBadgeLabel.backgroundColor = UIColor(hex: 0xEEF3F9)
    }
    
    private func applyContent(name: String, mac: String, connected: Bool) {
        isHidden = false
        bConnected = connected
        cardNameLabel.text = name
        subtitleLabel.text = connected ? "设备连接正常，可继续同步和管理。" : "设备当前未连接，可重新连接后继续管理。"
        macLabel.text = mac
        btImgView.image = UIImage(named: connected ? "content_blueteeth_link" : "content_blueteeth_unlink")
        statusBadgeLabel.isHidden = connected
        statusBadgeLabel.text = "未连接"
        statusBadgeLabel.textColor = UIColor(hex: 0x7E8A9A)
        statusBadgeLabel.backgroundColor = UIColor(hex: 0xEEF3F9)
    }

    public func refreshData(value: Int? = 0) {
        DeviceManager.shared.initializeDevices()
        
        var count = DeviceManager.shared.devices.count
        count += cacheDevices.count
        if count == 0 {
            applyEmptyState()
        } else {
            self.isHidden = false

            if (cacheDevices.count) > 0 {
                XLogger.shared.log("Item already exists at index \(index)")
                self.isHidden = false
                cardImgView.image = UIImage(named: "icon_ewatch")
                if let device = BluetoothWatchDevice.loadFromSandbox(mac: lastestDeviceMac) {
                    if device.max == lastestDeviceMac && (device.max == XGZTBlueToothManager.shared.device?.max && XGZTBlueToothManager.shared.device != nil) {
                        if XGZTBlueToothManager.shared.centralManager?.state == .poweredOff {
                            bConnected = false
                        } else {
                            if value == 100 || XGZTBlueToothManager.shared.isReconnectingNow {
                                bConnected = false
                            } else {
                                if XGZTBlueToothManager.shared.checkConnectedDevicesIsEmpty() {
                                    bConnected = false
                                } else {
                                    bConnected = true
                                }
                            }
                            
                        }
                    } else {
                        bConnected = false
                    }
                    applyContent(name: device.deviceName ?? "", mac: device.max ?? "", connected: bConnected)
                    return
                }
                let deviceName = XGZTBlueToothManager.shared.getDeviceName(mac: lastestDeviceMac)
                if deviceName.count > 0 {
                    if lastestDeviceMac == XGZTBlueToothManager.shared.device?.max && XGZTBlueToothManager.shared.device != nil {
                        if XGZTBlueToothManager.shared.centralManager?.state == .poweredOff {
                            bConnected = false
                        } else {
                            if value == 100 || XGZTBlueToothManager.shared.isReconnectingNow {
                                bConnected = false
                            } else {
                                if XGZTBlueToothManager.shared.checkConnectedDevicesIsEmpty() {
                                    bConnected = false
                                } else {
                                    bConnected = true
                                }
                            }
                            
                        }
                    } else {
                        bConnected = false
                    }
                    applyContent(name: deviceName, mac: lastestDeviceMac, connected: bConnected)
                    return
                }
            }
            
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
                applyEmptyState()
            } else {
                self.isHidden = false
                cardImgView.image = UIImage(named: AppDelegate.IsDeviceNotRound() ? "icon_ewatch" : "icon_ewatch_2")
                if currentModel!.mac == lastestDeviceMac && bleSelf.isConnected {
                    if XGZTBlueToothManager.shared.centralManager?.state == .poweredOff {
                        bConnected = false
                    } else {
                        if value == 100 || XGZTBlueToothManager.shared.isReconnectingNow {
                            bConnected = false
                        } else {
                            bConnected = true
                        }
                    }
                    
                } else {
                    bConnected = false
                }
                let name = (currentModel?.name ?? "") + " - \(bleSelf.bleModel.screenWidth)*\(bleSelf.bleModel.screenHeight)"
                applyContent(name: name, mac: currentModel?.mac ?? "", connected: bConnected)
            }
        }
    }
}

private final class DeviceEdgeInsetLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + contentInsets.left + contentInsets.right,
                      height: size.height + contentInsets.top + contentInsets.bottom)
    }
}
