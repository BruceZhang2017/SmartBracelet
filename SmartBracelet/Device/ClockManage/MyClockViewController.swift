//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MyClockViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//

import UIKit
import Then
import Toaster
import TJDWristbandSDK
import ABParTool

var needStop = false

typealias imgBlock = () ->()

class MyClockViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var imagePickerVc: TZImagePickerController?
    var imageUploadVc: UploadImageViewController?
    var index = 0
    var datetimeLocation = 0  ///时间上方0 时间下方1
    var datetimeTopLocation = 0 ///关闭0 日期1 睡眠2 心率3 计步4
    var datetimeBottomLocation = 0 ///关闭0 日期1 睡眠2 心率3 计步4
    var colorIndex = 0 ///白色0 黑色1 黄色2 橙色3 粉色4 紫色5 蓝色6 青色7
    var diallocation = 5
    final let locations = ["above".localized(), "below".localized()]
    final let xgztlocations = ["mine_null".localized(), "position_top_left".localized(), "position_bottom_left".localized(), "position_top_right".localized(), "position_bottom_right".localized(), "position_center".localized()]
    final let tops = ["closure".localized(), "date".localized(), "sleep".localized(), "heart_rate".localized(), "step".localized()]
    var topTap = false
    final var colors: [UIColor] = [UIColor.white, UIColor.black, UIColor.yellow,
                             UIColor(red: 232/255.0, green: 149/255.0, blue: 102/255.0, alpha: 1),
                             UIColor(red: 229/255.0, green: 120/255.0, blue: 131/255.0, alpha: 1),
                             UIColor(red: 171/255.0, green: 140/255.0, blue: 218/255.0, alpha: 1),
                             UIColor(red: 121/255.0, green: 168/255.0, blue: 232/255.0, alpha: 1),
                             UIColor(red: 154/255.0, green: 227/255.0, blue: 224/255.0, alpha: 1),
                             UIColor(red: 155/255.0, green: 226/255.0, blue: 163/255.0, alpha: 1)]
    var itemVC: SelectItemViewController?
    var width: CGFloat = 164
    var height: CGFloat = 0
    var binData = Data()
    var current = 0
    var total = 0
    var currentImage: UIImage?
    var currentPackage = 0
    var footView: CustomImageFooterView?
    var packageNum = 0
    var imageScale: CGFloat = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        let deviceMetrics = AppDelegate.resolvedDeviceScreenMetrics()
        let w: CGFloat = CGFloat(deviceMetrics?.width ?? 240)
        let h: CGFloat = CGFloat(deviceMetrics?.height ?? 240)
        if w == 80 {
            self.view.bg_base1()
            self.edgesForExtendedLayout = .all
        }
        
        title = "custom_watch_face".localized()
        
        if isXGZT {
            
        } else {
            datetimeLocation = bleSelf.dialSelectModel.timeDirection
            datetimeTopLocation = bleSelf.dialSelectModel.onTheTime
            datetimeBottomLocation = bleSelf.dialSelectModel.belowTheTime
            colorIndex = bleSelf.dialSelectModel.textColor
        }
        
        //去掉没有数据显示部分多余的分隔线
        tableView.tableFooterView =  UIView.init(frame: CGRect.zero)
        
        //壁纸推送
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.startImagePush, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.imagePush, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifyXGZT(_:)), name: NSNotification.Name("MyClockViewController"), object: nil)
        
        footView = CustomImageFooterView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 160))
        tableView.tableFooterView = footView
        
        
        footView?.isHidden = !(w == 80 && h == 160)
        if isXGZT {
            footView?.isHidden = true 
        }
        footView?.delegate = self
        bleSelf.getFuncCategory()
        
        if let metrics = deviceMetrics, metrics.isRect {
            height = CGFloat(width) * CGFloat(metrics.height) / CGFloat(metrics.width)
        } else { // 圆形
            height =  width
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent || isBeingDismissed {
            teardownTransientControllersForRelease()
        }
    }
    
    deinit {
        needStop = true
        XLogger.shared.log("壁纸推送暂停")
        NotificationCenter.default.removeObserver(self)
        binData = Data()
        releaseTransientControllerReferences()
    }

    private func teardownTransientControllersForRelease() {
        dismissItemController()
        dismissImageUploadController()
    }

    private func releaseTransientControllerReferences() {
        itemVC?.delegate = nil
        imageUploadVc?.delegate = nil
        itemVC = nil
        imageUploadVc = nil
    }

    private func dismissItemController() {
        let itemController = itemVC
        itemController?.delegate = nil
        itemVC = nil
        itemController?.dismiss(animated: false, completion: nil)
    }

    private func dismissImageUploadController() {
        let uploadController = imageUploadVc
        uploadController?.delegate = nil
        imageUploadVc = nil
        uploadController?.dismiss(animated: false, completion: nil)
    }

    private func refreshUploadProgress(_ progress: String) {
        imageUploadVc?.refreshProgress(p: progress)
    }

    private func resolvedDeviceMetrics() -> (width: Int, height: Int, isRect: Bool) {
        AppDelegate.resolvedDeviceScreenMetrics() ?? (240, 240, false)
    }

    private func resolvedDeviceSize() -> CGSize {
        let metrics = resolvedDeviceMetrics()
        return CGSize(width: metrics.width, height: metrics.height)
    }

    private func resolvedMaskRadius(for image: UIImage) -> CGFloat {
        let metrics = resolvedDeviceMetrics()
        if metrics.isRect {
            return 0
        }
        let referenceHeight = CGFloat(max(metrics.height, Int(min(image.size.width, image.size.height))))
        return max(referenceHeight / 2, 1)
    }
    
    // 修改自定义设置内容位置
    private func modifyCustomDialSettings() {
        if isXGZT {
            XGZTCommand.setTimePositionAndColor(type: 2, position: diallocation, color: colorIndex)
            return
        }
        
        ///时间上方0 时间下方1
        bleSelf.dialSelectModel.timeDirection = datetimeLocation
        
        ///关闭0 日期1 睡眠2 心率3 计步4
        bleSelf.dialSelectModel.onTheTime = datetimeTopLocation
        
        ///关闭0 日期1 睡眠2 心率3 计步4
        bleSelf.dialSelectModel.belowTheTime = datetimeBottomLocation
        
        ///白色0 黑色1 黄色2 橙色3 粉色4 紫色5 蓝色6 青色7
        bleSelf.dialSelectModel.textColor = colorIndex
        
        bleSelf.setImagePushSettings(bleSelf.dialSelectModel)
        DialSelectModel.setModel(bleSelf.dialSelectModel)
    }
    
    private func startupdateCustomImage() {
        guard let originalImage = currentImage else { return }

        let targetSize = resolvedDeviceSize()
        
        // 第一步：调整图片尺寸为 240×240
        guard let resizedImage = resizeImage(originalImage, to: targetSize) else {
            XLogger.shared.log("Failed to resize image to \(width)x\(height)")
            return
        }
        
        // 第二步：按压缩梯度尝试转换，避免在极低目标大小下重复做无效压缩
        let usesRLE = XGZTBlueToothManager.shared.device?.screenType == 2 || XGZTBlueToothManager.shared.device?.screenType == 3
        let targetSizeBytes = usesRLE ? 28 * 1024 : 120 * 1024
        let qualitySteps: [CGFloat] = usesRLE
            ? [1.0, 0.72]
            : [1.0, 0.9, 0.8, 0.72, 0.64, 0.56, 0.48, 0.4]
        let candidateImages: [(name: String, image: UIImage)] = {
            var candidates: [(String, UIImage)] = [("base", resizedImage)]

            if usesRLE {
                candidates.append(contentsOf: buildRLECandidateImages(from: resizedImage, targetSize: targetSize))
            }

            return candidates
        }()

        for candidate in candidateImages {
            if let parData = attemptDialDataConversion(for: candidate.image,
                                                       phaseName: candidate.name,
                                                       qualitySteps: qualitySteps,
                                                       targetSize: targetSize,
                                                       targetSizeBytes: targetSizeBytes,
                                                       usesRLE: usesRLE) {
                XLogger.shared.log("Success: phase=\(candidate.name), dial size=\(parData.count), target=\(targetSizeBytes)")
                binData = parData
                XGZTCommand.dialMarketQuery(dataType: 0)
                return
            }
        }

        XLogger.shared.log("Unable to reduce dial size below target=\(targetSizeBytes)")
    }

    private func attemptDialDataConversion(for sourceImage: UIImage,
                                           phaseName: String,
                                           qualitySteps: [CGFloat],
                                           targetSize: CGSize,
                                           targetSizeBytes: Int,
                                           usesRLE: Bool) -> Data? {
        var lastParSize: Int?
        var stagnantCount = 0

        for (attemptIndex, quality) in qualitySteps.enumerated() {
            let candidateImage: UIImage
            if quality >= 0.999 {
                candidateImage = sourceImage
            } else if let compressedData = sourceImage.jpegData(compressionQuality: quality),
                      let compressedImage = UIImage(data: compressedData) {
                candidateImage = compressedImage
            } else {
                XLogger.shared.log("Failed to create compressed candidate image, phase=\(phaseName), quality=\(quality)")
                return nil
            }

            guard let rawImageData = candidateImage.rawImageData else {
                XLogger.shared.log("Failed to get raw image data, phase=\(phaseName)")
                return nil
            }

            guard let parData = makeDialData(from: rawImageData, targetSize: targetSize, usesRLE: usesRLE) else {
                XLogger.shared.log("Failed to convert image to dial data at \(Int(targetSize.width))x\(Int(targetSize.height)), phase=\(phaseName)")
                return nil
            }

            let parSize = parData.count
            XLogger.shared.log("Attempt \(attemptIndex + 1): phase=\(phaseName), quality=\(quality), raw=\(rawImageData.count), dial=\(parSize), target=\(targetSizeBytes)")

            if parSize <= targetSizeBytes {
                return parData
            }

            if let lastParSize {
                if parSize >= lastParSize {
                    stagnantCount += 1
                } else {
                    stagnantCount = 0
                }
            }

            if stagnantCount >= 2 {
                XLogger.shared.log("Dial size stopped improving, phase=\(phaseName), last=\(lastParSize ?? parSize), current=\(parSize)")
                break
            }

            lastParSize = parSize
        }

        return nil
    }

    private func makeDialData(from rawImageData: Data, targetSize: CGSize, usesRLE: Bool) -> Data? {
        if usesRLE {
            return ParTool.rle(fromRaw: rawImageData,
                               width: Int32(targetSize.width),
                               height: Int32(targetSize.height),
                               transparentColor: 1)
        }

        return ParTool.par(fromRaw: rawImageData,
                           width: Int32(targetSize.width),
                           height: Int32(targetSize.height),
                           runAlpha: false,
                           useFilter: false,
                           supportRotate: false)
    }

    // 辅助方法：调整图片尺寸
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0 // 避免受设备缩放影响
        
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func buildRLECandidateImages(from image: UIImage, targetSize: CGSize) -> [(String, UIImage)] {
        let configs: [(String, CGFloat, UInt8)] = [
            ("quant-16", 1.0, 16),
            ("quant-32", 1.0, 32),
            ("pixel-75-quant-32", 0.75, 32),
            ("pixel-62-quant-48", 0.625, 48),
            ("pixel-50-quant-64", 0.5, 64)
        ]

        return configs.compactMap { name, scale, step in
            guard let candidate = resizeAndReduceRGB(image: image,
                                                     targetSize: targetSize,
                                                     downsampleRatio: scale,
                                                     quantizationStep: step) else {
                return nil
            }
            return (name, candidate)
        }
    }

    func resizeAndReduceRGB(image: UIImage,
                            targetSize: CGSize,
                            downsampleRatio: CGFloat = 1.0,
                            quantizationStep: UInt8 = 4) -> UIImage? {
        guard let normalizedImage = resizeImage(image, to: targetSize) else {
            return nil
        }

        let workingImage: UIImage
        if downsampleRatio < 0.999 {
            let sampledSize = CGSize(width: max(1, floor(targetSize.width * downsampleRatio)),
                                     height: max(1, floor(targetSize.height * downsampleRatio)))
            guard let lowResImage = resizeImage(normalizedImage, to: sampledSize),
                  let upscaledImage = redrawImage(lowResImage, to: targetSize, interpolation: .none) else {
                return nil
            }
            workingImage = upscaledImage
        } else {
            workingImage = normalizedImage
        }

        guard let cgImage = workingImage.cgImage else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        if let pixelData = context.data {
            let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
            let step = max(1, Int(quantizationStep))
            for y in 0..<height {
                for x in 0..<width {
                    let index = (y * width + x) * bytesPerPixel
                    var red = data[index]
                    var green = data[index + 1]
                    var blue = data[index + 2]

                    red = UInt8((Int(red) / step) * step)
                    green = UInt8((Int(green) / step) * step)
                    blue = UInt8((Int(blue) / step) * step)

                    data[index] = red
                    data[index + 1] = green
                    data[index + 2] = blue
                }
            }
        }
        
        guard let newCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: newCGImage)
    }

    private func redrawImage(_ image: UIImage, to targetSize: CGSize, interpolation: CGInterpolationQuality) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        context.interpolationQuality = interpolation
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private func compressAndConvertImage(image: UIImage) -> UIImage? {
        guard let data = image.compressImageOnlength(maxLength: 10) else {
            return nil
        }
        guard let nImage = UIImage(data: data) else {
            return nil
        }
        XLogger.shared.log("nImage: width \(nImage.size.width) height \(nImage.size.height)")
        return nImage
    }
    
    @objc func handleNotifyXGZT(_ notification: Notification) {
        let obj = notification.object as? Int ?? 0 // 1.开始 2.成功 3.失败   自定义 4.配置，5.开始，6，成功，7.失败
        _ = notification.userInfo as? [String: String]
        if obj == 4 {
            if binData.count == 0 {
                return
            }
            let binsize = binData.count
            let mtu = XGZTBlueToothManager.shared.device?.mtu ?? 0
            var packageTotal = 0
            guard mtu > 0 else {
                fatalError("MTU should be greater than 0")
            }

            if binsize % 200 == 0 {
                packageTotal = binsize / 200
            } else {
                packageTotal = binsize / 200 + 1
            }
            XGZTCommand.dialMarketSetTransferConfig(packageTotal: packageTotal, binSize: binsize, mtu: mtu, dialType: 1, dialNum: 1, local: diallocation, typeValue: 0 ,dialTypeValue: colorIndex)
        } else if obj == 5 {
            if binData.count == 0 {
                return
            }
            packageNum += 1
            let maxDataLength = 200
            let bin = (packageNum - 1) * maxDataLength
            let progress = bin * 100 / binData.count

            // 计算子数据的范围
            let a = min(bin + maxDataLength, binData.count)
            if a <= bin {
                return
            }
            let range = bin..<a
            let subData = binData.subdata(in: range)
            var control = 0
            if bin + maxDataLength >= binData.count {
                control = 1
            }
            XGZTCommand.dialMarketTransferData(packageNum: packageNum, binNum: bin, progressBar: progress, control: control, data: subData)
            
            let d = Float(bin * 100) / Float(binData.count)
            let s = String(format: "%.02f%%", d)
            DispatchQueue.main.async {
                [weak self] in
                self?.refreshUploadProgress(s)
            }
            
        } else if obj == 6 {
            if binData.count == 0 {
                return
            }
            packageNum = 0
            notif()
            binData = Data()
        } else if obj == 7 {
            if binData.count == 0 {
                return
            }
            packageNum = 0
            binData = Data()
            DispatchQueue.main.async {
                [weak self] in
                self?.dismissImageUploadController()
            }
        }
    }
    
    @objc func handleNotify(_ notify: Notification) {
        if notify.name == WristbandNotifyKeys.startImagePush {
            let any = notify.object as! Int
            XLogger.shared.log("收到壁纸推送通知: \(any)")
            if any == 1 {
                var mtuSize = 16
                let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B")
                if bk {
                    mtuSize = bleSelf.bleModel.MTU > 16 ? bleSelf.bleModel.MTU - 4 : 16
                }
                if bk {
                    currentPackage = 0
                    bleSelf.setImagePush(binData, dataIndex: 0, MTU: mtuSize)
                    return
                }
                for i in 0..<self.total {
                    if needStop == true {
                        Async.main {
                            [weak self] in
                            self?.dismissImageUploadController()
                        }
                        return
                    }
                    Async.main {
                        [weak self] in
                        guard let sSelf = self else {
                            return
                        }
                        let d = Float(i * 100) / Float(sSelf.total)
                        self?.refreshUploadProgress(String(format: "%.02f%%", d))
                    }
                    XLogger.shared.log("for循环推送[\(mtuSize)]: \(i) \(self.total)")
                    bleSelf.setImagePush(binData, dataIndex: i, MTU: mtuSize)
                    usleep(30 * 1000)
                    if i + 1 == self.total {
                        XLogger.shared.log("执行完成操作")
                        notif()
                    }
                }
                
            } else {
                Async.main {
                    [weak self] in
                    self?.dismissImageUploadController()
                    Toast(text: NSLocalizedString("该设备不支持壁纸推送，或者电量过低", comment: "")).show()
                    
                }
            }
        }
        
        if notify.name == WristbandNotifyKeys.imagePush {
            if let any = notify.object, any is [Int] {
                let array = any as! [Int]
                if array[1] == 0 {
                    wuPrint("更新失败")
                    DispatchQueue.main.async {
                        [weak self] in
                        self?.dismissImageUploadController()
                    }
                    return
                } else {
                    let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
                    if bk {
                        currentPackage += 1
                        let mtuSize = bleSelf.bleModel.MTU > 16 ? bleSelf.bleModel.MTU - 4 : 16
                        XLogger.shared.log("for循环推送[\(mtuSize)]: \(currentPackage) \(self.total)")
                        bleSelf.setImagePush(binData, dataIndex: currentPackage, MTU: mtuSize)
                        if currentPackage >= self.total {
                            notif()
                        }
                    }
                }
            }
        }
    }
    
    private func notif() {
        let timestamp = Int(Date().timeIntervalSince1970)
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self, let currentImage = self.currentImage else {
                return
            }
            Toast(text: "toast_success".localized()).show()
            let metrics = self.resolvedDeviceMetrics()
            self.saveImage(currentImage: currentImage, imageName: "\(lastestDeviceMac)_\(metrics.width)_\(metrics.height)_\(timestamp).png")
            var lastStamp = UserDefaults.standard.dictionary(forKey: "lastStamp") ?? [:]
            lastStamp[lastestDeviceMac] = timestamp
            UserDefaults.standard.set(lastStamp, forKey: "lastStamp")
            UserDefaults.standard.synchronize()
            self.dismissImageUploadController()
            self.tableView?.reloadData()
        }
        var clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
        var clockStr = clockDir[lastestDeviceMac] as? [String] ?? ["_&&_&&_", "_&&_&&_", "_&&_&&_"]
        let metrics = resolvedDeviceMetrics()
        let imageN = "\(lastestDeviceMac)_\(metrics.width)_\(metrics.height)_\(timestamp).png"
        let fullPath = NSHomeDirectory().appending("/Documents/").appending(imageN)
        clockStr[index] = "\("custom_watch_face".localized())&&\(imageN)&&\(fullPath)"
        clockDir[lastestDeviceMac] = clockStr
        UserDefaults.standard.setValue(clockDir, forKey: "MyClock")
        UserDefaults.standard.synchronize()
    }
    
    //保存图片至沙盒
    private func saveImage(currentImage: UIImage, imageName: String){
        if let imageData = currentImage.jpegData(compressionQuality: 1) as NSData? {
            let fullPath = NSHomeDirectory().appending("/Documents/").appending(imageName)
            imageData.write(toFile: fullPath, atomically: true)
        }
    }
    
    private func jlPushInitialize(image: UIImage) {
        ///壁纸推送需要点先初始化壁纸
        if bleSelf.isJLBlue && !bleSelf.funcCategoryModel.hasJLImagePush{
            //此方法最好放到杰里设备连接同步完成后调用
            JLSelf.getFlashInfo()
            //壁纸或者表盘前调用需要调用一次
            JLSelf.btn_List()
        }
        
        perform(#selector(self.jlPushImage(image:)), with: image, afterDelay: 0.5)
    }
    
    @objc private func jlPushImage(image: UIImage) {
        ///壁纸推送  需要设备支持
        //自行裁剪对应宽高，并压缩图片 目前没有限制 但是设备空间有限 一般150kb差不多 尽量控制300kb左右
        if bleSelf.isJLBlue && !bleSelf.funcCategoryModel.hasJLImagePush{
            if bleSelf.batteryLevel <= 15 {
                self.showHud(NSLocalizedString("设备电量低，请先给设备充电", comment: ""))
                return
            }
            
            var newImage = image
            if !AppDelegate.IsDeviceNotRound() {
                newImage = maskRoundedImage(image: image, radius: resolvedMaskRadius(for: image))
            }
            
            JLSelf.getJLDataFromImage(image: newImage)
            
            JLSelf.getInfoList()
           XLogger.shared.log("执行杰里的壁纸推送逻辑")
        }else{
            var data = bleSelf.getRGBData565FromImage(image: image)!
            XLogger.shared.log("执行杰里的壁纸推送逻辑1")
            if bleSelf.funcCategoryModel.hasJLImagePush {
                XLogger.shared.log("执行杰里的壁纸推送逻辑2")
                //两个字节互调
                var i = 0
                while i < data.count - 1 {
                    let one = data[i]
                    let two = data[i+1]
                    
                    data[i] = two
                    data[i+1] = one
                    i += 2
                }
            }
            wuPrint(data.count)
            self.total = Int(ceil(Double(data.count)/16))
            self.binData = data
            bleSelf.startImagePush(data)
            
        }
    }
    
    func maskRoundedImage(image: UIImage, radius: CGFloat) -> UIImage {
        let imageView: UIImageView = UIImageView(image: image)
        let layer = imageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = radius
        UIGraphicsBeginImageContext(imageView.bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
    }
}



extension MyClockViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return height + 80
        } else if indexPath.row == 4 || (indexPath.row == 2 && isXGZT) {
            return 112
        }
        
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as! SelectItemViewController
            controller.delegate = self
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .overFullScreen
            controller.type = 0
            if isXGZT {
                controller.index = diallocation
                controller.titles = xgztlocations
            } else {
                controller.index = datetimeLocation
                controller.titles = locations
            }
            controller.titleStr = "time_position".localized()
            itemVC = controller
            navigationController?.present(controller, animated: false, completion: nil)
        } else if indexPath.row == 2 && !isXGZT {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as! SelectItemViewController
            controller.delegate = self
            topTap = true
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .overFullScreen
            controller.index = datetimeTopLocation
            controller.type = 1
            controller.titles = tops
            controller.titleStr = "content_above_time".localized()
            itemVC = controller
            navigationController?.present(controller, animated: false, completion: nil)
        } else if indexPath.row == 3 && !isXGZT {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as! SelectItemViewController
            controller.delegate = self
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .overFullScreen
            controller.index = datetimeBottomLocation
            controller.type = 2
            controller.titles = tops
            controller.titleStr = "content_below_time".localized()
            itemVC = controller
            navigationController?.present(controller, animated: false, completion: nil)
        }
    }
}

