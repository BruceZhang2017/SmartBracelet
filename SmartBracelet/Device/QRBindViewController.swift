import UIKit

class QRBindViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var codeResult = ""
    var type = 0
    
    // 用于展示二维码区域的视图
    private lazy var qrContainerView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        return view
    }()
    
    // 加号图标
    private lazy var plusImageView: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "plus_icon"))
        // 启用用户交互（UIImageView 默认关闭）
        imgView.isUserInteractionEnabled = true
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(plusImageTapped))
        imgView.addGestureRecognizer(tapGesture)
        return imgView
    }()
    
    // 步骤说明标签
    private lazy var stepLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = """
        绑定步骤:
        1. 打开应用，去支付页面保存收款码到手机本地；(必须手动点击保存收款码进行保存,截图无效);
        2. 点击上方二维码区域，添加或更换二维码；
        3. 点击下方绑定按钮，将二维码绑定至手表；点我
        """
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    // 去绑定按钮
    private lazy var bindButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("去绑定", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .brand
        btn.layer.cornerRadius = 22
        btn.addTarget(self, action: #selector(bindButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("QRBindViewController"), object: nil)
    }
    
    func dealloc() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加二维码容器视图
        view.addSubview(qrContainerView)
        qrContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(50)
            make.size.equalTo(CGSize(width: 150, height: 150))
        }
        qrContainerView.addSubview(plusImageView)
        plusImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 150, height: 150))
        }
        
        // 添加步骤说明标签
        view.addSubview(stepLabel)
        stepLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(qrContainerView.snp.bottom).offset(30)
        }
        
        // 添加去绑定按钮
        view.addSubview(bindButton)
        bindButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
            make.height.equalTo(44)
        }
    }
    
    // 点击事件处理方法
    @objc private func plusImageTapped() {
        // 在这里实现点击加号图标后的逻辑
        print("加号图标被点击了")
        // 例如：打开图片选择器、显示二维码选择界面等
        codeResult = ""
        openLocalPhotoAlbum()
    }

    
    @objc private func bindButtonTapped() {
        // 实际要处理 URL Scheme 调用第三方 App 等复杂操作，以下仅打印示意
        print("开始执行绑定流程，可在此处理与其他 App 交互等逻辑")
        if codeResult.count > 0 {
            XGZTCommand.setQRCode(type: UInt8(type), qrString: codeResult)
        }
    }
    
    // MARK: - ------- 相册
    func openLocalPhotoAlbum() {

        LBXPermissions.authorizePhotoWith { [weak self] (granted) in

            if granted {
                if let strongSelf = self {
                    let picker = UIImagePickerController()
                  
                    picker.sourceType = UIImagePickerController.SourceType.photoLibrary
                    picker.delegate = self;

                    picker.allowsEditing = true
                   strongSelf.present(picker, animated: true, completion: nil)
                }
            } else {
                LBXPermissions.jumpToSystemPrivacySetting()
            }
        }
    }
    
    // MARK: - ----相册选择图片识别二维码 （条形码没有找到系统方法）
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        var image:UIImage? = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        
        if (image == nil )
        {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        }

        if(image == nil) {
            return
        }

        if(image != nil) {
            let arrayResult = LBXScanWrapper.recognizeQRImage(image: image!)
            if arrayResult.count > 0 {
                let result = arrayResult[0]

                //showMsg(title: result.strBarCodeType, message: result.strScanned)
                if result.strScanned != nil {
                    let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator", codeString: result.strScanned!, size: plusImageView.bounds.size, qrColor: UIColor.black, bkColor: UIColor.white)
                    codeResult = result.strScanned!
                    plusImageView.image = qrImg
                }

                return
            }
        }
        showMsg(title: "", message: "识别失败")
    }

    
    func showMsg(title:String?,message:String?)
    {
        let alertController = UIAlertController(title: title, message:message, preferredStyle: UIAlertController.Style.alert)
        
        let alertAction = UIAlertAction(title:  "知道了", style: UIAlertAction.Style.default) { (alertAction) -> Void in
            

        }

        alertController.addAction(alertAction)

        present(alertController, animated: true, completion: nil)
    }

    func myCode() {
        
    }

    func scanFinished(scanResult: LBXScanResult, error: String?) {
        NSLog("scanResult:\(scanResult)")
        
        
        
    }
    
    
    @objc private func handleNotification(_ notification: Notification) {
        if let obj = notification.object as? String, obj.count > 0 {
            if obj == "0" {
                DispatchQueue.main.async { [weak self] in
                    self?.showMsg(title: "", message: "发送成功")
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.showMsg(title: "", message: "发送失败")
                }
            }
        }
    }
}
