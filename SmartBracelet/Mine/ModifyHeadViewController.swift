//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ModifyHeadViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/7.
//  Copyright © 2020 tjd. All rights reserved.
//
	
import UIKit
import Kingfisher
import Toaster
import Alamofire

class ModifyHeadViewController: UIViewController {
    @IBOutlet weak var headImageView: UIImageView!
    @IBOutlet weak var headView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var selectPhotoButton: UIButton!
    @IBOutlet weak var CameraButton: UIButton!
    lazy var imagePicker = HImagePickerUtils()
    var currentImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headView.addVGradientLayer(at: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenWidth), colors: [UIColor.k64F2B4, UIColor.k08CCCC])
        headImageView.clipsToBounds = true
        let fileName = "head.jpg"
        let b = FileCache().fileIfExist(name: fileName)
        if b {
            let data = FileCache().readData(name: fileName)
            headImageView.image = UIImage(data: data)
        } else {
            let url = UserManager.sharedInstall.user?.headUrl ?? ""
            if url.count > 0 && url.hasPrefix("http") {
                headImageView.kf.setImage(with: URL(string: url)!)
            } else {
                headImageView.image = UIImage(named: "image_portrait")
            }
        }
        
        CameraButton.setTitle("mine_camera".localized(), for: .normal)
        selectPhotoButton.setTitle("select_image".localized(), for: .normal)
        saveButton.setTitle("mine_save".localized(), for: .normal)
        cancelButton.setTitle("mine_cancel".localized(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func invokeCamera(_ sender: Any) {
        imagePicker.takePhoto(presentFrom: self, completion: { [unowned self] (image, status) in
            if status == .success {
                self.headImageView.image = image
                self.currentImage = image
            }else{
                if status == .denied{
                    HImagePickerUtils.showTips(at: self,type: .takePhoto)
                }else{
                    print(status.description())
                }
            }
        })
    }
    
    @IBAction func invokePhoto(_ sender: Any) {
        imagePicker.choosePhoto(presentFrom: self, completion: { [unowned self] (image, status) in
            if status == .success {
                self.headImageView.image = image
                self.currentImage = image
            }else{
                if status == .denied{
                    HImagePickerUtils.showTips(at: self,type: .choosePhoto)
                }else{
                    print(status.description())
                }
                
            }
        })
    }
    
    @IBAction func save(_ sender: Any) {
        if currentImage == nil {
            return
        }
        guard let data = currentImage?.jpegData(compressionQuality: 0.05) else {
            return
        }
        FileCache().saveData(data, name: "head.jpg")
        //uploadImage(data: data)
        Toast(text: "保存成功").show()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func back(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func uploadData(name: String) {
        //ProgressHUD.show()
        var parameters = ["id": "\(UserManager.sharedInstall.user?.id ?? 0)"]
        parameters["headUrl"] = name
        AF.request("\(UrlPrefix)api/User/userinfo.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { (response) in
            
        }
    }
}