extension MyClockViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isXGZT {
            return 3
        }
        let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
        if bleSelf.isJLBlue {
            return 1
        }
        if bk {
            return 4
        }
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell1", for: indexPath) as! EidtClockHeadTableViewCell
            cell.delegate = self
            cell.clockView.layer.cornerRadius = AppDelegate.IsDeviceNotRound() ? 30 : width / 2
            cell.clockView.clipsToBounds = true
            if isXGZT {
                cell.dateTimeLabel.isHidden = true
                cell.dateTimeTopLabel.isHidden = true
                cell.dateTimeBottomLabel.isHidden = true
            } else {
                cell.dateTimeLabel.text = "time".localized()
                cell.dateTimeTopLabel.text = datetimeTopLocation > 0 ? tops[datetimeTopLocation] : ""
                cell.dateTimeBottomLabel.text = datetimeBottomLocation > 0 ? tops[datetimeBottomLocation] : ""
                cell.dateTimeLabel.textColor = colors[colorIndex]
                cell.dateTimeTopLabel.textColor = colors[colorIndex]
                cell.dateTimeBottomLabel.textColor = colors[colorIndex]
            }
            cell.topLC.constant = datetimeLocation == 0 ? 10 : 74
            cell.itemImageView.contentMode = .scaleToFill
            cell.itemImageView.backgroundColor = UIColor.gray
            cell.itemImageView.layer.cornerRadius = 30
            cell.itemImageView.clipsToBounds = true
            cell.selectButton.setTitle("select_image".localized(), for: .normal)
            cell.selectButton.setTitleColor(UIColor.brand, for: .normal)
            cell.selectButton.titleLabel?.font = UIFont.subtitle1()
            cell.selectButton.titleLabel?.textAlignment = .center // 文字水平居中
            cell.selectButton.contentHorizontalAlignment = .center // 按钮内容水平居中
            cell.selectButton.contentVerticalAlignment = .center // 按钮内容垂直居中
            let metrics = resolvedDeviceMetrics()
            let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
            let lastStamp = UserDefaults.standard.dictionary(forKey: "lastStamp") ?? [:]
            let stamp = lastStamp[lastestDeviceMac] ?? ""
            let fullPath = NSHomeDirectory().appending("/Documents/").appending("\(lastestDeviceMac)_\(metrics.width)_\(metrics.height)_\(stamp).png")
            if let savedImage = UIImage(contentsOfFile: fullPath) {
                cell.itemImageView?.image = savedImage
            }
            cell.ivWidthLC.constant = width
            cell.ivHeightLC.constant = height
            // 隐藏分隔符
            cell.layoutMargins = UIEdgeInsets.zero
            cell.separatorInset = UIEdgeInsets.zero
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        if indexPath.row == 4 || (indexPath.row == 2 && isXGZT) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell3", for: indexPath) as! EditClcokBottomTableViewCell
            cell.index = colorIndex
            cell.delegate = self
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell2", for: indexPath) as! EditClockMiddleTableViewCell
        if indexPath.row == 1 {
            cell.textLabel?.text = "time_position".localized()
            if isXGZT {
                cell.detailTextLabel?.text = xgztlocations[diallocation]
            } else {
                cell.detailTextLabel?.text = locations[datetimeLocation]
            }
        }
        if indexPath.row == 2 && !isXGZT {
            cell.textLabel?.text = "content_above_time".localized()
            cell.detailTextLabel?.text = tops[datetimeTopLocation]
        }
        if indexPath.row == 3 && !isXGZT {
            cell.textLabel?.text = "content_below_time".localized()
            cell.detailTextLabel?.text = tops[datetimeBottomLocation]
        }
        return cell
    }
    
}

