//
//  JLBlueManager.swift
//  TJDWristbandSDKDemo
//
//  Created by APPLE on 2021/12/16.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit
import JL_BLEKit
import JLDialUnit
import ZipZap
import DFUnits
import TJDWristbandSDK

///杰里单例
public let JLSelf = JLBlueManager.shared

@objcMembers
open class JLBlueManager: NSObject {

    /// Singleton
    public static let shared = JLBlueManager()
    
    open var mAssist = JL_Assist.init()
    open var bt_sdk = JL_RunSDK.sharedMe() as! JL_RunSDK
    open var bt_ble = QCY_BLEApple.init()
    //命令处理中心
    open var mCmdManager = JL_ManagerM.init()
    open var QCY_BLE_LEN_45 :NSInteger = 45
    open var lastUUID : String = ""
    open var mBleName : String = ""
    open var isSaveUUID : Bool = false
    
    open var isForce = false //是否需要强制更新
    
    var watchBinName:String?
    var mWatchName :String?
    var imageName = "bgp_w001"
    
    open var charRcspWrite: CBCharacteristic?
    
    open var charRcspRead: CBCharacteristic?
    
    var downloadData: Data!///OTA数据
    var filePath:String?
    var isStartOTA = false
    var localData: Data!
    var location = 0
    var count = 0
    var otaTimer: Timer?
    var JLProgress: MBProgressHUD!
    var hasNewVersion = false
    var hver = ""
    var sver = ""
    var progressCurrent = Float()
    var jlOtaTimer : Timer?
    var otaTimeout = 0
    
    var flashSize : UInt32 = 0
    var fatsSize : UInt32 = 0
    var realFreeSize : UInt32 = 0
    var isCmdUpdateUI = false
    var dataArray = [Any]()
    var deviceText: String?
    
    var contentDialArray = [String]()
    
    open var JLtotal = 0
    
    open var JLbinData = Data()
    
    open var JLcurrent = 0
    
    typealias JLHandler = (Bool) -> ()
    typealias JLProgressHandler = (Float) -> ()
    var JLPushBlock: JLHandler?
    var JLProgressBlock: JLProgressHandler?
    
    open var JLdialName = ""
    
    var jlOTAPath = ""
    var UpFileName = ""
    var isChecked = false
    
    var isZipData = false
//    DialSelectModel
    var JLmodel = DialModel()
    var threadTimer_0 = JL_Timer.init()
    var threadTimer_1 = JL_Timer.init()
    var battery = 0
    
