//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MyClockViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//

import UIKit
import Then
import Toaster
import TJDWristbandSDK


var needStop = false

typealias imgBlock = () ->()

class MyClockViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var collctionView: UICollectionView!
//    var rightButton: UIButton!
//    var bShowDetail = false
//    var nullLabel: UILabel!
//    var ClockArray: [String] = []
    var imagePickerVc: TZImagePickerController?
    var imageUploadVc: UploadImageViewController?
    var index = 0
    var datetimeLocation = 0  ///时间上方0 时间下方1
    var datetimeTopLocation = 0 ///关闭0 日期1 睡眠2 心率3 计步4
    var datetimeBottomLocation = 0 ///关闭0 日期1 睡眠2 心率3 计步4
    var colorIndex = 0 ///白色0 黑色1 黄色2 橙色3 粉色4 紫色5 蓝色6 青色7
    final let locations = ["above".localized(), "below".localized()]
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
    
    var binData = Data()
    var current = 0
    var total = 0
    var currentImage: UIImage?
    
    var footView: CustomImageFooterView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "custom_watch_face".localized()
        print("瑞昱设备表盘宽%@高%@,可推空间",bleSelf.bleModel.screenWidth, bleSelf.bleModel.screenHeight)
        
        datetimeLocation = bleSelf.dialSelectModel.timeDirection
        datetimeTopLocation = bleSelf.dialSelectModel.onTheTime
        datetimeBottomLocation = bleSelf.dialSelectModel.belowTheTime
        colorIndex = bleSelf.dialSelectModel.textColor
        
        //去掉没有数据显示部分多余的分隔线
        tableView.tableFooterView =  UIView.init(frame: CGRect.zero)
        
        //将分隔线offset设为零，即将分割线拉满屏幕
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        //设置分隔线颜色
        tableView.separatorColor = UIColor.gray
        
        //壁纸推送
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.startImagePush, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotify(_:)), name: WristbandNotifyKeys.imagePush, object: nil)
        
        footView = CustomImageFooterView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 160))
        tableView.tableFooterView = footView
        
        let w: CGFloat = CGFloat(bleSelf.bleModel.screenWidth)
        let h: CGFloat = CGFloat(bleSelf.bleModel.screenHeight)
        footView?.isHidden = !(w == 80 && h == 160)
        footView?.delegate = self
        bleSelf.getFuncCategory()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //collctionView.reloadData()
    }
    
    deinit {
        itemVC?.dismiss(animated: false, completion: {
            
        })
        needStop = true
        print("壁纸推送暂停")
        imageUploadVc?.dismiss(animated: false, completion: {
            
        })
        NotificationCenter.default.removeObserver(self)
    }
    
    // 修改自定义设置内容位置
    private func modifyCustomDialSettings() {
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
    
    @objc func handleNotify(_ notify: Notification) {
        if notify.name == WristbandNotifyKeys.startImagePush {
            let any = notify.object as! Int
            print("收到壁纸推送通知: \(any)")
            if any == 1 {
                for i in 0..<self.total {
                    if needStop == true {
                        Async.main {
                            [weak self] in
                            self?.imageUploadVc?.dismiss(animated: false, completion: {
                                [weak self] in
                                self?.imageUploadVc = nil
                            })
                        }
                        return
                    }
                    Async.main {
                        [weak self] in
                        guard let sSelf = self else {
                            return
                        }
                        let d = Float(i * 100) / Float(sSelf.total)
                        self?.imageUploadVc?.refreshProgress(p: String(format: "%.02f%%", d))
                    }
                    print("for循环推送: \(i) \(self.total)")
                    bleSelf.setImagePush(binData, dataIndex: i)
                    usleep(30 * 1000)
                    if i + 1 == self.total {
                        let timestamp = Int(Date().timeIntervalSince1970)
                        DispatchQueue.main.async {
                            [weak self] in
                            if self?.currentImage == nil {
                                return
                            }
                            let w  = bleSelf.bleModel.screenWidth
                            let h = bleSelf.bleModel.screenHeight
                            let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
                            self?.saveImage(currentImage: self!.currentImage!, imageName: "\(lastestDeviceMac)_\(w)_\(h)_\(timestamp).png")
                            var lastStamp = UserDefaults.standard.dictionary(forKey: "lastStamp") ?? [:]
                            lastStamp[lastestDeviceMac] = timestamp
                            UserDefaults.standard.set(lastStamp, forKey: "lastStamp")
                            UserDefaults.standard.synchronize()
                            self?.imageUploadVc?.dismiss(animated: false, completion: {
                                [weak self] in
                                self?.imageUploadVc = nil
                            })
                            self?.tableView?.reloadData()
                        }
                        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
                        var clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
                        var clockStr = clockDir[lastestDeviceMac] as? [String] ?? ["_&&_&&_", "_&&_&&_", "_&&_&&_"]
                        let w  = bleSelf.bleModel.screenWidth
                        let h = bleSelf.bleModel.screenHeight
                        let imageN = "\(lastestDeviceMac)_\(w)_\(h)_\(timestamp).png"
                        let fullPath = NSHomeDirectory().appending("/Documents/").appending(imageN)
                        clockStr[index] = "\("custom_watch_face".localized())&&\(imageN)&&\(fullPath)"
                        clockDir[lastestDeviceMac] = clockStr
                        UserDefaults.standard.setValue(clockDir, forKey: "MyClock")
                        UserDefaults.standard.synchronize()
                        
                        
                    }
                }
                
            } else {
                Async.main {
                    [weak self] in
                    self?.imageUploadVc?.dismiss(animated: false, completion: {
                        [weak self] in
                        self?.imageUploadVc = nil
                    })
                    Toast(text: NSLocalizedString("该设备不支持壁纸推送，或者电量过低", comment: "")).show()
                    
                }
            }
        }
        
        if notify.name == WristbandNotifyKeys.imagePush {
            if let any = notify.object, any is [Int] {
                let array = any as! [Int]
                if array[1] == 0 {
                    wuPrint("更新失败")
                    return
                }
                wuPrint("更新成功")
                DispatchQueue.main.async {
                    [weak self] in
                    self?.imageUploadVc?.dismiss(animated: false, completion: {
                        
                    })
                }
            }
        }
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
            if bleSelf.bleModel.screenType == 2 {
                newImage = maskRoundedImage(image: image, radius: (CGFloat(bleSelf.bleModel.screenHeight))/2)
            }
            
            JLSelf.getJLDataFromImage(image: newImage)
            
            JLSelf.getInfoList()
            
        }else{
            var data = bleSelf.getRGBData565FromImage(image: image)!
            
            if bleSelf.funcCategoryModel.hasJLImagePush {
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
            return 160
        } else if indexPath.row == 4 {
            return 100
        }
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
            itemVC?.delegate = self
            itemVC?.modalTransitionStyle = .crossDissolve
            itemVC?.modalPresentationStyle = .overFullScreen
            itemVC?.index = datetimeLocation
            itemVC?.type = 0
            itemVC?.titles = locations
            itemVC?.titleStr = "time_position".localized()
            navigationController?.present(itemVC!, animated: false, completion: nil)
        } else if indexPath.row == 2 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
            itemVC?.delegate = self
            topTap = true
            itemVC?.modalTransitionStyle = .crossDissolve
            itemVC?.modalPresentationStyle = .overFullScreen
            itemVC?.index = datetimeTopLocation
            itemVC?.type = 1
            itemVC?.titles = tops
            itemVC?.titleStr = "content_above_time".localized()
            navigationController?.present(itemVC!, animated: false, completion: nil)
        } else if indexPath.row == 3 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
            itemVC?.delegate = self
            itemVC?.modalTransitionStyle = .crossDissolve
            itemVC?.modalPresentationStyle = .overFullScreen
            itemVC?.index = datetimeBottomLocation
            itemVC?.type = 2
            itemVC?.titles = tops
            itemVC?.titleStr = "content_below_time".localized()
            navigationController?.present(itemVC!, animated: false, completion: nil)
        }
    }
}