extension MyClockViewController: SelectItemVCDelegate {
    func callback(type: Int, index: Int, value: String) {
        if type == 0 {
            if isXGZT {
                diallocation = index
            } else {
                datetimeLocation = index
            }
            tableView.reloadData()
        }
        if type == 1 {
            datetimeTopLocation = index
            tableView.reloadData()
        }
        if type == 2 {
            datetimeBottomLocation = index
            tableView.reloadData()
        }
        modifyCustomDialSettings()
    }
}

extension MyClockViewController: EidtClockHeadTableViewCellDelegate {
    func handleSelectPhoto() {
        imagePickerVc = TZImagePickerController(maxImagesCount: 1, delegate: self)
        imagePickerVc?.modalPresentationStyle = .fullScreen
        imagePickerVc?.allowCrop = true
        imagePickerVc?.showSelectBtn = false
        if !AppDelegate.IsDeviceNotRound() {
            imagePickerVc?.needCircleCrop = true
        }
        let targetSize = resolvedDeviceSize()
        let w = targetSize.width
        let h = targetSize.height
        var w1: CGFloat = 0
        var h1: CGFloat = 0
        if w >= h {
            h1 = 300 * h / w
            w1 = 300
        } else {
            h1 = 300
            w1 = 300 * w / h
        }
        imagePickerVc?.cropRect = CGRect(x: (ScreenWidth - w1) / 2, y: (ScreenHeight - h1) / 2, width: w1, height: h1)
        imagePickerVc?.naviTitleColor = UIColor.black
        imagePickerVc?.barItemTextColor = UIColor.black
        imagePickerVc?.iconThemeColor = UIColor.black
        self.parent?.present(imagePickerVc!, animated: true) {
            
        }
        
    }
}

