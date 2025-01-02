//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DevicesViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK
import Toaster

class DevicesViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dialManagmentLabel: UILabel!
    @IBOutlet weak var bottomLConstraint: NSLayoutConstraint!
    @IBOutlet weak var dialView: UIView!
    @IBOutlet weak var deviceBGImageView: UIImageView!
    @IBOutlet weak var btView: UIView!
    let changeButton = UIButton(type: .system)
    let dialButton = VerticalButton(type: .system)
    let btButton = UIButton(type: .system)
    var deviceSettingView: UIView? // 设备设置的视图
    var deviceView: DevicesView!
    var clockArray: [String] = []
    var width: CGFloat = 90
    var height: CGFloat = 150
    var deviceSettingsViewHeightMultiplier = 13
    var deviceSettingsView: DeviceSettingsViewController?
    var lblTitle: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device".localized()
        deviceView = DevicesView().then {
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 16
            $0.clipsToBounds = true 
        }
        topView.addSubview(deviceView)
        deviceView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
        }
        deviceView.setupUI()
        deviceView.refreshData()
        
        contentView.backgroundColor = UIColor.clear
        
        bleSelf.getSwitchForWristband()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DevicesViewController"), object: nil)
        dialManagmentLabel.text = "dial_management".localized()
        initializeDeviceSettings()
        
        let randomBool = Bool.random()
        deviceBGImageView.image = UIImage(named: randomBool ? "device_bg1" : "device_bg2")
        deviceBGImageView.layer.cornerRadius = 16
        deviceBGImageView.clipsToBounds = true
        
        dialView.layer.cornerRadius = 16
        dialView.clipsToBounds = true
        
        btView.layer.cornerRadius = 16
        btView.clipsToBounds = true 
        btView.addSubview(btButton)
        btButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-30)
            make.top.bottom.equalToSuperview()
        }
        btButton.setTitleColor(UIColor.black, for: .normal)
        btButton.titleLabel?.font = UIFont.body2()
        btButton.setTitle("push_to_bt_settings".localized(), for: .normal)
        btButton.contentHorizontalAlignment = .left
        btButton.titleLabel?.numberOfLines = 0
        btButton.addTarget(self, action: #selector(pushToMobileSettings), for: .touchUpInside)
        
        let ivRight = UIImageView(image: UIImage(named: "content_icon_nextgray_normal"))
        btView.addSubview(ivRight)
        ivRight.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-10)
            make.width.equalTo(10)
            make.height.equalTo(17)
        }
        
        
        addChangeButton() // 切换设备
        addDialButton() // 添加表盘
        changeButtonAttr() // 切换设备入口
        
        width = (ScreenWidth - 60) / 3
        if AppDelegate.IsDeviceNotRound() { // 方形
            let w = isXGZT ? (XGZTBlueToothManager.shared.device?.screenWidth ?? 0) : bleSelf.bleModel.screenWidth
            let h = isXGZT ? (XGZTBlueToothManager.shared.device?.screenHeight ?? 0) : bleSelf.bleModel.screenHeight
            height = CGFloat(width) * CGFloat(h) / CGFloat(w)
        } else { // 圆形
            height =  width
        }
        
        print("width: \(width) height: \(height)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deviceView?.refreshData()
        changeButtonAttr()
        refreshDevices()
        
        if isXGZT {
            refreshHeight()
        } else {
            Async.main(after: 1) {
                if bleSelf.isConnected { // 连接成功
                    bleSelf.notifyModel.isWechat = true
                    bleSelf.notifyModel.isQQ = true
                    bleSelf.notifyModel.isLinkedin = true
                    bleSelf.notifyModel.isFacebook = true
                    bleSelf.notifyModel.isTwitter = true
                    bleSelf.notifyModel.isWhatapp = true
                    bleSelf.notifyModel.isLine = true
                    bleSelf.notifyModel.isKakaoTalk = true
                    bleSelf.notifyModel.isFacebookMessage = true
                    bleSelf.notifyModel.isInstagram = true
                    bleSelf.setAncsSwitchForWristband(bleSelf.notifyModel)
                }
            }
        }
    }
    
    private func refreshDevices() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
        let clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
        let clockStr = clockDir[lastestDeviceMac] as? [String] ?? ["_&&_&&_", "_&&_&&_", "_&&_&&_"]
        if clockStr.count > 0 {
            clockArray = clockStr
        } else {
            clockArray.removeAll()
        }
        collectionView?.reloadData()
        if checkIsNullForDial() {
            collectionView?.isHidden = true
            dialButton.isHidden = false
        } else {
            collectionView?.isHidden = false
            dialButton.isHidden = true
        }
    }
    
    private func checkIsNullForDial() -> Bool {
        if clockArray.count == 0 {
            return true
        }
        for item in clockArray {
            let array = item.components(separatedBy: "&&")
            if array[0] == "_" {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 设备设置
    private func initializeDeviceSettings() {
        deviceSettingView = UIView().then {
            $0.backgroundColor = UIColor.white
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 16
            
        }
        contentView.addSubview(deviceSettingView!)
        deviceSettingView?.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.right.equalTo(-15)
            $0.top.equalTo(dialView.snp.bottom).offset(15)
        }
        lblTitle = UILabel().then {
            $0.textColor = UIColor.black
            $0.font = UIFont.boldSystemFont(ofSize: 15)
            $0.text = "device_settings".localized()
        }
        deviceSettingView?.addSubview(lblTitle!)
        lblTitle?.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.top.equalTo(10)
            $0.height.equalTo(20)
        }
        
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        deviceSettingsView = storyboard.instantiateViewController(withIdentifier: "DeviceSettingsViewController") as? DeviceSettingsViewController
        addChild(deviceSettingsView!)
        deviceSettingView?.addSubview(deviceSettingsView!.view)
        deviceSettingsView?.view.snp.makeConstraints {
            $0.left.equalTo(0)
            $0.top.equalTo(lblTitle!.snp.bottom).offset(10)
            $0.right.equalTo(0)
            $0.height.equalTo(52 * deviceSettingsViewHeightMultiplier)
            $0.bottom.equalToSuperview()
        }
        bottomLConstraint.constant = CGFloat(52 * deviceSettingsViewHeightMultiplier + 70)
    }
    
    public func refreshHeight() {
        // 将 deviceSettingsViewHeightMultiplier 修改为 14
        deviceSettingsViewHeightMultiplier = 14
            
        deviceSettingsView?.view.snp.remakeConstraints {
            $0.left.equalTo(0)
            $0.top.equalTo(lblTitle!.snp.bottom).offset(10)
            $0.right.equalTo(0)
            $0.height.equalTo(52 * deviceSettingsViewHeightMultiplier)
            $0.bottom.equalToSuperview()
        }
        updateDeviceSettingsViewBottomConstraint()
    }
    
    private func updateDeviceSettingsViewBottomConstraint() {
        bottomLConstraint.constant = CGFloat(52 * deviceSettingsViewHeightMultiplier + 70)
    }
    
    public func addChangeButton() {
        changeButton.setTitle("switch_device".localized(), for: .normal)
        if let image = UIImage(named: "icon_change_device") {
            changeButton.setImage(image, for: .normal)
        }
        changeButton.tintColor = UIColor.brand
        changeButton.layer.borderColor = UIColor.brand.cgColor
        changeButton.layer.borderWidth = 1.0
        changeButton.backgroundColor = .white
        changeButton.layer.cornerRadius = 22
        // 设置图标的内边距
        changeButton.imageEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -2,
            bottom: 0,
            right: 2
        )

        // 设置标题的内边距
        changeButton.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: 2,
            bottom: 0,
            right: -2
        )
        // 添加按钮到视图中
        topView.addSubview(changeButton)
        changeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(44)
            make.bottom.equalTo(-20)
        }
        changeButton.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
    }
    
    private func changeButtonAttr() {
        if deviceView.isHidden == true {
            changeButton.tintColor = UIColor.white
            changeButton.backgroundColor = .brand
            changeButton.setTitle("device_add".localized(), for: .normal)
            if let image = UIImage(named: "icon_add_device") {
                changeButton.setImage(image, for: .normal)
            }
        } else {
            changeButton.tintColor = UIColor.brand
            changeButton.backgroundColor = .white
            changeButton.setTitle("switch_device".localized(), for: .normal)
            if let image = UIImage(named: "icon_change_device") {
                changeButton.setImage(image, for: .normal)
            }
        }
    }
    
    // 添加表盘按钮
    public func addDialButton() {
        dialButton.setTitle("add_dial".localized(), for: .normal)
        if let image = UIImage(named: "icon_add2") {
            dialButton.setImage(image, for: .normal)
        }
        dialButton.tintColor = UIColor.brand
        dialButton.backgroundColor = UIColor.fill
        dialButton.layer.cornerRadius = 16
        dialView.addSubview(dialButton)
        dialButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(screenWidth - 64)
            make.height.equalTo(130)
            make.top.equalTo(44)
        }
        dialButton.addTarget(self, action: #selector(pushToDial), for: .touchUpInside)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if let obj = notification.object as? String, obj.count > 0 {
            print("刷新设备列表数据")
            deviceView?.refreshData()
            changeButtonAttr()
            refreshDevices()
            return
        }
        //self.perform(#selector(pushToMobileSettings), with: nil, afterDelay: 0.3)
    }
    
    @objc private func pushToMobileSettings() {
        let url = URL(string: "App-Prefs:root=Bluetooth")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }

    /// 表盘管理
    func pushToClockManage(index: Int) {
        if bleSelf.bleModel.screenWidth == 80 {
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let myClockVC = storyboard.instantiateViewController(withIdentifier: "MyClockViewController") as! MyClockViewController
            myClockVC.index = index
            navigationController?.pushViewController(myClockVC, animated: true)
            return
        }
        
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ClockManageViewController") as? ClockManageViewController
        vc?.index = index
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction private func showPop(_ sender: Any) {
        
    }
    
    @objc public func addDevice() {
        var count = DeviceManager.shared.devices.count
        count += BluetoothWatchDevice.loadAll()?.count ?? 0
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        if count == 0 {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
            vc.title = "device_add".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController")
            vc.title = "device_change".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc public func pushToDial() {
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        pushToClockManage(index: 0)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockBCollectionViewCell
        cell.addImageView.image = UIImage(named: "icon_add2")
        if indexPath.row < clockArray.count  {
            let item = clockArray[indexPath.item]
            let array = item.components(separatedBy: "&&")
            if array[0] == "_" || (DeviceManager.shared.devices.count == 0 && (BluetoothWatchDevice.loadAll()?.count ?? 0) == 0) {
                cell.clockImageView.isHidden = true
                cell.addImageView.isHidden = false
                cell.clockBGView.backgroundColor = UIColor.fill
            } else {
                cell.clockImageView.isHidden = false
                cell.addImageView.isHidden = true
                cell.clockBGView.backgroundColor = UIColor.clear
                if array[1].contains(".png") || array[1].contains(".jpg") || array[1].contains(".jpeg") {
                    print("保存的图片路径：\(array[1])")
                    if array[1].contains("Documents") {
                        cell.clockImageView.image = UIImage(contentsOfFile: array[1])
                    } else {
                        if array[1].contains("http") {
                            cell.clockImageView.kf.setImage(with: URL(string: array[1]))
                        } else {
                            let fullPath = NSHomeDirectory().appending("/Documents/").appending(array[1])
                            cell.clockImageView.image = UIImage(contentsOfFile: fullPath)
                        }
                    }
                }
            }
            
        } else {
            cell.clockImageView.isHidden = true
            cell.addImageView.isHidden = false
            cell.clockBGView.backgroundColor = UIColor.fill
        }
        cell.width.constant = width
        cell.height.constant = height
        return cell
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        pushToClockManage(index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension String {
    static let kDevice = "Device"
}


class VerticalButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let imageViewSize = self.imageView?.frame.size,
              let titleLabelSize = self.titleLabel?.frame.size else {
            return
        }
        
        let totalHeight = imageViewSize.height + titleLabelSize.height
        
        self.imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageViewSize.height),
            left: 0,
            bottom: 0,
            right: -titleLabelSize.width
        )
        
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageViewSize.width,
            bottom: -(totalHeight - titleLabelSize.height),
            right: 0
        )
    }
    
    override var intrinsicContentSize: CGSize {
        guard let imageViewSize = self.imageView?.frame.size,
              let titleLabelSize = self.titleLabel?.frame.size else {
            return super.intrinsicContentSize
        }
        
        let width = max(imageViewSize.width, titleLabelSize.width)
        let height = imageViewSize.height + titleLabelSize.height + self.titleEdgeInsets.top
        
        return CGSize(width: width, height: height)
    }
}
