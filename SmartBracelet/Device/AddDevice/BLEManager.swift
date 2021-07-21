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

let bleSelf = WUBleManager.shared

class BLEManager: NSObject {
    static let shared = BLEManager()
    var sleepArray: [[TJDSleepModel]] = Array(repeating: [], count: 6)
    var stepArray: [[StepModel]] = Array(repeating: [], count: 6)
    var heartArray: [HeartModel] = []
    var bloodArray: [BloodModel] = []
    var oxygenArray: [OxygenModel] = []
    var alarmArray: [WUAlarmClock] = [] // 闹钟
    var measureAsync: Async?
    var binData = Data()
    var total = 0
    var distanceDays = 0 // 相隔多少天
    
    override init() {
        super.init()
        WUAppManager.isDebug = true 
        bleSelf.setupManager()
        callback()
        setupNotify()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func startScan() {
        if bleSelf.isBluetoothOn {
            bleSelf.startFindBleDevices()

        }
    }
    
    public func startScanAndConnect() {
        if bleSelf.isBluetoothOn == false {
            return
        }
        if let model = WUBleModel.getModel() as? TJDWristbandSDK.WUBleModel {
            bleSelf.bleModel = model
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
        bleSelf.bleModel.isBond = false
        WUBleModel.setModel(bleSelf.bleModel)
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
        }
        
        if notify.name == WUBleManagerNotifyKeys.off {
            print("蓝牙未打开")
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1)
        }
        
        if notify.name == WUBleManagerNotifyKeys.scan {
            // 如果搜索到设备后，刷新列表
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "scan") // 搜索页面
        }
        