extension MyClockViewController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        if photos.count <= 0 {
            return
        }
        XLogger.shared.log("选定了图片")
        if imageUploadVc != nil {
            return
        }
        let controller = UploadImageViewController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controller.delegate = self
        if isXGZT && !AppDelegate.IsDeviceNotRound() {
            controller.image = photos.first?.croppedToCircleSmooth()
        } else {
            controller.image = photos.first
        }

        controller.imgView.contentMode = .scaleAspectFit
        imageUploadVc = controller
        self.present(controller, animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
    }
}

extension MyClockViewController: EditClcokBottomTableViewCellDelegate {
    func callbackForSelectColor(collectionView: UICollectionView, index: Int) {
        colorIndex = index
        modifyCustomDialSettings()
        if isXGZT {
            //tableView.reloadRows(at: [IndexPath(item: 2, section: 0)], with: UITableView.RowAnimation.automatic)
        } else {
            tableView.reloadRows(at: [IndexPath(item: 4, section: 0), IndexPath(item: 0, section: 0)], with: UITableView.RowAnimation.automatic)
        }
        collectionView.reloadData()
    }
}

extension MyClockViewController: UploadImageDelegate {
    func startUpload(image: UIImage) {
        currentImage = image
        if isXGZT {
            startupdateCustomImage()
            return
        }
        
        if bleSelf.isJLBlue {
            let data = bleSelf.getRGBData565FromImage(image: image)!
            self.total = Int(ceil(Double(data.count)/16))
            self.binData = data
            jlPushInitialize(image: image)
        } else {
            XLogger.shared.log("中科设备开始推送数据")
            let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
            if bk {
                let mtuSize = bleSelf.bleModel.MTU > 16 ? bleSelf.bleModel.MTU - 4 : 16
                var data = image.toBMPRGB565()!
                self.total = Int(ceil(Double(data.count)/Double(mtuSize)))
                self.binData = data
                bleSelf.startImagePush(data, MTU: mtuSize)
            } else {
                let data = bleSelf.getRGBData565FromImage(image: image)!
                self.total = Int(ceil(Double(data.count)/16))
                self.binData = data
                bleSelf.startImagePush(data)
            }
        }
    }
    
