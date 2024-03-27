//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BLEManager.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/24.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK
import Toaster
import AudioToolbox
import AVKit

let bleSelf = WUBleManager.shared

class BLEManager: NSObject {
    static let shared = BLEManager()
    var sleepArray: [[SleepModel]] = Array(repeating: [], count: 6)
    var stepArray: [[StepModel]] = Array(repeating: [], count: 6)
    var heartArray: [HeartModel] = []
    var bloodArray: [BloodModel] = []
    var oxygenArray: [OxygenModel] = []
    var alarmArray: [WUAlarmClock] = [] // 闹钟
    var measureAsync: Async?
    var binData = Data()
    var total = 0
    var distanceDays = 0 // 相隔多少天
    var bleFlag = -1
    var audioPlayer: AVAudioPlayer!
    var mTimer: Timer?
    var currentFunctionStep = 0 // 当前读取数据的阶段
    var currentReadProgress = 0 {
        didSet {
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 100, userInfo: ["msg": "\("sync_data".localized())\(currentReadProgress)/9"])
        }
    }
    var isReconnect = false // 当前操作是否为回连
    var isFirstConnected = true // 第一次连接
    
    override init() {
        super.init()
        WUAppManager.isDebug = true 
        bleSelf.setupManager()
        //杰里初始化
        JLSelf.setUpJLinfo()
        callback()
        setupNotify()
        
        // MARK:- 杰里回调
        JLSelf.JLPushBlock = { result in
            if result {
                Async.main {
                    self.showHud(NSLocalizedString("推送成功", comment: ""))
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 2)
                }
            }else{
                Async.main {
                    self.showHud(NSLocalizedString("推送失败", comment: ""))
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 3)
                }
            }
        }
        
        JLSelf.JLProgressBlock = { result in
            let s = String(format: "%.02f%%", result*100.0)
            NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 1, userInfo: ["p": s])
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func startScan() {
        if bleSelf.isBluetoothOn {
            log.info("开始扫描设备")
            bleSelf.startFindBleDevices()

        }
    }
    
    public func startScanAndConnect() {
        if bleSelf.isBluetoothOn == false {
            return
        }
        if let model = WUBleModel.getModel() as? TJDWristbandSDK.WUBleModel {
            bleSelf.bleModel = model
            if bleSelf.bleModel.internalNumberString.hasPrefix("P1") || bleSelf.bleModel.internalNumberString.hasPrefix("S1") {
                bleSelf.bleModel.screenWidth = 80
                bleSelf.bleModel.screenHeight = 160
            }
            bleSelf.connectBleDevice(model: bleSelf.bleModel)
            startTimer(timerTnternal: 2)
            log.info("开始连接设备")
        }
    }
    
    public func rescan() {
        bleSelf.bleModels.removeAll()
        bleSelf.startFindBleDevices()
    }

    public func unbind() {
        bleSelf.disconnectBleDevice()
        //解绑
        let model = WUBleModel()
        bleSelf.bleModel = model
        WUBleModel.setModel(bleSelf.bleModel)
        Toast(text: "unbind_device_desc".localized()).show()
        wuPrint("解绑成功 - 设置 - 手动忽略该设备后可重新扫描蓝牙进行重连")
    }
    
    public func startTimer(timerTnternal: TimeInterval) {
        MRGCDTimer.share.scheduledDispatchTimer(withName: "BLEManager", timeInterval: timerTnternal, queue: .global(), repeats: false) {
            
        }
    }
    
    public func endTimer() {
        MRGCDTimer.share.destoryTimer(withName: "BLEManager")
    }
    
    public func setupNotify() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleBLENotify), name: WUBleManagerNotifyKeys.on, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBLENotify), name: WUBleManagerNotifyKeys.off, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBLENotify), name: WUBleManagerNotifyKeys.scan, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBLENotify), name: WUBleManagerNotifyKeys.connected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBLENotify), name: WUBleManagerNotifyKeys.disconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBLENotify(_:)), name: WUBleManagerNotifyKeys.stateChanged, object: nil)
    }
    
    @objc func handleBLENotify(_ notify: Notification) {
        if notify.name == WUBleManagerNotifyKeys.on {
            print("蓝牙已打开")
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 0)
            if bleFlag == 1 {
                bleFlag = -1
                startScanAndConnect()
            }
        }
        
        if notify.name == WUBleManagerNotifyKeys.off {
            print("蓝牙未打开")
            bleFlag = 1
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1)
        }
        
        if notify.name == WUBleManagerNotifyKeys.scan {
            // 如果搜索到设备后，刷新列表
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "scan") // 搜索页面
        }
        
        if notify.name == WUBleManagerNotifyKeys.connected {
            // 将蓝牙对象设置为已绑定，保存蓝牙对象
            Toast(text: "toast_success".localized()).show()
            endTimer()
            bleSelf.bleModel.isBond = true
            WUBleModel.setModel(bleSelf.bleModel)
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected") // 通知搜索页面
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: nil) // 通知主控页面
            let deviceMac = lastestDeviceMac
            lastestDeviceMac = bleSelf.bleModel.mac
            if lastestDeviceMac.count > 0 {
                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                UserDefaults.standard.synchronize()
                if deviceMac == lastestDeviceMac && isFirstConnected == false {
                    isReconnect = true
                } else {
                    isReconnect = false
                }
            }
            isFirstConnected = false
        }
        
        if notify.name == WUBleManagerNotifyKeys.disconnected {
            print("蓝牙断开连接")
            isReconnect = false
            if bleSelf.bleModel.isBond == true && lastestDeviceMac.count > 0 {
                isReconnect = true
                bleSelf.reConnectDevice() // 执行重新连接
            }
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: "disconnect")
            NotificationCenter.default.post(name: Notification.Name("UploadImageViewController"), object: nil)
        }
        
        if notify.name == WUBleManagerNotifyKeys.stateChanged {
            print("蓝牙状态变更：\(bleSelf.stringFromState())")
        }
    }
    
    private func callback() {
        bleSelf.didSetStartMeasure = {(isSuccess, type) in
            print("回调设置开始测试功能: \(isSuccess) \(type)")
            if isSuccess {
            }
        }
        
        bleSelf.didSetUserinfo = { isSuccess in
            print("回调设置用户信息功能: \(isSuccess)")
            if isSuccess {
            }
        }
        
        bleSelf.didSetCamera = { (isSuccess, isEnter) in
            print("回调拍照是否成功: \(isSuccess) \(isEnter)")
        }
        
        bleSelf.didSetLongSit = { isSuccess in
            print("回调设置长座提醒功能: \(isSuccess)")
            if isSuccess {
            }
        }
        
        bleSelf.didSetSwitch = { isSuccess in
            print("回调设置开关功能: \(isSuccess)")
            if isSuccess {
            }
        }
    }
    
    public func regNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.search_Phone, object: nil )
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.readyToWrite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: JLComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.read_Sport, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.read_All_Sport, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.read_All_Sleep, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sysCeLiang_heart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sysCeLiang_blood, object: nil)
        
        // 测量后，返回的数据
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.devSendCeLiang_heart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.devSendCeLiang_blood, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.setOrRead_Time, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.syncLanguage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.getDevInfo, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.search_Dev, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.setOrRead_UserInfo, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.takePhoto, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.setOrRead_Switch, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.setOrRead_SitParam, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.syncEle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.setOrRead_Alarm, object: nil) // 闹钟读取和设置
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sysCeLiang_oxygen, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.devSendCeLiang_oxygen, object: nil)
        
        //MARK: 监听表盘推送
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.startDialPush, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.dialPush, object: nil)
        
        #if WeiZhongYun_
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.powerSwitch, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.telephoneSMS, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.gps_total, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.gps_info, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.gps_detail, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sleep_setting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.body_temperature, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.e_sim, object: nil)
        #endif
        
        #if DisplayPrint_
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sendData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.recieveData, object: nil)
        #endif
    }

    @objc func handleNotify(_ notify: Notification) {
        #if DisplayPrint_
        if notify.name == WristbandNotifyKeys.sendData {
            let str = notify.object as? String ?? ""
            wuPrint("发送的值：\(str)")
        }
        if notify.name == WristbandNotifyKeys.recieveData {
            let str = notify.object as? String ?? ""
            wuPrint("接收的值：\(str)")
        }
        #endif
        if notify.name == WristbandNotifyKeys.search_Phone {
            // 创建通知内容
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("device_tip", comment: "")
            content.body = NSLocalizedString("found_success", comment: "")
            content.badge = 1
            content.sound = .default

            // 设置触发器
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            // 创建通知请求
            let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)

            // 添加通知请求到UNUserNotificationCenter
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("添加本地通知错误: \(error.localizedDescription)")
                } else {
                    print("添加本地通知成功")
                }
            }
            
            DispatchQueue.main.async {
                [weak self] in
                if UIApplication.shared.applicationState == .active {
                    let path = Bundle.main.path(forResource: "Alarm", ofType: "mp3")!
                    let url = URL(fileURLWithPath: path)
                    do {
                        self?.audioPlayer =  try AVAudioPlayer(contentsOf: url)
                    } catch {
                      // can't load file
                    }
                    self?.audioPlayer.play()
                }
                
                
                let alert = UIAlertController(title: "device_tip".localized(), message: "found_success".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .cancel, handler: { [weak self] action in
                    self?.audioPlayer.stop()
                }))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
                    
                })
            }
        }
        
        if notify.name == WristbandNotifyKeys.readyToWrite {
            wuPrint("可以进行列表上的功能操作了！")
            if isReconnect { // 如果是断开，则不进行数据读取
                wuPrint("回连，不读取信息")
                return
            }
            bleSelf.bindSetForWristband() // 第0步：先绑定设备
            ///此通知非杰里设备在这里开始同步数据
            if !bleSelf.isJLBlue{
                Async.main(after: 0.1) {
                    bleSelf.setTimeForWristband() // 第0步：设置时间
                    bleSelf.getDeviceInfoForWristband() // 第1步：获取设备信息
                }
                currentReadProgress = 1
                
                Async.main(after: 0.2) {
                    bleSelf.setLanguageForWristband() // 第0步：同步语言
                }
                NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2) // 加载loading动效
            }
        }
        
        //杰里配对成功后同步
        if notify.name == JLComplete {
            wuPrint("JL设备配对成功")
            currentReadProgress = 1
            bleSelf.setTimeForWristband() // 第0步：设置时间
            bleSelf.getDeviceInfoForWristband() // 第1步：获取设备信息
            
            Async.main(after: 0.2) {
                bleSelf.setLanguageForWristband() // 第0步：同步语言
            }
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2) // 加载loading动效
        }
        
        if notify.name == WristbandNotifyKeys.bindSet {
            wuPrint("ANCS 绑定成功")
        }
                
        if notify.name == WristbandNotifyKeys.read_Sport {
            wuPrint("current step：%d", bleSelf.step)
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
            print("开始读取心跳：\(currentFunctionStep)")
            currentFunctionStep = 5
            currentReadProgress = 4
            bleSelf.aloneGetMeasure(.heart) // 第5步：获取心跳历史数据
            startReadDataTimer() //启动服务器
            perform(#selector(handleHideLoading), with: nil, afterDelay: 1) // 隐藏loading
        }
                
        if notify.name == WristbandNotifyKeys.read_All_Sport {
            endReadDataTimer()
            currentFunctionStep = 0
            guard let  model = notify.object as? StepModel else {
                return
            }
            let savedTimeStamp = UserDefaults.standard.integer(forKey: "SavedTimeStamp")
            if model.timeStamp > savedTimeStamp {
                UserDefaults.standard.setValue(model.timeStamp, forKey: "SavedTimeStamp")
            }
            let date = WUDate.dateFromTimeStamp(model.timeStamp)
            let dateStr = date.stringFromYmdHms()
            wuPrint(model.step, dateStr)
            if model.day >= 3 {
                return
            }
            stepArray[model.day] += [model]
            let day = min(3, distanceDays)
            if model.day == day {
                if model.totalCount == model.indexOfTotal {
                    print("detail step sync complete", model.day)
                    bleSelf.aloneGetSleep(with: 1) // 第10步：从前一天开始获取
                }
            } else {
                if model.totalCount == model.indexOfTotal {
                    print("detail step sync complete", model.day)
                    bleSelf.aloneGetStep(with: model.day + 1)
                }
            }
            if model.step == 0 {
                return
            }
            let stepModel = DStepModel()
            stepModel.mac = model.mac
            stepModel.uuidString = model.uuidString
            stepModel.timeStamp = model.timeStamp
            stepModel.step = model.step
            stepModel.distance = model.distance
            stepModel.cal = model.cal
            try? stepModel.er.save(update: true)
            print("将步数信息保存到数据库中: \(stepModel.timeStamp)")
        }
        
        if notify.name == WristbandNotifyKeys.read_All_Sleep {
            guard let model = notify.object as? SleepModel else {
                return
            }
            dump(model)
            sleepArray[model.day] += [model]
            let sleepModel = DSleepModel()
            sleepModel.mac = model.mac
            sleepModel.uuidString = model.uuidString
            sleepModel.state = model.state
            sleepModel.timeStamp = model.timeStamp
            sleepModel.indexOfTotal = model.indexOfTotal
            sleepModel.totalCount = model.totalCount
            sleepModel.day = model.day
            try? sleepModel.er.save(update: true)
            print("将睡眠信息保存到数据库中: \(sleepModel.timeStamp)")
            if model.day == 2 {
                if model.totalCount == model.indexOfTotal {
                    print("detail sleep sync complete", model.day) // 第11步：数据已经全部读完
                    
                }
            } else {
                if model.totalCount == model.indexOfTotal {
                    print("detail sleep sync complete", model.day)
                    bleSelf.aloneGetSleep(with: model.day + 1)
                }
            }
            if model.day == 0 {
                if model.totalCount == model.indexOfTotal {
                    print("开始读取血压: \(currentFunctionStep)")
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "sleep")
                    currentFunctionStep = 7
                    currentReadProgress = 6
                    bleSelf.aloneGetMeasure(.blood) // 第7步：获取血压历史数据
                    startReadDataTimer()
                }
            }
        }
                
        if notify.name == WristbandNotifyKeys.sysCeLiang_heart {
            guard let  model = notify.object as? HeartModel else {
                return
            }
            dump(model)
            heartArray.append(model)
            let heartModel = DHeartRateModel()
            heartModel.mac = model.mac
            heartModel.uuidString = model.uuidString
            heartModel.heartRate = model.heart
            heartModel.timeStamp = model.timeStamp
            try? heartModel.er.save(update: true)
            print("收到测试心跳的结果: \(heartModel.timeStamp)")
            if model.indexOfTotal == model.totalCount {
                let str1 = String.init(format: "heart history complete, total %d line", model.totalCount)
                wuPrint(str1)
                heartArray.sort {
                    $0.timeStamp > $1.timeStamp
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
            }
            currentFunctionStep = 6
            currentReadProgress = 5
            print("开始读取睡眠: \(currentFunctionStep)")
            bleSelf.aloneGetSleep(with: 0) // 第6步：获取历史睡眠信息
            startReadDataTimer()
        }
                
        if notify.name == WristbandNotifyKeys.sysCeLiang_blood {
            guard let  model = notify.object as? BloodModel else {
                return
            }
            dump(model)
            print("开始解析血压数据")
            bloodArray.append(model)
            let bloodModel = DBloodModel()
            bloodModel.mac = model.mac
            bloodModel.uuidString = model.uuidString
            bloodModel.min = model.min
            bloodModel.max = model.max
            bloodModel.timeStamp = model.timeStamp
            if model.min > 0 && model.max > 0 {
                try? bloodModel.er.save(update: true)
            }
            if model.indexOfTotal == model.totalCount {
                let str1 = String.init(format: "blood history complete, total %d line", model.totalCount)
                wuPrint(str1)
                bloodArray.sort {
                    $0.timeStamp > $1.timeStamp
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
            }
            DispatchQueue.main.async {
                [weak self] in
                self?.currentReadProgress = 7
                bleSelf.aloneGetMeasure(.oxygen) // 第8步：获取血氧历史数据
                self?.perform(#selector(BLEManager.readStepHistory), with: nil, afterDelay: 2)
            }
        }
        
        if notify.name == WristbandNotifyKeys.devSendCeLiang_heart {
            measureAsync?.cancel()
            guard let  model = notify.object as? HeartModel else {
                return
            }
            dump(model)
            let heartModel = DHeartRateModel()
            heartModel.mac = model.mac
            heartModel.uuidString = model.uuidString
            heartModel.heartRate = model.heart
            heartModel.timeStamp = model.timeStamp
            try? heartModel.er.save(update: true)
            print("收到测试心跳的结果: \(heartModel.timeStamp)")
            if heartArray.count > 0 {
                heartArray.insert(model, at: 0)
            } else {
                heartArray.append(model)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: nil)
            }
        }
        if notify.name == WristbandNotifyKeys.devSendCeLiang_blood {
            measureAsync?.cancel()
            guard let  model = notify.object as? BloodModel else {
                return
            }
            dump(model)
            let bloodModel = DBloodModel()
            bloodModel.mac = model.mac
            bloodModel.uuidString = model.uuidString
            bloodModel.min = model.min
            bloodModel.max = model.max
            bloodModel.timeStamp = model.timeStamp
            if model.min > 0 && model.max > 0 {
                try? bloodModel.er.save(update: true)
            }
            wuPrint("血压结束")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: nil)
            }
            if bloodArray.count > 0 {
                bloodArray.insert(model, at: 0)
            } else {
                bloodArray.append(model)
            }
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
        }
        
        if notify.name == WristbandNotifyKeys.sysCeLiang_oxygen {
            guard let  model = notify.object as? OxygenModel else {
                return
            }
            let oxygenModel = DOxygenModel()
            oxygenModel.mac = model.mac
            oxygenModel.uuidString = model.uuidString
            oxygenModel.timeStamp = model.timeStamp
            oxygenModel.oxygen = model.oxygen
            if model.oxygen > 0 {
                print("将血氧数据保存至数据库中：\(model.timeStamp)")
                try? oxygenModel.er.save(update: true)
            }
            let str = String(format: "oxygen：%d, %d, %d", model.oxygen, model.indexOfTotal, model.totalCount)
            wuPrint(str)
            oxygenArray.append(model)
            if model.indexOfTotal == model.totalCount {
                let str1 = String(format: "oxygen history complete, total %d line", model.totalCount)
                wuPrint(str1)
                stepArray = Array(repeating: [], count: 6)
                // 处理需要读取几天的数据
                let savedTimeStamp = UserDefaults.standard.integer(forKey: "SavedTimeStamp")
                if savedTimeStamp > 0 {
                    let date = WUDate.dateFromTimeStamp(savedTimeStamp)
                    let distance = Calendar.current.dateComponents([.day], from: Date(), to: date)
                    distanceDays = min(abs(distance.day ?? 0) + 1, 6)
                } else {
                    distanceDays = 6
                }
                oxygenArray.sort {
                    $0.timeStamp > $1.timeStamp
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
            }
        }
        if notify.name == WristbandNotifyKeys.devSendCeLiang_oxygen {
            measureAsync?.cancel()
            guard let  model = notify.object as? OxygenModel else {
                return
            }
            dump(model)
            let oxygenModel = DOxygenModel()
            oxygenModel.mac = model.mac
            oxygenModel.uuidString = model.uuidString
            oxygenModel.timeStamp = model.timeStamp
            oxygenModel.oxygen = model.oxygen
            if model.oxygen > 0 {
                print("将血氧数据保存至数据库中：\(model.timeStamp)")
                try? oxygenModel.er.save(update: true)
            }
            print("血氧结束")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: nil)
            }
            if oxygenArray.count > 0 {
                oxygenArray.insert(model, at: 0)
            } else {
                oxygenArray.append(model)
            }
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
        }
        
        if notify.name == WristbandNotifyKeys.setOrRead_Time { // 时间设置成功
            bleSelf.ruiYuDialSet()
            print("时间同步成功")
            Async.main(after: 0.3) {
                bleSelf.getBatteryForWristband()
            }
            Async.main(after: 1.5) {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }
        }
         
        if notify.name == WristbandNotifyKeys.syncEle { // 电量同步结束后
            if bleSelf.isJLBlue {
                var deviceModel = DeviceManager.shared.deviceInfo[bleSelf.bleModel.mac]
                deviceModel?.battery = bleSelf.batteryLevel
            } else {
                var deviceModel = DeviceManager.shared.deviceInfo[bleSelf.bleModel.mac]
                deviceModel?.battery = bleSelf.batteryLevel
            }
            print("电量读取成功: \(bleSelf.batteryLevel)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
                NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: "1")
            }
        }
                
        if notify.name == WristbandNotifyKeys.syncLanguage {
            print("语言设置成功")
        }
                
        if notify.name == WristbandNotifyKeys.getDevInfo {
            dump(bleSelf.bleModel)
            dump(bleSelf.funcListModel)
            print("设备信息获取成功")
            if bleSelf.bleModel.mac.count > 0 {
                lastestDeviceMac = bleSelf.bleModel.mac
                UserDefaults.standard.setValue(bleSelf.bleModel.mac, forKey: "LastestDeviceMac")
                UserDefaults.standard.synchronize()
            }
            if bleSelf.bleModel.internalNumberString.hasPrefix("P1") || bleSelf.bleModel.internalNumberString.hasPrefix("S1") {
                bleSelf.bleModel.screenWidth = 80
                bleSelf.bleModel.screenHeight = 160
                log.info("更新设备的信息")
            }
            bleSelf.getUserinfoForWristband() // 第2步：获取用户信息
            currentReadProgress = 2
            Async.main(after: 1) {
                bleSelf.getBatteryForWristband()
            }
        }
                
        if notify.name == WristbandNotifyKeys.search_Dev {
            print("查找手环成功")
        }
                
        if notify.name == WristbandNotifyKeys.setOrRead_UserInfo {
            dump(bleSelf.userInfo)
            print("用户信息获取成功")
            bleSelf.getStep() // 第3步：获取步数
            let deviceModel = DeviceModel()
            deviceModel.battery = bleSelf.batteryLevel
            deviceModel.mac = bleSelf.bleModel.mac
            deviceModel.name = bleSelf.bleModel.name
            DeviceManager.shared.deviceInfo[bleSelf.bleModel.mac] = deviceModel
            currentReadProgress = 3
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }
        }
                
        if notify.name == WristbandNotifyKeys.takePhoto {
            print("takePhoto成功")
            NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: nil)
        }
        
        if notify.name == WristbandNotifyKeys.setOrRead_SitParam {
            dump(bleSelf.longSitModel)
            print("setOrRead_SitParam成功")
        }
        
        if notify.name == WristbandNotifyKeys.setOrRead_Switch {
            dump(bleSelf.functionSwitchModel)
            print("setOrRead_Switch成功")
        }
        
        //MARK: 表盘推送监听
        if notify.name == WristbandNotifyKeys.startDialPush {
            let any = notify.object as! Int
            if any == 1 {
                print("支持表盘推送可以开始推送")
                NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 1)
                for i in 0..<self.total {
                    print("循环推送数据:"+String(i))
                    let d = Float(i * 100) / Float(self.total)
                    let s = String(format: "%.02f%%", d)
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 1, userInfo: ["p": s])
                    bleSelf.setDialPush(binData, dataIndex: i)
                    Thread.sleep(forTimeInterval: 0.03)
                }
                NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 2)
            } else {
                Async.main {
                    Toast(text: "该设备不支持表盘推送，或者电量过低").show()
                }
            }
        }
        
        if notify.name == WristbandNotifyKeys.dialPush {
            if let any = notify.object, any is [Int] {
                let array = any as! [Int]
                if array[1] == 0 {
                    wuPrint("更新失败")
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 3)
                }
            }
        }
        
        
        #if WeiZhongYun_
        print("为中云2")
        if notify.name == WristbandNotifyKeys.powerSwitch {
            dump(bleSelf.userInfo)
        }
        
        if notify.name == WristbandNotifyKeys.telephoneSMS {
            dump(bleSelf.userInfo)
        }
        
        if notify.name == WristbandNotifyKeys.gps_total {
            dump(notify.object)
        }
        if notify.name == WristbandNotifyKeys.gps_info {
            dump(notify.object)
        }
        if notify.name == WristbandNotifyKeys.gps_detail {

        }
        if notify.name == WristbandNotifyKeys.sleep_setting {
            dump(bleSelf.sleepSettingModel)
        }
        
        if notify.name == WristbandNotifyKeys.e_sim {
            dump(bleSelf.userInfo)
        }
        if notify.name == WristbandNotifyKeys.body_temperature {
            dump(bleSelf.userInfo)
        }
        #endif
        if notify.name == WristbandNotifyKeys.setOrRead_Alarm { // 闹钟读取、设置
            guard let model = notify.object as? WUAlarmClock else {
                return
            }
            if model.clockId == 0 {
                alarmArray.removeAll()
            }
            alarmArray.append(model)
            if model.clockId >= 2 {
                DispatchQueue.main.async { // 返回主线程刷新
                    NotificationCenter.default.post(name: Notification.Name.Alarm, object: nil)
                }
            }
            dump(model)
        }
    }
    
    @objc private func handleHideLoading() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3) // 移除Loading
        }
    }
}

