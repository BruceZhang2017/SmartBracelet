//
//  UploadImageViewController.swift
//  SmartBracelet
//
//  Created by anker on 2021/12/19.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit
import Toaster

class UploadImageViewController: UIViewController {
    
    weak var delegate: UploadImageDelegate?
    var image:UIImage? {
        didSet {
            if image == nil {
                return
            }
            imgView.image = image!
            guard let imageData = NSUIImageJPEGRepresentation(image!, 0.3) else {
                return
            }
            sizeLabel.text = "device_ota_file_size".localized() + imageData.count.sizeToStr()
        }
    }
    
    lazy var conView: UIView = {
        let view = UIView().then {
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 16
            $0.clipsToBounds = true
        }
        self.view.addSubview(view)
        view.snp.makeConstraints {
            $0.left.equalTo(50)
            $0.right.equalTo(-50)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(300)
        }
        return view
    }()
    
    lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        conView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.top.equalTo(32)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(150)
        }
        return imageView
    }()
    
    lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.text_third
        label.font = UIFont.body1()
        conView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.equalTo(imgView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        return label
    }()
    
    lazy var uploadButton: UIButton = {
        let button = UIButton(type: .custom).then {
            $0.backgroundColor = UIColor.brand
            $0.setTitleColor(UIColor.white, for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            $0.setTitle("start_uploading".localized(), for: .normal)
            $0.addTarget(self, action: #selector(handleUpload), for: .touchUpInside)
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 22
        }
        conView.addSubview(button)
        button.snp.makeConstraints {
            $0.leading.equalTo(20)
            $0.right.equalTo(-20)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().offset(-20)
        }
        return button
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom).then {
            $0.setImage(UIImage(named: "quxiao"), for: .normal)
            $0.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        }
        conView.addSubview(button)
        button.snp.makeConstraints {
            $0.top.right.equalToSuperview()
            $0.height.width.equalTo(40)
        }
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        conView.isHidden = false
        uploadButton.isHidden = false
        cancelButton.isHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleStop), name: Notification.Name("UploadImageViewController"), object: nil)
        needStop = false
        
        UIApplication.shared.isIdleTimerDisabled = true // 保持常亮
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false // 取消常亮
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleStop() {
        view.isHidden = true 
        dismiss(animated: false) {
            
        }
    }
    
    @objc func handleUpload() {
        if !bleSelf.isConnected {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        uploadButton.isUserInteractionEnabled = false
        if let i = image {
            cancelButton.isHidden = true 
            let w: CGFloat = CGFloat(bleSelf.bleModel.screenWidth)
            let h: CGFloat = CGFloat(bleSelf.bleModel.screenHeight)
            let newImage = i.scaled(to: CGSize(width: w, height: h))
            let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
            if bleSelf.isJLBlue || bk {
                delegate?.startUpload(image: newImage)
            } else {
                let imageData = newImage.compressImageOnlength(maxLength: (w <= 80 || h <= 160) ? 28 : 100)
                delegate?.startUpload(image: UIImage(data: imageData!)!)
            }
        }
    }
    
    @objc func handleCancel() {
        if uploadButton.titleLabel?.text == "start_uploading".localized() {
            dismiss(animated: false, completion: nil)
        }
    }
    
    func scale(image: UIImage, toSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(toSize, false, 1)
        image.draw(in: CGRect.init(origin: .zero, size: toSize))
        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return temp
    }
    
    public func refreshProgress(p : String) {
        uploadButton.setTitle("start_uploading".localized() + "..." + p, for: .normal)
    }
}

protocol UploadImageDelegate: NSObjectProtocol {
    func startUpload(image: UIImage)
}