    func dismissVC() {
        imageUploadVc = nil
    }
}

extension UIImage {
    func compressImageOnlength(maxLength: Int) -> Data? {
        let maxL = maxLength * 1024
        var compress:CGFloat = 0.9
        let maxCompress:CGFloat = 0.1
        var imageData = self.jpegData(compressionQuality: compress)
        while (imageData?.count)! > maxL && compress > maxCompress {
            compress -= 0.1
            imageData = self.jpegData(compressionQuality: compress)
        }
        return imageData
    }
}

extension UIImage {
     
    //将图片缩放成指定尺寸（多余部分自动删除）
    func scaled(to newSize: CGSize) -> UIImage {
        //绘制并获取最终图片
        UIGraphicsBeginImageContext(newSize)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
}

extension MyClockViewController: CustomImageFooterViewDelegate {
    func callbackForSelectImage(collectionView: UICollectionView, index: Int) {
        let image = UIImage(named: "\(index + 1)_80_160")!
        
        XLogger.shared.log("选定了图片")
        if imageUploadVc != nil {
            return
        }
        let controller = UploadImageViewController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controller.delegate = self
        controller.image = image
        controller.imgView.contentMode = .scaleAspectFit
        imageUploadVc = controller
        self.present(controller, animated: false, completion: nil)
    }
}
