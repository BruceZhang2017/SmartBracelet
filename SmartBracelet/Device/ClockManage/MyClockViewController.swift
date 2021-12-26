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
    
    var datetimeLocation = 0  ///时间上方0 时间下方1
    var datetimeTopLocation = 0 ///关闭0 日期1 睡眠2 心率3 计步4
    var datetimeBottomLocation = 0 ///关闭0 日期1 睡眠2 心率3 计步4
    var colorIndex = 0 ///白色0 黑色1 黄色2 橙色3 粉色4 紫色5 蓝色6 青色7
    final let locations = ["上方", "下方"]
    final let tops = ["关闭", "日期", "睡眠", "心率", "记步"]
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
    var needStop = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print("瑞昱设备表盘宽%@高%@,可推空间",bleSelf.bleModel.screenWidth, bleSelf.bleModel.screenHeight)
//        if bShowDetail == false {
//            rightButton = UIButton(type: .custom).then {
//                $0.initializeRightNavigationItem()
//                $0.setTitle("管理", for: .normal)
//                $0.setTitle("mine_delete".localized(), for: .selected)
//                $0.setTitle("完成", for: .disabled)
//            }
//            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
//        }
//        collctionView.bounces = false
//        let flow = ClockCollectionViewFlowLayout()
//        collctionView.collectionViewLayout = flow
//
//        nullLabel = UILabel().then {
//            $0.textColor = UIColor.black
//            $0.font = UIFont.systemFont(ofSize: 20)
//            $0.text = "device_need_download_dial_tip".localized()
//            $0.numberOfLines = 0
//        }
//        view.addSubview(nullLabel)
//        nullLabel.snp.makeConstraints {
//            $0.left.equalTo(20)
//            $0.right.equalTo(-20)
//            $0.centerY.equalToSuperview()
//        }
//
//        let clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
//        let clockStr = clockDir[bleSelf.bleModel.mac] as? String ?? ""
//        if clockStr.count > 0 {
//            ClockArray = clockStr.components(separatedBy: "&&&")
//            nullLabel.isHidden = true
//        }
        
        
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //collctionView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        itemVC?.dismiss(animated: false, completion: {
            
        })
        needStop = true
        imageUploadVc?.dismiss(animated: false, completion: {
            
        })
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
            if any == 1 {
                for i in 0..<self.total {
                    if needStop == true {
                        Async.main {
                            [weak self] in
                            self?.imageUploadVc?.dismiss(animated: false, completion: {
                                
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
                        self?.imageUploadVc?.uploadButton.setTitle(String(format: "%.02f%%", d), for: .normal)
                    }
                    print("for循环推送: \(i) \(self.total)")
                    bleSelf.setImagePush(binData, dataIndex: i)
                    usleep(20 * 1000)
                    if i + 1 == self.total {
                        Async.main {
                            [weak self] in
                            self?.imageUploadVc?.dismiss(animated: false, completion: {
                                
                            })
                        }
                    }
                }
                
            } else {
                Async.main {
                    wuPrint(NSLocalizedString("该设备不支持壁纸推送，或者电量过低", comment: ""))
                    
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
                Async.main {
                    [weak self] in
                    self?.imageUploadVc?.dismiss(animated: false, completion: {
                        
                    })
                    self?.tableView.reloadData()
                }
            }
        }
    }
}

//extension MyClockViewController: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return ClockArray.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockCollectionViewCell
//        let item = ClockArray[indexPath.row]
//        let array = item.components(separatedBy: "&&")
//        cell.dialImageView.image = UIImage(named: array[1])
//        //cell.clockNameLabel.text = "\(bleSelf.bleModel.name)-\(indexPath.row + 1)"
//        cell.opaqueView.isHidden = true
//        cell.optionImageView.isHidden = true
//        return cell
//    }
//
//}
//
//extension MyClockViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
//        if !bleSelf.isConnected {
//            Toast(text: "mine_unconnect".localized()).show()
//            return
//        }
//        let vc = storyboard?.instantiateViewController(withIdentifier: "ClockUseViewController") as? ClockUseViewController
//        vc?.index = indexPath.row + 1
//        vc?.clockStr = ClockArray[indexPath.row]
//        parent?.navigationController?.pushViewController(vc!, animated: true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: (ScreenWidth - 60) / 2, height: (ScreenWidth - 60) / 2)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
//}

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
            itemVC?.titleStr = "时间位置"
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
            itemVC?.titleStr = "时间上方内容"
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
            itemVC?.titleStr = "时间下方内容"
            navigationController?.present(itemVC!, animated: false, completion: nil)
        }
    }
}

extension MyClockViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell1", for: indexPath) as! EidtClockHeadTableViewCell
            cell.delegate = self
            cell.dateTimeLabel.text = "时间"
            cell.dateTimeTopLabel.text = datetimeTopLocation > 0 ? tops[datetimeTopLocation] : ""
            cell.dateTimeBottomLabel.text = datetimeBottomLocation > 0 ? tops[datetimeBottomLocation] : ""
            cell.dateTimeLabel.textColor = colors[colorIndex]
            cell.dateTimeTopLabel.textColor = colors[colorIndex]
            cell.dateTimeBottomLabel.textColor = colors[colorIndex]
            cell.topLC.constant = datetimeLocation == 0 ? 10 : 74
            if binData.count > 0 {
                cell.imageView?.image = UIImage(data: binData)
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
            cell.textLabel?.text = "时间位置"
            cell.detailTextLabel?.text = locations[datetimeLocation]
        }
        if indexPath.row == 2 {
            cell.textLabel?.text = "时间上方内容"
            cell.detailTextLabel?.text = tops[datetimeTopLocation]
        }
        if indexPath.row == 3 {
            cell.textLabel?.text = "时间下方内容"
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
        imagePickerVc?.cropRect = CGRect(x: (ScreenWidth - w) / 2, y: (ScreenHeight - h) / 2, width: w, height: h)
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
        imageUploadVc = UploadImageViewController()
        imageUploadVc?.modalPresentationStyle = .overCurrentContext
        imageUploadVc?.modalTransitionStyle = .crossDissolve
        imageUploadVc?.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        imageUploadVc?.delegate = self
        imageUploadVc?.image = photos.first
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
        let data = bleSelf.getRGBData565FromImage(image: image)!
        self.total = Int(ceil(Double(data.count)/16))
        self.binData = data
        
        bleSelf.startImagePush(data)
    }
}