    func setUpJLinfo()  {
        
        self.mAssist.mNeedPaired = true
        self.mAssist.mPairKey = nil
        self.mAssist.mService = "AE00"
        self.mAssist.mRcsp_W = "AE01"
        self.mAssist.mRcsp_R = "AE02"
        
        bt_ble = bt_sdk.bt_ble
        mAssist = bt_ble.mAssist
        
        mCmdManager = bt_ble.mAssist.mCmdManager
        
        isSaveUUID = true
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WUBleManagerNotifyKeys.on, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WUBleManagerNotifyKeys.off, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.JL_BlueClose, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.JL_didDisconnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.JL_didConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.JL_didDiscoverChar, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.JL_didUpdateNoti, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.JL_didUpdateValueFor, object: nil)
        
    }
    
    @objc func handleNotify(_ notify: Notification) {
        if notify.name == WUBleManagerNotifyKeys.on {
            
            JL_Tools.post(kQCY_BLE_ON, object: 1)
        }
        if notify.name == WUBleManagerNotifyKeys.off {
            
            JL_Tools.post(kQCY_BLE_OFF, object: 0)
        }
        
        if notify.name == WristbandNotifyKeys.JL_BlueClose {
                        
            let central = notify.object as! CBManagerState
            
            self.mAssist.assistUpdate(central)
            
        }
        
        if notify.name == WristbandNotifyKeys.JL_didDisconnectPeripheral {
            
            let peripheral = notify.object as! CBPeripheral
            
            self.mAssist.assistDisconnectPeripheral(peripheral)
            
            JL_Tools.post(kQCY_BLE_DISCONNECTED, object: peripheral)
            
        }
        
        if notify.name == WristbandNotifyKeys.JL_didConnect {

            let peripheral = notify.object as! CBPeripheral
            JL_Tools.post(kQCY_BLE_CONNECTED, object: peripheral)
        }
        
        if notify.name == WristbandNotifyKeys.JL_didDiscoverChar {
               
            let service = notify.userInfo?["service"] as! CBService
            let peripheral = notify.userInfo?["peripheral"] as! CBPeripheral
            
            self.mAssist.assistDiscoverCharacteristics(for: service, peripheral: peripheral)
        }
        
        if notify.name == WristbandNotifyKeys.JL_didUpdateNoti {
            
            let characteristic = notify.userInfo?["characteristic"] as! CBCharacteristic
            let peripheral = notify.userInfo?["peripheral"] as! CBPeripheral
            self.mAssist.assistUpdate(characteristic, peripheral: peripheral) { isPaired in
                if isPaired == true {
                    JL_Tools.setUser(peripheral.identifier.uuidString, forKey: "kUUID_BLE_LAST")
                    JL_Tools.post("kQCY_BLE_PAIRED", object: peripheral)
                    wuPrint("配对成功")
                    if (self.jlOTAPath.count != 0) || (self.downloadData != nil) {
                        NotificationCenter.default.post(name: sysJLOTAComplete, object: nil)
                    }else {
                        NotificationCenter.default.post(name: JLComplete, object: nil)
                    }
                    bleSelf.JLPair = true
                    JL_Tools.delay(0.5) {
                        self.getInfo()
                    }
                    
                } else {
                    bleSelf.JLPair = false
                    bleSelf.disconnectBleDevice()
                    wuPrint("配对失败 ！！")
                }
            }
            
        }
        
        if notify.name == WristbandNotifyKeys.JL_didUpdateValueFor {
            
            let characteristic = notify.object as! CBCharacteristic
            
            self.mAssist.assistUpdateValue(for: characteristic)
            
        }
        
        
    }
    /// 连接设备后进行自检
    func getInfo() {
        
        self.mCmdManager.cmdTargetFeatureResult { status,sn,data   in
            
            let model = self.mCmdManager.outputDeviceModel()
            
            if (status == JL_CMDStatus.success) {
                
                let upst = model.otaStatus
                if upst == JL_OtaStatus.force {
                    wuPrint("进入强制升级")
                    self.isForce = true
                    
                    return
                } else {
                    
                    if model.otaHeadset == JL_OtaHeadset.YES {
                        wuPrint("进入强制升级:OTA另一只耳机")
                        self.isForce = true
                    }
                }
                wuPrint("---> 设备正常使用...")
                JL_Tools.mainTask {
                    /*--- 获取公共信息 ---*/
                    self.mCmdManager.cmdGetSystemInfo(.COMMON, result: nil)
                }
            } else {
                wuPrint("---> ERROR：设备信息获取错误!")
            }
        }
    }
    
    /// 操作杰理设备功能之前，先获取flash
    func getFlashInfo() {
        
//        self.showHud(NSLocalizedString("获取Flash信息...", comment: ""), duration: 30)
        wuPrint("获取Flash信息...")
        
        DialManager.openDialFileSystem(withCmdManager: mCmdManager) { type, progress in
            if (type == DialOperateType.unnecessary) {
//                self.showHud("已经获取过", duration: 1)
                wuPrint("已经获取过")
            }
            if (type == DialOperateType.fail) {
//                self.showHud(NSLocalizedString("获取失败!", comment: ""), duration: 1)
                wuPrint("获取文件列表失败")
            }
            if (type == DialOperateType.success) {
//                self.showHud(NSLocalizedString("获取文件列表...", comment: ""), duration: 30)
                wuPrint("获取文件列表成功...")

            }

            Async.main(after: 0.5) {

                self.hideHud()
            }
        }
        
        
    }
    
    //MARK: 自定义壁纸
    
    func btn_List() {
        self.showHud()
        DialManager.listFile { type, array in
            self.dataArray = array!
            wuPrint("Fats List --->\(self.dataArray)")
            
            JL_Tools.mainTask {
                wuPrint("获取成功!")
                
                self.btn_GetFace()
            }
        }
    }
    // (2)
    func btn_GetFace() {
        
        mCmdManager.mFlashManager.cmdWatchFlashPath(nil, flag: JL_DialSetting.readCurrentDial) { flag, size, path, describe in
            JL_Tools.mainTask { [self] in
                if (flag == 0){
                    
                    wuPrint("当前表盘:\(String(describing: path))")
                    mWatchName = path
                    
                } else {
                    
                    mWatchName = "空"
                }
            }
        }
        
        if (mWatchName?.count == 0 || ((mWatchName?.contains("/null")) != nil)) {
            JL_Tools.mainTask {
                
                self.hideHud()
            }
            return
        }
        
        mCmdManager.mFlashManager.cmdWatchFlashPath(self.mWatchName, flag: JL_DialSetting.getDialName) { flag, size, path, describe in
            
            JL_Tools.mainTask { [self] in
                if (flag == 0){
                    wuPrint("读取背景成功!")
                    wuPrint("当前背景:\(String(describing: path))")
                    let name = path?.last?.uppercased()
                    wuPrint(name as Any)
                    if ((path?.contains("null")) != nil){
                        //                        self.newBgName(self.mWatchName!)
                        watchBinName = imageName
                    } else {
                        watchBinName = name
                    }
                    
                    self.hideHud()
                    
                } else {
                    watchBinName = imageName
                    //                    self.newBgName(self.mWatchName!)
                    self.hideHud()
                }
            }
        }
        
    }
    // 暂时用不上
    func newBgName(_ name:String) {
        let wName = name.replacingOccurrences(of: "/", with: "")
        wuPrint(wName)
        if wName.contains("WATCH"){
            watchBinName = "BGP_W000"
        } else {
            let txt = wName.replacingOccurrences(of: "WATCH", with: "")
            
            let strLen = txt.count
            if (strLen == 1) {
                watchBinName = "BGP_W00" + txt
            }
            if (strLen == 2) {
                watchBinName = "BGP_W0" + txt
            }
            if (strLen == 3) {
                watchBinName = "BGP_W" + txt
            }
        }
    }
    
    // (3)
    func getInfoList() {
        
        JL_Tools.delay(1) {
            if self.dataArray.contains(where: { ($0 as AnyObject).caseInsensitiveCompare(self.watchBinName!) == .orderedSame }) {
                
                //更新自定义图
                self.replaceCustomWatch()
            } else {
                //增加自定义图片
                self.addCustomWatch()
                
            }
        }
        
    }
    //更新自定义图
    func replaceCustomWatch() {
        let wName = "/" + watchBinName!
        let binPath = JL_Tools.listPath(.libraryDirectory, middlePath: "", file: watchBinName!)
        //        let pathData = NSData.init(contentsOfFile: binPath)
        //        let binPath = JL_Tools.listPath(.documentDirectory, middlePath: "", file: imageName)
        
        let pathData = NSData.init(contentsOfFile: binPath)
        wuPrint("自定义表盘-->创建的文件大小:",pathData?.length as Any)
        
        DialManager.repaceFile(wName, content: pathData! as Data) { type, progress in
            if (type == DialOperateType.noSpace) {
                wuPrint("空间不足")
            }
            if (type == DialOperateType.doing) {
                
                
                wuPrint("--->表盘推送进度:\(progress*100.0)")
                self.JLcurrent = Int(progress*100.0)
                JLSelf.JLProgressBlock?(progress)
                
            }
            if (type == DialOperateType.fail) {
                wuPrint("更新失败")
            }
            if (type == DialOperateType.success) {
                wuPrint("更新完成")
                
                self.activeCustomWatch()
            }
        }
        
    }
    func addCustomWatch() {
        let wName = "/" + watchBinName!
        let binPath = JL_Tools.listPath(.libraryDirectory, middlePath: "", file: watchBinName!)
        //        let pathData = NSData.init(contentsOfFile: binPath)
        //        let binPath = JL_Tools.listPath(.documentDirectory, middlePath: "", file: imageName)
        
        let pathData = NSData.init(contentsOfFile: binPath)
        wuPrint("自定义表盘-->创建的文件大小:",pathData?.length as Any)
        
        DialManager.addFile(wName, content: pathData! as Data) { type, progress in
            
            if (type == DialOperateType.noSpace) {
                wuPrint("空间不足")
            }
            if (type == DialOperateType.doing) {
                
                
                wuPrint("--->添加进度:\(progress*100.0)")
                self.JLcurrent = Int(progress*100.0)
                JLSelf.JLProgressBlock?(progress)
                
            }
            if (type == DialOperateType.fail) {
                wuPrint("添加失败")
            }
            if (type == DialOperateType.success) {
                wuPrint("添加完成")
                
                /*--- 更新缓存 ---*/
                self.activeCustomWatch()//设置自定义表盘
            }
        }
        
    }
    
    //设置自定义表盘
    func activeCustomWatch() {
        
        let wName = "/" + watchBinName!
        mCmdManager.mFlashManager.cmdWatchFlashPath(wName, flag: JL_DialSetting.activateCustomDial) { flag, size, path, describe in
            
            JL_Tools.mainTask {
                if (flag == 0) {
                    
                    wuPrint("背景:\(self.watchBinName!)")
                    
                    Async.main {
                        //                        self.canHide = true
                        //                        bleSelf.imagePushBlock = nil
                        self.showHud(NSLocalizedString("自定义表盘成功", comment: ""), duration: 1)
                        //                        self.pressBtn(self.bgBtn)
                        self.JLPushBlock?(true)
                    }
                } else {
                    self.showHud(NSLocalizedString("自定义表盘失败", comment: ""), duration: 1)
                    //                    self.pressBtn(self.bgBtn)
                    self.JLPushBlock?(false)
                }
            }
        }
    }
    // MARK: - 自定义壁纸数据转换
    @discardableResult
    func getJLDataFromImage(image:UIImage) -> Data {
        let cha = ChangeImageData.init()
        
        var dev_w = bleSelf.bleModel.screenWidth//jlModel.flashInfo.mScreenWidth
        var dev_h = bleSelf.bleModel.screenHeight//jlModel.flashInfo.mScreenHeight
        if (dev_w == 0){
            dev_w = 240
        }
        if (dev_h == 0){
            dev_h = 240
        }
        var cgsize = CGSize.init()
        cgsize.width = CGFloat(dev_w)
        cgsize.height = CGFloat(dev_h)
        let imageData = BitmapTool.resize(image, andResizeTo: cgsize)
        cha.changeImage(toBin: imageData, and: JLSelf.mCmdManager)
        
        return imageData
    }
    
    //MARK: 表盘推送
    
    //获取当前表盘列表
    func btn_list() {
        
        DialManager.listFile { type, array in
            self.dataArray = array!
            wuPrint("Fats List --->\(self.dataArray)")
            //获取到了数组，超过 watch100的加入数组中
            self.contentDialArray.removeAll()
            for i in self.dataArray {
                
                if !(i as! String).hasPrefix("."){
                    if ((i as! String).hasPrefix("WATCH")&&(i as! String).count >= 8 ) || (i as! String).hasPrefix("WH"){
                        
                        self.contentDialArray.append(i as! String)
                    }
                }
            }
            
            Async.main(after: 0.5) {
                
                JL_Tools.mainTask { [self] in
                    //如果有配对的名称 直接设置 没有新增
                    //                let nameString = "WATCH" + "44"//self.model.dialName
                    
                    if self.dataArray.contains(where: { ($0 as AnyObject).caseInsensitiveCompare(self.JLdialName) == .orderedSame }) {
                        self.btn_SetFace(isRemove: false)
                        
                    } else {
                        //设置bindata推送
                        self.jl_getFace()
                        
                    }
                }
            }
        }
    }
    func jl_getFace() {
        
        mCmdManager.mFlashManager.cmdWatchFlashPath(nil, flag: JL_DialSetting.readCurrentDial) { flag, size, path, describe in
            JL_Tools.mainTask {
                if (flag == 0) {
                    wuPrint("当前表盘:\(path!)") //当前没有表盘崩溃
                    self.jl_addfile()
                    
                }else {
                    wuPrint("获取表盘失败")
                }
            }
        }
    }
    //增加文件
    func jl_addfile() {
        
        self.showHudForever()
        
        let path = "/" + JLdialName
        wuPrint("-->创建的文件大小\(JLbinData.count)")
        self.JLtotal = self.JLbinData.count
        DialManager.addFile(path, content: self.JLbinData) { type, progressess in
            
            if (type == .noSpace) {
                //                self.showHud("空间不足~", duration: 0.5)
                
            }
            if (type == .fail) {
                
                self.showHud(NSLocalizedString("创建文件失败！", comment: ""), duration: 1)
                wuPrint("创建文件失败！")
            }
            if (type == .doing) {
                
                
                
                wuPrint("--->表盘推送进度:\(progressess*100.0)")
                self.JLcurrent = Int(progressess*100.0)
                JLSelf.JLProgressBlock?(progressess)
                
            }
            if (type == .success) {
                
                self.showHud(NSLocalizedString("创建文件成功！", comment: ""), duration: 1)
                //成功之后 获取数组中是否包含超过watch100以后的表盘 选择最前一个删除 1-8修改逻辑
                
                //                if self.contentDialArray.count > 0{
                //                    self.btn_Remove()
                //                } else {
                //                    // 直接设置表盘
                //                    self.btn_SetFace()
                //                }
                // 直接设置表盘
                self.btn_SetFace(isRemove: true)
            }
        }
    }
    
    //设置表盘
    func btn_SetFace(isRemove :Bool) {
        let path = "/" + JLdialName
        wuPrint("表盘的名字:\(path)")
        mCmdManager.mFlashManager.cmdWatchFlashPath(path, flag: JL_DialSetting.setDial) { flag, size, path, describe in
            JL_Tools.mainTask {
                if (flag != 0) {
                    
                    self.showHud(NSLocalizedString("设置表盘失败~", comment: ""), duration: 1)
                    wuPrint("设置表盘失败~")
                    //                    self.canHide = true
                    //                    self.pressBtn(self.bgBtn)
                    self.JLPushBlock?(false)
                } else {
                    self.showHud(NSLocalizedString("设置表盘成功!", comment: ""), duration: 1)
                    
                    wuPrint("设置表盘成功!")
                    //                    self.canHide = true
                    //                    self.pressBtn(self.bgBtn)
                    self.JLPushBlock?(true)
                    //成功
                    if self.contentDialArray.count > 0{
                        if isRemove {
                            self.btn_Remove()
                        }
                        
                    }
                    
                }
                
            }
        }
    }
    //删除表盘
    func btn_Remove() {
        self.showHudForever()
        
        let stringA = self.contentDialArray.first!
        
        self.deviceText = "/" + stringA
        
        wuPrint("删除的表盘是:\(String(describing: self.deviceText))")
        
        DialManager.deleteFile(self.deviceText ?? "") { type, progress in
            //
            
            if type == .fail {
                wuPrint("删除失败")
                
                JL_Tools.mainTask {
                    
                    self.hideHud()
                }
                
            }
            if type == .success {
                JL_Tools.mainTask {
                    
                    self.hideHud()
                }
                wuPrint("删除的表盘是:\(String(describing: self.deviceText))")
                wuPrint("删除成功")
            }
        }
    }
    
    //MARK: OTA
    func OTAbtn_list() {
        
        DialManager.listFile { type, array in
            
            if array != nil {
                self.dataArray = array ?? [Any]()
            }
            
            wuPrint("Fats List --->\(self.dataArray)")
            
            Async.main(after: 0.5) {
                
                self.hideHud()
            }
        }
    }
    
    func info_check() {
        
        mCmdManager.cmdTargetFeatureResult { status,sn,data   in
            
            var model = JLModel_Device.init()
            model = self.mCmdManager.outputDeviceModel()
            
            if (status == JL_CMDStatus.success) {
                
                let upst = model.otaStatus
                if upst == JL_OtaStatus.force{
                    wuPrint("进入强制升级")
                    
                    if let window = getKeyWindow() {
                        
                        self.JLProgress = MBProgressHUD.showAdded(to: window, animated: true)
                        self.JLProgress.mode = .determinate
                        self.JLProgress.backgroundView.style = MBProgressHUDBackgroundStyle.solidColor
                        self.JLProgress.backgroundView.color = UIColor.black.withAlphaComponent(0.35)
                        self.JLProgress.label.text = String.init(format: "%.1f%%", self.JLProgress.progress * 100)
                        
                        if self.isZipData == true {
                            self.JLOTAUpdateZipSource()
                            
                        } else {
                            
                            if self.downloadData != nil {
                                
                                self.JLOTAUpdate()
                            }else {
                                wuPrint("无可升级的ufw文件")
                                self.showHud("无可升级的ufw文件", duration: 1)
                            }
                        }
                        return
                        
                    }
                    
                    
                } else {
                    
                    if model.otaHeadset == JL_OtaHeadset.YES {
                        wuPrint("进入强制升级:OTA另一只耳机")
                        
                    }
                }
                wuPrint("---> 设备正常使用...")
                JL_Tools.mainTask {
                    /*--- 获取公共信息 ---*/
                    self.mCmdManager.cmdGetSystemInfo(.COMMON, result: nil)
                }
            } else {
                wuPrint("---> ERROR：设备信息获取错误!")
            }
            
        }
        
    }
    func JLOTAUpdateForZipResource() {
        
        JL_Tools.subTask {
            
            /*--- 更新资源标志 ---*/
            self.mCmdManager.mFlashManager.cmdWatchUpdateResource()
            /*--- 展示手表更新资源UI ---*/
            wuPrint("--->Fats Update UI.(OTA)")
            
            var m_flag = UInt8(0)
            self.mCmdManager.mFlashManager.cmdUpdateResourceFlash(JL_FlashOperateFlag.start) { flag in
                m_flag = flag
            }
            
            if (m_flag != 0) {
                JL_Tools.mainTask {
                    wuPrint("---> 升级请求失败!")
                    return
                }
            }
            
            
            wuPrint("self.filePath:\(self.jlOTAPath)")
            DialManager.updateResourcePath(self.jlOTAPath, list: self.dataArray) { updateResult, array, index, progress in
                
                JL_Tools.mainTask {
                    if (updateResult == .replace) {
                        //资源替换
                        let fileName = array![index]
                        let txt = "\(fileName)" + "\(index+1)" + "/" + "\(array?.count ?? 0)"
                        self.JLProgress.progress = progress
                        self.JLProgress.label.text = NSLocalizedString("正在更新表盘:", comment: "") + txt + " " + String.init(format: "%.1f%%", progress * 100)
                        wuPrint("\(txt)")
                        return
                        
                    }
                    if (updateResult == .add) {
                        //资源新增
                        let fileName = array![index]
                        let txt = "正在传输新表盘:\(fileName)" + "\(index+1)" + "/" + "\(array?.count ?? 0)"
                        self.JLProgress.progress = progress
                        self.JLProgress.label.text = NSLocalizedString("正在传输新表盘:", comment: "") + txt + " " + String.init(format: "%.1f%%", progress * 100)
                        wuPrint("\(txt)")
                        return
                    }
                    if (updateResult == .finished) {
                        wuPrint("资源更新完成")
                    }
                    if (updateResult == .newest) {
                        wuPrint("资源已是最新")
                    }
                    if (updateResult == .invalid) {
                        wuPrint("无效资源文件")
                    }
                    if (updateResult == .empty) {
                        wuPrint("资源文件为空")
                    }
                    if (updateResult == .noSpace) {
                        wuPrint("设备空间不足")
                    }
                    
                    JL_Tools.delay(1.0) {
                        self.JLOTAUpdateZipSource()
                    }
                    
                }
                
            }
            
        }
        
    }
    func JLOTAUpdateZipSource() {
        
        let zipName = UpFileName.replacingOccurrences(of: ".zip", with: "")
        
        let zipPath = JL_Tools.listPath(.documentDirectory, middlePath: zipName, file: "")
        
        wuPrint("zipName:\(zipName)")
        
        let zipArr = JL_Tools.subPaths(zipPath)
        
        var otaName : String?
        for name in zipArr {
            if (name as AnyObject).hasSuffix(".ufw") {
                otaName = (name as! String)
                break
            }
        }
        
        if otaName == nil {
            wuPrint("未找到OTA升级文件~")
            
            self.showHud(NSLocalizedString("未找到OTA升级文件", comment: ""), duration: 1)
            return
        }
        
        
        let otaPath = JL_Tools.listPath(.documentDirectory, middlePath: zipName, file: otaName ?? "")
        
        let otaData = NSData.init(contentsOfFile:otaPath)
        
        wuPrint("otaPath:\(otaData!)")
        
        self.downloadData = otaData as Data?
        
        self.count = otaData!.length
        
        
        self.jlOtaTimeCheck()
        /*--- 开始OTA升级 ---*/
        
        mCmdManager.mOTAManager.cmdOTAData(otaData! as Data) { result, progress in
            JL_Tools.mainTask {
                if result == .preparing || result == .upgrading {
                    self.jlOtaTimeCheck()
                    if result == .upgrading {
                        wuPrint("---> 正在升级：\(progress*100.0)")
                        //                        self.JLProgress.showHud()
                        self.JLProgress.progress = Float(progress*100.0)/Float(self.count)
                        self.JLProgress.label.text = String.init(format: "%.1f%%", progress * 100)
                        
                    }
                    if result == .preparing {
                        wuPrint("---> 检验文件：\(progress*100.0)")
                        //                        self.JLProgress.showHud()
                        self.JLProgress.progress = Float(progress*100.0)/Float(self.count)
                        self.JLProgress.label.text = String.init(format: "%.1f%%", progress * 100)
                        
                    }
                }
                if result == .prepared {
                    self.jlOtaTimeCheck()
                    wuPrint("---> 等待升级...")
                }
                if result == .reconnect {
                    self.jlOtaTimeCheck()
                    
                    bleSelf.reConnectDevice()
                }
                if result == .success || result == .reboot {
                    wuPrint("OTA成功")
                    self.JLProgress.hide(animated: true)
                    self.JLProgress.progress = 0
                    
                    self.showHud(NSLocalizedString("升级成功!", comment: ""))
                    self.showHud(NSLocalizedString("如不能连接,请到蓝牙设置中手动忽略设备后重新连接设备!", comment: ""), duration: 1)
                    self.isChecked = false
                }
                if result == .fail {
                    wuPrint("OTA失败")
                    self.info_check()
                    self.showHud(NSLocalizedString("升级失败!", comment: ""))
                }
                if result == .dataIsNull {
                    self.showHud(NSLocalizedString("OTA升级数据为空!", comment: ""))
                }
                if result == .seekFail {
                    self.showHud(NSLocalizedString("OTA指令失败!", comment: ""))
                }
                if result == .infoFail {
                    self.showHud(NSLocalizedString("OTA升级固件信息错误!", comment: ""))
                }
                if result == .lowPower {
                    self.showHud(NSLocalizedString("OTA升级设备电压低!", comment: ""))
                }
                if result == .enterFail {
                    self.showHud(NSLocalizedString("未能进入OTA升级模式!", comment: ""))
                }
                if result == .unknown {
                    self.showHud(NSLocalizedString("OTA未知错误!", comment: ""))
                }
                if result == .failSameVersion {
                    self.showHud(NSLocalizedString("升级版本相同~", comment: ""))
                }
                if result == .failTWSDisconnect {
                    self.showHud(NSLocalizedString("TWS耳机未连接~", comment: ""))
                }
                if result == .failNotInBin {
                    self.showHud(NSLocalizedString("耳机未在充电仓~", comment: ""))
                }
            }
            
        }
    }
    func JLOTAUpdate() {
        
        wuPrint("self.downloadData:\(self.downloadData!.count)")
        
        self.count = self.downloadData.count
        
        //        self.jlOtaTimeCheck()
        /*--- 开始OTA升级 ---*/
        
        mCmdManager.mOTAManager.cmdOTAData(self.downloadData! as Data) { result, progress in
            JL_Tools.mainTask {
                if result == .preparing || result == .upgrading {
                    self.jlOtaTimeCheck()
                    if result == .upgrading {
                        wuPrint("---> 正在升级：\(progress*100.0)")
                        //                        self.JLProgress.showHud()
                        self.JLProgress.progress = Float(progress*100.0)/Float(self.count)
                        self.JLProgress.label.text = String.init(format: "%.1f%%", progress * 100)
                        
                        
                    }
                    if result == .preparing {
                        wuPrint("---> 检验文件：\(progress*100.0)")
                        //                        self.JLProgress.showHud()
                        self.JLProgress.progress = Float(progress*100.0)/Float(self.count)
                        self.JLProgress.label.text = String.init(format: "%.1f%%", progress * 100)
                        
                    }
                }
                if result == .prepared {
                    self.jlOtaTimeCheck()
                    wuPrint("---> 等待升级...")
                }
                if result == .reconnect {
                    self.jlOtaTimeCheck()
                    
                    bleSelf.reConnectDevice()
                }
                if result == .success || result == .reboot {
                    wuPrint("OTA成功")
                    self.JLProgress.hide(animated: true)
                    self.JLProgress.progress = 0
                    
                    self.showHud(NSLocalizedString("升级成功!", comment: ""))
                    self.showHud(NSLocalizedString("如不能连接,请到蓝牙设置中手动忽略设备后重新连接设备!", comment: ""), duration: 1)
                    self.hasNewVersion = false
                    self.isChecked = false
                    
                }
                if result == .fail {
                    
                    wuPrint("OTA失败")
                    self.showHud(NSLocalizedString("升级失败!", comment: ""))
                }
                if result == .dataIsNull {
                    
                    self.showHud(NSLocalizedString("OTA升级数据为空!", comment: ""))
                }
                if result == .seekFail {
                    
                    self.showHud(NSLocalizedString("OTA指令失败!", comment: ""))
                }
                if result == .infoFail {
                    
                    self.showHud(NSLocalizedString("OTA升级固件信息错误!", comment: ""))
                }
                if result == .lowPower {
                    self.showHud(NSLocalizedString("OTA升级设备电压低!", comment: ""))
                }
                if result == .enterFail {
                    self.jlOtaTimeCheck()
                    self.showHud(NSLocalizedString("未能进入OTA升级模式!", comment: ""))
                }
                if result == .unknown {
                    
                    self.showHud(NSLocalizedString("OTA未知错误!", comment: ""))
                }
                if result == .failSameVersion {
                    self.showHud(NSLocalizedString("升级版本相同~", comment: ""))
                }
                if result == .failTWSDisconnect {
                    self.showHud(NSLocalizedString("TWS耳机未连接~", comment: ""))
                }
                if result == .failNotInBin {
                    self.showHud(NSLocalizedString("耳机未在充电仓~", comment: ""))
                }
            }
            
        }
    }
    
    func jlOtaTimeCheck() {
        otaTimeout = 0
        if jlOtaTimer == nil {
            jlOtaTimer = JL_Tools.timingStart(#selector(otaTimeAdd), target: self, time: 1.0)
        }
    }
    @objc func otaTimeClose() {
        JL_Tools.timingStop(jlOtaTimer!)
        
        otaTimeout = 0
        jlOtaTimer = nil
    }
    
    @objc func otaTimeAdd() {
        otaTimeout += 1
        if otaTimeout == 30 {
            self.otaTimeClose()
            wuPrint("OTA ---> 超时了！！！")
            self.JLProgress.hide(animated: true)
            self.JLProgress.progress = 0
            //            self.showHud(NSLocalizedString("OTA ---> 超时了!", comment: ""))
        }
    }
    
    //MARK: 联系人推送
    func getContact() {
        
        self.showHudForever()
        let cha = ChangeImageData.init()
        cha.getContact(self.mCmdManager)
        
        /*
        let mData = NSMutableData.init()
        
        let deviceModel = mCmdManager.outputDeviceModel() as JLModel_Device?
        
        if (deviceModel!.smallFileWayType == JL_SmallFileWayType.NO){
            /*--- 原来通讯流程 ---*/
            
            mCmdManager.mFileManager.setCurrentFileHandleType(JLFileTransferHelper.getContactTargetDev(deviceModel!))
            mCmdManager.mFileManager.cmdFileReadContent(withName: "CALL.txt") { result, size, data, progress in
                if (result == JL_FileContentResult.start) {
                    wuPrint("---> 读取【Call.txt】开始.")
                } else if (result == JL_FileContentResult.reading){
                    wuPrint("---> 读取【Call.txt】Reading.")
                    if (data!.count > 0) {
                        mData.append(data!)
                    }
                }else if (result == JL_FileContentResult.end){
                    wuPrint("---> 读取【Call.txt】结束")
                    if (mData == nil || mData.count < 40) {
                        return
                    }
                    
                    JL_Tools.mainTask {
                        cha.outputContactsListData(mData as Data)
                        self.hideHud()
                    }
                }
            }
            
        } else {
            /*--- 查询小文件列表 ---*/
            wuPrint("查询小文件列表")
            JL_Tools.subTask {
                var smallFile = nil as JLModel_SmallFile?
                self.mCmdManager.mSmallFileManager.cmdSmallFileQueryType(JL_SmallFileType.contacts) { array in
                    
                    if (array!.count > 0) {
                        smallFile = array![0]
                        self.threadTimer_0.threadContinue()
                    }
                }
                self.threadTimer_0.threadWait()
                if smallFile == nil {
                    JL_Tools.mainTask {
                        
                        self.hideHud()
                    }
                    
                    return
                }
                /*--- 读取小文件通讯录 ---*/
                self.mCmdManager.mSmallFileManager.cmdSmallFileRead(smallFile!) { status, progress, data in
                    
                    if (status == JL_SmallFileOperate.doing) {
                        wuPrint("---> 小文件读取【Call.txt】开始")
                    }
                    if (status != JL_SmallFileOperate.doing && status != JL_SmallFileOperate.suceess) {
                        wuPrint("---> 小文件读取【Call.txt】失败~")
                    }
                    if (data!.count > 0) {
                        mData.append(data!)
                    }
                    if (status == JL_SmallFileOperate.suceess) {
                        wuPrint("---> 小文件读取【Call.txt】成功!")
                        if mData.count >= 40 {
                            JL_Tools.mainTask {
                                cha.outputContactsListData(mData as Data)
                                self.hideHud()
                            }
                        }
                    }
                }
            }
        }
        */
    }
    
    func syncContactsListToDevice() {
        
        
        let deviceModel = mCmdManager.outputDeviceModel() as JLModel_Device?
        //documentDirectory  libraryDirectory
        let path = JL_Tools.create(on: .libraryDirectory, middlePath: "", file: "CALL.TXT")
        
        wuPrint("联系人array:\(JLmodel.jlArray.count)")
        var model = PersonModel.init()
        for i in 0..<JLmodel.jlArray.count {
            
            model = JLmodel.jlArray[i] as! PersonModel
            wuPrint(model.fullName)
            wuPrint(model.phoneNum)
        }
        
        JL_Tools.write(ContactsTool.setContactsToData(JLmodel.jlArray), fillFile: path)
        
        
        if (deviceModel!.smallFileWayType == JL_SmallFileWayType.NO){
            /*--- 原来通讯流程 ---*/
            if (JLFileTransferHelper.getContactTargetDev(deviceModel!) == .FLASH2){
                JLFileTransferHelper.sendContactFileToFlash(withFileName: "CALL.TXT", withManager: mCmdManager) { type, progress in
                    if (type == .start) {
                        wuPrint("同步中")
                    }
                    if (type == .success) {
                        wuPrint("传输成功")
                        
                    }
                }
            } else {
                JLFileTransferHelper.sendContactFile(withFileName: "CALL.TXT", withManager: mCmdManager) { type, progress in
                    if (type == .start) {
                        wuPrint("同步中")
                    }
                    if (type == .success) {
                        wuPrint("传输成功")
                        
                    }
                }
            }
        } else {
            /*--- 小文件方式传输通讯录 ---*/
            wuPrint("小文件方式传输通讯录")
            let cha = ChangeImageData.init()
            cha.smallFileSyncContactsList(withPath: path, and: mCmdManager)
            JL_Tools.subTask {
                
                cha.status =  { (str) in
                    if str == "1" {
                        self.JLPushBlock?(true)
//                        bleSelf.imagePushBlock = nil
                        self.showHud((NSLocalizedString("推送成功", comment: "")), duration: 1.0)
                        
                    } else {
                        self.JLPushBlock?(false)
                        wuPrint("传输失败")
                        self.showHud((NSLocalizedString("推送失败", comment: "")), duration: 1.0)
                    }
                    
                }
                
            }
            //            self.smallFileSyncContactsListWithPath(path)
            
        }
        
    }
    
    func smallFileSyncContactsListWithPath(_ path:String) {
        wuPrint("通讯录路径:\(path)")
        
        JL_Tools.subTask { [self] in
            
            var smallFile:JLModel_SmallFile? = nil
            //        --- 查询小文件列表 ---
            
            mCmdManager.mSmallFileManager.cmdSmallFileQueryType(JL_SmallFileType.contacts) { [self] array in
                wuPrint("进入查询小文件列表")
                wuPrint(array!.count)
                wuPrint(array as Any)
                if (array!.count > 0) {
                    smallFile = array![0]
                    self.threadTimer_1.threadContinue()
                    
                    wuPrint(smallFile as Any)
                } else {
                    //手表没有联系人的时候，读取到空，继续下发命令
                    /*--- 小文件传输文件 ---*/
                    wuPrint(smallFile as Any)
                    let pathData = NSData.init(contentsOfFile: path)
                    
                    mCmdManager.mSmallFileManager.cmdSmallFileNew(pathData! as Data, type: .contacts) { status, progress, fileID in
                        
                        JL_Tools.mainTask {
                            if (status == JL_SmallFileOperate.suceess) {
                                wuPrint("传输成功 同步成功")
                                //                        self.canHide = true
                                //                        self.pressBtn(self.bgBtn)
                                self.JLPushBlock?(true)
//                                bleSelf.imagePushBlock = nil
                                self.showHud((NSLocalizedString("推送成功", comment: "")), duration: 1.0)
                                
                            }
                            if (status != JL_SmallFileOperate.suceess && status != JL_SmallFileOperate.doing) {
                                self.JLPushBlock?(false)
                                wuPrint("传输失败")
                                
                            }
                            
                        }
                    }
                }
                
                
            }
            
            self.threadTimer_1.threadWait()
            
            /*--- 先删通讯录 ---*/
            if (smallFile.hashValue != 0) {
                var status_del = JL_SmallFileOperate.init(rawValue: 0)
                
                let newSmallFile = smallFile ?? JLModel_SmallFile()
                
                mCmdManager.mSmallFileManager.cmdSmallFileDelete(newSmallFile) { status in
                    status_del = status
                    self.threadTimer_1.threadContinue()
                }
                self.threadTimer_1.threadWait()
                if (status_del != .suceess) {
                    wuPrint("--->小文件 CALL.TXT 传输失败")
                    return
                }
            }
            
            /*--- 小文件传输文件 ---*/
            
            let pathData = NSData.init(contentsOfFile: path)
            
            mCmdManager.mSmallFileManager.cmdSmallFileNew(pathData! as Data, type: .contacts) { status, progress, fileID in
                
                JL_Tools.mainTask {
                    if (status == JL_SmallFileOperate.suceess) {
                        wuPrint("传输成功 同步成功")
                        //                        self.canHide = true
                        //                        self.pressBtn(self.bgBtn)
                        self.JLPushBlock?(true)
//                        bleSelf.imagePushBlock = nil
                        self.showHud((NSLocalizedString("推送成功", comment: "")), duration: 1.0)
                    }
                    if (status != JL_SmallFileOperate.suceess && status != JL_SmallFileOperate.doing) {
                        self.JLPushBlock?(false)
                        wuPrint("传输失败")
                    }
                    
                }
            }
            
        }
        
    }
}
