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
    var sleepArray: [[SleepModel]] = Array(repeating: [], count: 7)
    var stepArray: [[StepModel]] = Array(repeating: [], count: 7)
    var heartArray: [HeartModel] = []
    var bloodArray: [BloodModel] = []
    var alarmArray: [WUAlarmClock] = [] // 闹钟
    var measureAsync: Async?
    
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
            Toast(text: "蓝牙已打开").show()
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 0)
        }
        
        if notify.name == WUBleManagerNotifyKeys.off {
            Toast(text: "蓝牙未打开").show()
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1)
        }
        
        if notify.name == WUBleManagerNotifyKeys.scan {
            // 如果搜索到设备后，刷新列表
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "scan") // 搜索页面
        }
        
        if notify.name == WUBleManagerNotifyKeys.connected {
            // 将蓝牙对象设置为已绑定，保存蓝牙对象
            print("设备连接成功")
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
            lastestDeviceMac = ""
            UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
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
        
        bleSelf.didSetStartBodyTemperature = { isSuccess in
            if isSuccess {
            }
        }
        
        bleSelf.didSetPowerSwitch = { isSuccess in
            if isSuccess {
            }
        }
        
        bleSelf.didSetTelephoneSMS = { isSuccess in
            if isSuccess {
            }
        }
        
        bleSelf.didSetSleepSetting = { isSuccess in
            if isSuccess {
            }
        }
    }
    
    public func regNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.readyToWrite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.read_Sport, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.read_All_Sport, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.read_Sleep, object: nil)
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
        #if WeiZhongYun
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.powerSwitch, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.telephoneSMS, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.gps_total, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.gps_info, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.gps_detail, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sleep_setting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.body_temperature, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.e_sim, object: nil)
        #endif
        
        #if DisplayPrint
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.sendData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.recieveData, object: nil)
        #endif
    }

    @objc func handleNotify(_ notify: Notification) {
        #if DisplayPrint
        if notify.name == WristbandNotifyKeys.sendData {
            let str = notify.object as! String
            wuPrint("发送的值：\(str)")
        }
        if notify.name == WristbandNotifyKeys.recieveData {
            let str = notify.object as! String
            wuPrint("接收的值：\(str)")
        }
        #endif
                
        if notify.name == WristbandNotifyKeys.readyToWrite {
            wuPrint("可以进行列表上的功能操作了！")
            bleSelf.getDeviceInfoForWristband() // 第1步：获取设备信息
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2)
        }
                
        if notify.name == WristbandNotifyKeys.read_Sport {
            wuPrint("current step：%d", bleSelf.step)
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
            stepArray = Array(repeating: [], count: 7)
            bleSelf.aloneGetStep(with: 0) // 第5步：获取历史步行信息
        }
                
        if notify.name == WristbandNotifyKeys.read_All_Sport {
            let  model = notify.object as! StepModel
            let date = WUDate.dateFromTimeStamp(model.timeStamp)
            let dateStr = date.stringFromYmdHms()
            wuPrint(model.step, dateStr)
            stepArray[model.day] += [model]
            if model.day == 6 {
                if model.totalCount == model.index {
                    print("detail step sync complete", model.day)
                    bleSelf.aloneGetSleep(with: 0) // 第6步：获取历史睡眠信息
                }
            } else {
                if model.totalCount == model.index {
                    print("detail step sync complete", model.day)
                    bleSelf.aloneGetStep(with: model.day + 1)
                }
            }
        }
                
        if notify.name == WristbandNotifyKeys.read_Sleep {
            wuPrint("current sleep：%d", bleSelf.sleep)
        }
        
        if notify.name == WristbandNotifyKeys.read_All_Sleep {
            let model = notify.object as! SleepModel
            dump(model)
            sleepArray[model.day] += [model]
            if model.day == 6 {
                if model.totalCount == model.index {
                    print("detail sleep sync complete", model.day)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "sleep")
                    bleSelf.aloneGetMeasure(.heart) // 第7步：获取心跳历史数据
                }
            } else {
                if model.totalCount == model.index {
                    print("detail sleep sync complete", model.day)
                    bleSelf.aloneGetSleep(with: model.day + 1)
                }
            }
        }
                
        if notify.name == WristbandNotifyKeys.sysCeLiang_heart {
            let  model = notify.object as! HeartModel
            heartArray.append(model)
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
            dump(model)
            wuPrint("收到测试心跳的结果")
            bleSelf.aloneGetMeasure(.blood) // 第8步：获取血压历史数据
            if model.index == model.totalCount {
                let str1 = String.init(format: "heart history complete, total %d line", model.totalCount)
                wuPrint(str1)
            }
        }
                
        if notify.name == WristbandNotifyKeys.sysCeLiang_blood {
            let  model = notify.object as! BloodModel
            dump(model)
            bloodArray.append(model)
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
            if model.index == model.totalCount {
                let str1 = String.init(format: "blood history complete, total %d line", model.totalCount)
                wuPrint(str1)
                NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3) // 移除Loading
            }
        }
        
        if notify.name == WristbandNotifyKeys.devSendCeLiang_heart {
            measureAsync?.cancel()
            let  model = notify.object as! HeartModel
            dump(model)
        }
        if notify.name == WristbandNotifyKeys.devSendCeLiang_blood {
            measureAsync?.cancel()
            let  model = notify.object as! BloodModel
            dump(model)
        }
        
        if notify.name == WristbandNotifyKeys.setOrRead_Time { // 时间设置成功
            bleSelf.getStep(with: 0) // 第4步：获取步数
        }
         
        if notify.name == WristbandNotifyKeys.syncEle { // 电量同步结束后
            
        }
                
        if notify.name == WristbandNotifyKeys.syncLanguage {
            print("语言设置成功")
        }
                
        if notify.name == WristbandNotifyKeys.getDevInfo {
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
            bleSelf.setTimeForWristband() // 第3步：同步时间给设备
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
        #if WeiZhongYun
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
            let model = notify.object as! WUAlarmClock
            if model.weekday > 0 {
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
    public func readSleepData(array: [SleepModel]) -> [Int]  {
        let arr = SleepModel.sleepTime(array)
        let a = SleepTimeModel.detailSleep(arr)
        return a
    }
}