extension BLEManager {
    public func showBLEAlertView() {
        let alertView = UIAlertController(title: "系统提示", message: "请先开启蓝牙，设置 -> 蓝牙", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "mine_cancel".localized(), style: .cancel) { (action) in
            
        }
        let ok = UIAlertAction(title: "mine_confirm".localized(), style: .default) { (action) in
            let url = URL(string: "App-Prefs:root=Bluetooth")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
        }
        alertView.addAction(cancel)
        alertView.addAction(ok)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.present(alertView, animated: true, completion: {
            
        })
    }
}

extension BLEManager {
    public func readSleepData(array: [SleepModel]) -> [Int]  {
        let arr = SleepModel.sleepTime(array)
        let a = SleepTimeModel.detailSleep(arr)
        print("清醒时间:\(a[0])，浅睡时间:\(a[1])，深睡时间:\(a[2])")
        return a
    }
    
    public func sendDial() {
        let str = "http://app.ss-tjd.com/api/dialpush/0.1/brlt/ui/dw_dial/di201911011148330"
        HttpHelper.shared.getWith(url: str, parameters: nil, success: { (data) in
            let temp = data as! Data
            self.total = Int(ceil(Double(temp.count)/16))
            self.binData = temp
            print("检查是否可以表盘推送")
            bleSelf.startDialPush(temp)
            
        }, failure: { (_) in
            
        }) { (_) in
            
        }
    }
    
