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

class MyClockViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var collctionView: UICollectionView!
//    var rightButton: UIButton!
//    var bShowDetail = false
//    var nullLabel: UILabel!
//    var ClockArray: [String] = []
    var imagePickerVc: TZImagePickerController?
    
    var datetimeLocation = 0
    var datetimeTopLocation = 0
    var datetimeBottomLocation = 0
    final let locations = ["上方", "下方"]
    final let tops = ["关闭", "日期", "睡眠", "心率", "记步"]
    var topTap = false

    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        //去掉没有数据显示部分多余的分隔线
        tableView.tableFooterView =  UIView.init(frame: CGRect.zero)
        
        //将分隔线offset设为零，即将分割线拉满屏幕
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        //设置分隔线颜色
        tableView.separatorColor = UIColor.gray
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //collctionView.reloadData()
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
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as! SelectItemViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.index = datetimeLocation
            vc.type = 0
            vc.titles = locations
            navigationController?.present(vc, animated: false, completion: nil)
        } else if indexPath.row == 2 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as! SelectItemViewController
            vc.delegate = self
            topTap = true
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.index = datetimeTopLocation
            vc.type = 1
            vc.titles = tops
            navigationController?.present(vc, animated: false, completion: nil)
        } else if indexPath.row == 3 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as! SelectItemViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.index = datetimeBottomLocation
            vc.type = 2
            vc.titles = tops
            navigationController?.present(vc, animated: false, completion: nil)
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
            return cell
        }
        if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell3", for: indexPath) as! EditClcokBottomTableViewCell
            
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
    }
}

extension MyClockViewController: EidtClockHeadTableViewCellDelegate {
    func handleSelectPhoto() {
        imagePickerVc = TZImagePickerController(maxImagesCount: 1, delegate: self)
        imagePickerVc?.modalPresentationStyle = .fullScreen
        imagePickerVc?.allowCrop = false
        imagePickerVc?.showSelectBtn = false
        self.parent?.present(imagePickerVc!, animated: true) {
            
        }
        
    }
}

extension MyClockViewController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        print("选定了图片")
        let imageCropVC = RSKImageCropViewController(image: photos.first!, cropMode: .custom)
        imageCropVC.delegate = self
        imageCropVC.dataSource = self
        imagePickerVc?.navigationController?.pushViewController(imageCropVC, animated: true)
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
        print("选定了图片")
    }
}

extension MyClockViewController: RSKImageCropViewControllerDataSource {
    func imageCropViewControllerCustomMaskRect(_ controller: RSKImageCropViewController) -> CGRect {
        return CGRect(x: (ScreenWidth - 140) / 2, y: (ScreenHeight - 140) / 2, width: 140, height: 140)
    }
    
    func imageCropViewControllerCustomMaskPath(_ controller: RSKImageCropViewController) -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x: (ScreenWidth - 140) / 2, y: (ScreenHeight - 140) / 2, width: 140, height: 140), cornerRadius: 0)
    }
    
    func imageCropViewControllerCustomMovementRect(_ controller: RSKImageCropViewController) -> CGRect {
        return controller.maskRect
    }
    
    
}

extension MyClockViewController: RSKImageCropViewControllerDelegate {
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        imagePickerVc?.navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        imagePickerVc?.navigationController?.popViewController(animated: true)
    }
    
    
}