extension MyClockViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if bleSelf.isJLBlue {
            return 1
        }
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell1", for: indexPath) as! EidtClockHeadTableViewCell
            cell.delegate = self
            cell.dateTimeLabel.text = "time".localized()
            cell.dateTimeTopLabel.text = datetimeTopLocation > 0 ? tops[datetimeTopLocation] : ""
            cell.dateTimeBottomLabel.text = datetimeBottomLocation > 0 ? tops[datetimeBottomLocation] : ""
            cell.dateTimeLabel.textColor = colors[colorIndex]
            cell.dateTimeTopLabel.textColor = colors[colorIndex]
            cell.dateTimeBottomLabel.textColor = colors[colorIndex]
            cell.topLC.constant = datetimeLocation == 0 ? 10 : 74
            cell.itemImageView.contentMode = .scaleAspectFit
            cell.selectButton.setTitle(" ", for: .normal)
//            cell.selectButton.titleLabel?.adjustsFontSizeToFitWidth = true
//            cell.selectButton.titleLabel?.numberOfLines = 1
            let w  = bleSelf.bleModel.screenWidth
            let h = bleSelf.bleModel.screenHeight
            let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
            let lastStamp = UserDefaults.standard.dictionary(forKey: "lastStamp") ?? [:]
            let stamp = lastStamp[lastestDeviceMac] ?? ""
            let fullPath = NSHomeDirectory().appending("/Documents/").appending("\(lastestDeviceMac)_\(w)_\(h)_\(stamp).png")
            if let savedImage = UIImage(contentsOfFile: fullPath) {
                cell.itemImageView?.image = savedImage
            }
            let width = bleSelf.bleModel.screenWidth
            let height = bleSelf.bleModel.screenHeight
            if width == 80 && height == 160 {
                cell.leadingLC.constant = 50
                cell.ivWidthLC.constant = 80
                cell.ivHeightLC.constant = 160
            }
        
            return cell
        }
        if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell3", for: indexPath) as! EditClcokBottomTableViewCell
            cell.index = colorIndex
            cell.delegate = self
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell2", for: indexPath) as! EditClockMiddleTableViewCell
        if indexPath.row == 1 {
            cell.textLabel?.text = "time_position".localized()
            cell.detailTextLabel?.text = locations[datetimeLocation]
        }
        if indexPath.row == 2 {
            cell.textLabel?.text = "content_above_time".localized()
            cell.detailTextLabel?.text = tops[datetimeTopLocation]
        }
        if indexPath.row == 3 {
            cell.textLabel?.text = "content_below_time".localized()
            cell.detailTextLabel?.text = tops[datetimeBottomLocation]
        }
        return cell
    }
}

