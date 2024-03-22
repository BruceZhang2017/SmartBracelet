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
    var collectionView : UICollectionView!
    weak var delegate: DevicesViewDelegate?
    weak var currentModel: BLEModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollection()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCollection() {
        let padding: CGFloat = 20
        let layout = CyclicCardFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = padding
        layout.sectionInset = UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0)
        let itemW = ScreenWidth - padding * 2
        layout.itemSize = CGSize(width: itemW, height: 110)
        collectionView = UICollectionView(frame: CGRect(x: 20, y: 0, width: itemW + 1, height: 200), collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CyclicCardCell.self, forCellWithReuseIdentifier: NSStringFromClass(CyclicCardCell.self))
        addSubview(self.collectionView)
    }

    public func refreshData() {
        DeviceManager.shared.initializeDevices()
        collectionView.reloadData()
    }
}

extension DevicesView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(CyclicCardCell.self), for: indexPath) as! CyclicCardCell
        cell.bConnected = false
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        cell.layer.cornerRadius = 10
        let count = DeviceManager.shared.devices.count
        if count == 0 {
            cell.cardImgView.isHidden = true
            cell.cardNameLabel.isHidden = true
            cell.batteryButton.isHidden = true
            cell.btButton.isHidden = true
            cell.addLabel.isHidden = false
        } else {
            cell.cardImgView.isHidden = false
            cell.cardNameLabel.isHidden = false
            cell.batteryButton.isHidden = false
            cell.btButton.isHidden = false
            cell.addLabel.isHidden = true
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
                cell.cardImgView.isHidden = true
                cell.cardNameLabel.isHidden = true
                cell.batteryButton.isHidden = true
                cell.btButton.isHidden = true
                cell.addLabel.isHidden = false
                cell.addLabel.text = "请先连接设备"
            } else {
                cell.cardImgView.image = UIImage(named: "produce_image_no.2")
                cell.cardNameLabel.text = (currentModel?.name ?? "") + " - \(bleSelf.bleModel.screenWidth)*\(bleSelf.bleModel.screenHeight)"
                if currentModel!.mac == lastestDeviceMac && bleSelf.isConnected {
                    cell.btButton.setImage(UIImage(named: "content_blueteeth_link"), for: .normal)
                    cell.btButton.setTitle("mine_bluetooth_connect".localized(), for: .normal)
                    cell.bConnected = true
                } else {
                    cell.btButton.setImage(UIImage(named: "content_blueteeth_unlink"), for: .normal)
                    cell.btButton.setTitle("请连接蓝牙", for: .normal)
                }
                let deviceInfo = DeviceManager.shared.deviceInfo[currentModel!.mac]
                if deviceInfo != nil {
                    if deviceInfo?.battery ?? 0 < 5 {
                        cell.batteryButton.setImage(UIImage(named: "conten_battery_runout"), for: .normal)
                        cell.batteryButton.setTitle(" ", for: .normal)
                    } else {
                        cell.batteryButton.setImage(UIImage(named: "conten_battery_full"), for: .normal)
                        cell.batteryButton.setTitle(" ", for: .normal)
                    }
                } else {
                    cell.batteryButton.setImage(UIImage(named: "conten_battery_null"), for: .normal)
                    cell.batteryButton.setTitle("mine_battery_level_unknown".localized(), for: .normal)
                }
            }
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CyclicCardCell
        delegate?.callbackTap(model:currentModel, bConnected: cell.bConnected)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
//        let pointInView = view.convert(collectionView.center, to: collectionView)
//        let indexPathNow = collectionView.indexPathForItem(at: pointInView)
//        let index = (indexPathNow?.row ?? 0) % imageArr.count
//        let curIndexStr = String(format: "滚动至第%d张", index + 1)
//        print(curIndexStr)
//        showLabel.text = curIndexStr
//
//        // 动画停止, 重新定位到 第50组(中间那组) 模型
//        collectionView.scrollToItem(at: NSIndexPath.init(item: groupCount / 2 * imageArr.count + index, section: 0) as IndexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
    }
}

protocol DevicesViewDelegate: NSObjectProtocol {
    func callbackTap(model: BLEModel?, bConnected: Bool)
}
