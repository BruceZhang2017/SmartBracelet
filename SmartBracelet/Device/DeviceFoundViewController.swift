//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceFoundViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DeviceFoundViewController: BaseViewController {
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var foundButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    private var breathAnimationView: SCBreathAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "find_a_device".localized()
        deviceImageView.backgroundColor = UIColor.brand.withAlphaComponent(0.4)
        deviceImageView.layer.cornerRadius = 75
        let childImageView = UIImageView(frame: CGRect(x: 31, y: 31, width: 88, height: 88)) // 150-88=62，62/2=31
        childImageView.contentMode = .scaleAspectFit // 或者使用.center
        childImageView.image = UIImage(named: AppDelegate.IsDeviceNotRound() ? "icon_ewatch" : "icon_ewatch_2")
        deviceImageView.addSubview(childImageView)
        
        
        cancelButton.setTitle("mine_cancel".localized(), for: .normal)
        cancelButton.backgroundColor = UIColor.clear
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.brand.cgColor
        cancelButton.layer.cornerRadius = 26
        cancelButton.clipsToBounds = true
        cancelButton.setTitleColor(UIColor.brand, for: .normal)
        cancelButton.titleLabel?.font = UIFont.subtitle()
        
        
        foundButton.setTitle("find".localized(), for: .normal)
        foundButton.backgroundColor = UIColor.brand
        foundButton.layer.cornerRadius = 26
        foundButton.clipsToBounds = true
        foundButton.setTitleColor(UIColor.white, for: .normal)
        foundButton.titleLabel?.font = UIFont.subtitle()
        
        addSearchView()
        view.bringSubviewToFront(deviceImageView)
        breathAnimationView?.waveView.backgroundColor = UIColor.clear
    }
    
    /// 添加搜索视图
    private func addSearchView() {
        breathAnimationView = SCBreathAnimationView.viewFromNIB()
        breathAnimationView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(breathAnimationView!)
        
        breathAnimationView?.snp.makeConstraints {
            $0.center.equalTo(deviceImageView)
            $0.width.height.equalTo(150)
        }
    }
    
    public func testing() {
        breathAnimationView?.startAnimation()
    }
    
    public func stop() {
        breathAnimationView?.stopAnimation()
    }
    
    @IBAction func found(_ sender: Any) {
        if isXGZT {
            XGZTCommand.findBand(p0: 0)
        } else {
            bleSelf.findDeviceForWristband()
        }
        testing()
    }
    
    @IBAction func cancel(_ sender: Any) {
        if isXGZT {
            XGZTCommand.findBand(p0: 1)
        }
        stop()
        navigationController?.popViewController(animated: true)
    }
    
}