    public func sendDialWithLocalBin(_ value: Data) {
        total = Int(ceil(Double(value.count)/16))
        binData = value
        bleSelf.startDialPush(value)
        NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 1)
    }
    
    private func jlPushClock(_ value: Data) {
        ///表盘推送 需要设备支持
        ///正式请从服务器获取  以下是测试用本地数据
        let temp = value
        //必须去掉data前6个字节
        let sub = temp.dropFirst(6)

        wuPrint("subData:\(sub) ---- tempData:\(temp)")
        
        if bleSelf.isJLBlue && !bleSelf.funcCategoryModel.hasJLPush{
            
            if bleSelf.batteryLevel <= 15 {
                self.showHud(NSLocalizedString("设备电量低，请先给设备充电", comment: ""))
                return
            }
            
            JLSelf.JLtotal = Int(ceil(Double(sub.count)/16))
            JLSelf.JLbinData = sub
            
            //请注意 这里杰里表盘是根据做好表盘的固定表盘文件名字 不能随便写  已推过的会变成设置成功不会再推数据
//                    let stringName = daiName.uppercased()  //转大写
            JLSelf.JLdialName = "WH211"
            wuPrint("打印图片大小",JLSelf.JLdialName)
            wuPrint(self.binData.count)
        
            JLSelf.btn_list()
            NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 1)
        } else {
            sendDialWithLocalBin(value)
        }
    }
}