extension MyClockViewController: SelectItemVCDelegate {
    func callback(type: Int, index: Int, value: String) {
        if type == 0 {
            datetimeLocation = index
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
        let w: CGFloat = CGFloat(bleSelf.bleModel.screenWidth)
        let h: CGFloat = CGFloat(bleSelf.bleModel.screenHeight)
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
        print("选定了图片")
        if imageUploadVc != nil {
            return
        }
        imageUploadVc = UploadImageViewController()
        imageUploadVc?.modalPresentationStyle = .overCurrentContext
        imageUploadVc?.modalTransitionStyle = .crossDissolve
        imageUploadVc?.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        imageUploadVc?.delegate = self
        imageUploadVc?.image = photos.first
        imageUploadVc?.imgView.contentMode = .scaleAspectFit
        self.present(imageUploadVc!, animated: false) {
            
        }
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
    }
}

extension MyClockViewController: EditClcokBottomTableViewCellDelegate {
    func callbackForSelectColor(collectionView: UICollectionView, index: Int) {
        colorIndex = index
        modifyCustomDialSettings()
        tableView.reloadRows(at: [IndexPath(item: 4, section: 0), IndexPath(item: 0, section: 0)], with: UITableView.RowAnimation.automatic)
        collectionView.reloadData()
    }
}

extension MyClockViewController: UploadImageDelegate {
    func startUpload(image: UIImage) {
        currentImage = image
        let data = bleSelf.getRGBData565FromImage(image: image)!
        self.total = Int(ceil(Double(data.count)/16))
        self.binData = data
        if bleSelf.isJLBlue {
            jlPushInitialize(image: image)
        } else {
            bleSelf.startImagePush(data)
        }
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
        
        print("选定了图片")
        if imageUploadVc != nil {
            return
        }
        imageUploadVc = UploadImageViewController()
        imageUploadVc?.modalPresentationStyle = .overCurrentContext
        imageUploadVc?.modalTransitionStyle = .crossDissolve
        imageUploadVc?.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        imageUploadVc?.delegate = self
        imageUploadVc?.image = image
        imageUploadVc?.imgView.contentMode = .scaleAspectFit
        self.present(imageUploadVc!, animated: false) {
            
        }
    }
}