        if notify.name == WUBleManagerNotifyKeys.connected {
            // 将蓝牙对象设置为已绑定，保存蓝牙对象
            print("lefun设备连接成功")
            endTimer()
            bleSelf.bleModel.isBond = true
            WUBleModel.setModel(bleSelf.bleModel)
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected") // 通知搜索页面
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: nil) // 通知主控页面
            lastestDeviceMac = bleSelf.bleModel.mac
            UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
            UserDefaults.standard.synchronize()
        }
        
        if notify.name == WUBleManagerNotifyKeys.disconnected {
            print("蓝牙断开连接")
            if bleSelf.bleModel.isBond == true && lastestDeviceMac.count > 0 {
                bleSelf.reConnectDevice()
            }
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: "disconnect")
        }
        
        if notify.name == WUBleManagerNotifyKeys.stateChanged {
            print("蓝牙状态变更：\(bleSelf.stringFromState())")
        }
    }
    
    private func callback() {
        bleSelf.didSetStartMeasure = {(isSuccess, type) in
            if isSuccess {
            }
        }
        
        bleSelf.didSetUserinfo = { isSuccess in
            if isSuccess {
            }
        }
        
        bleSelf.didSetCamera = { (isSuccess, isEnter) in
        }
        
        bleSelf.didSetLongSit = { isSuccess in
            if isSuccess {
            }
        }
        
        bleSelf.didSetSwitch = { isSuccess in
            if isSuccess {
            }
        }
    }
    
    public func regNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.readyToWrite, object: nil)
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
                
        if notify.name == WristbandNotifyKeys.readyToWrite {
            wuPrint("可以进行列表上的功能操作了！")
            bleSelf.bindSetForWristband() // 第0步：先绑定设备
            bleSelf.setTimeForWristband() // 第0步：设置时间
            bleSelf.setLanguageForWristband() // 第0步：同步语言
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2)
        }
        
        if notify.name == WristbandNotifyKeys.bindSet {
            wuPrint("ANCS 绑定成功")
            bleSelf.getDeviceInfoForWristband() // 第1步：获取设备信息
        }
                
        if notify.name == WristbandNotifyKeys.read_Sport {
            wuPrint("current step：%d", bleSelf.step)
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
            bleSelf.aloneGetMeasure(.heart) // 第5步：获取心跳历史数据
        }
                
        if notify.name == WristbandNotifyKeys.read_All_Sport {
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
        }
        
        if notify.name == WristbandNotifyKeys.read_All_Sleep {
            guard let model = notify.object as? TJDSleepModel else {
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
                    bleSelf.aloneGetMeasure(.blood) // 第7步：获取血压历史数据
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "sleep")
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
            wuPrint("收到测试心跳的结果")
            if model.indexOfTotal == model.totalCount {
                let str1 = String.init(format: "heart history complete, total %d line", model.totalCount)
                wuPrint(str1)
                heartArray.sort {
                    $0.timeStamp > $1.timeStamp
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
            }
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3) // 移除Loading
            bleSelf.aloneGetSleep(with: 0) // 第6步：获取历史睡眠信息
            
        }
                
        if notify.name == WristbandNotifyKeys.sysCeLiang_blood {
            guard let  model = notify.object as? BloodModel else {
                return
            }
            dump(model)
            bloodArray.append(model)
            let bloodModel = DBloodModel()
            bloodModel.mac = model.mac
            bloodModel.uuidString = model.uuidString
            bloodModel.min = model.min
            bloodModel.max = model.max
            bloodModel.timeStamp = model.timeStamp
            try? bloodModel.er.save(update: true)
            if model.indexOfTotal == model.totalCount {
                let str1 = String.init(format: "blood history complete, total %d line", model.totalCount)
                wuPrint(str1)
                bloodArray.sort {
                    $0.timeStamp > $1.timeStamp
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
            }
            bleSelf.aloneGetMeasure(.oxygen) // 第8步：获取血氧历史数据
        }
        
        if notify.name == WristbandNotifyKeys.devSendCeLiang_heart {
            measureAsync?.cancel()
            guard let  model = notify.object as? HeartModel else {
                return
            }
            dump(model)
            wuPrint("心跳结束")
            if heartArray.count > 0 {
                heartArray.insert(model, at: 0)
            } else {
                heartArray.append(model)
            }
        }
        if notify.name == WristbandNotifyKeys.devSendCeLiang_blood {
            measureAsync?.cancel()
            guard let  model = notify.object as? BloodModel else {
                return
            }
            dump(model)
            wuPrint("血压结束")
            if bloodArray.count > 0 {
                bloodArray.insert(model, at: 0)
            } else {
                bloodArray.append(model)
            }
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
            try? oxygenModel.er.save(update: true)
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
                }
                oxygenArray.sort {
                    $0.timeStamp > $1.timeStamp
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
                bleSelf.aloneGetStep(with: 0) // 第9步：获取历史步行信息
            }
        }
        if notify.name == WristbandNotifyKeys.devSendCeLiang_oxygen {
            measureAsync?.cancel()
            guard let  model = notify.object as? OxygenModel else {
                return
            }
            dump(model)
            print("血氧结束")
            if oxygenArray.count > 0 {
                oxygenArray.insert(model, at: 0)
            } else {
                oxygenArray.append(model)
            }
        }
        
        if notify.name == WristbandNotifyKeys.setOrRead_Time { // 时间设置成功
            print("时间同步成功")
            bleSelf.getDeviceInfoForWristband() // 第1步：获取设备信息
            bleSelf.getBatteryForWristband()
        }
         
        if notify.name == WristbandNotifyKeys.syncEle { // 电量同步结束后
            print("电量设置成功")
        }
                
        if notify.name == WristbandNotifyKeys.syncLanguage {
            print("语言设置成功")
        }
                
        if notify.name == WristbandNotifyKeys.getDevInfo {
            dump(bleSelf.bleModel)
            dump(bleSelf.funcListModel)
            print("设备信息获取成功")
            bleSelf.getUserinfoForWristband() // 第2步：获取用户信息
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
        }
                
        if notify.name == WristbandNotifyKeys.takePhoto {
            print("takePhoto成功")
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
                    bleSelf.setDialPush(binData, dataIndex: i)
                    usleep(20 * 1000);
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
            if model.hour > 0 || model.minute > 0  {
                alarmArray.append(model)
            }
            if model.clockId == 4 {
                DispatchQueue.main.async { // 返回主线程刷新
                    NotificationCenter.default.post(name: Notification.Name.Alarm, object: nil)
                }
            }
            dump(model)
        }
    }
}

extension BLEManager {
    public func showBLEAlertView() {
        let alertView = UIAlertController(title: "系统提示", message: "请先开启蓝牙，设置 -> 蓝牙", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
            
        }
        let ok = UIAlertAction(title: "确定", style: .default) { (action) in
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
    public func readSleepData(array: [TJDSleepModel]) -> [Int]  {
        let arr = TJDSleepModel.sleepTime(array)
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
    }
}