extension BLEManager {
    // 初始化获取数据定时器判断
    func startReadDataTimer() {
        print("当前为主线程: \(Thread.current.isMainThread)")
        endReadDataTimer()
        mTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] t in
            log.info("开始执行定时器")
            let step = self?.currentFunctionStep ?? 0
            if step == 0 {
                print("开始读取心跳2: \(step)")
                self?.currentFunctionStep = 5
                bleSelf.aloneGetMeasure(.heart) // 第5步：获取心跳历史数据
            } else if step == 5 {
                print("开始读取睡眠2: \(step)")
                self?.currentFunctionStep = 6
                bleSelf.aloneGetSleep(with: 0) // 第6步：获取历史睡眠信息
            } else if step == 6 {
                print("开始读取血压2 : \(step)")
                self?.currentFunctionStep = 7
                bleSelf.aloneGetMeasure(.blood) // 第7步：获取血压历史数据
            } else if step == 7 {
                print("开始读取步行2 : \(step)")
                self?.currentFunctionStep = 9
                bleSelf.aloneGetStep(with: 0) // 第9步：获取历史步行信息
            }
        })
        mTimer?.fire()
        if mTimer != nil {
            RunLoop.current.add(mTimer!, forMode: .common)
        }
    }
    
    // 结束
    func endReadDataTimer() {
        mTimer?.invalidate()
        mTimer = nil
    }
    
    @objc func readStepHistory() {
        print("开始读取步数: \(currentFunctionStep)")
        currentFunctionStep = 9
        currentReadProgress = 8
        bleSelf.aloneGetStep(with: 0) // 第9步：获取历史步行信息
        startReadDataTimer()
    }
}
