//
//  SCFloatingWindowReviewView.swift
//  SoundCore
//
//  Created by Leo.guan on 2020/12/10.
//  Copyright © 2020 team. All rights reserved.
//

import SDWebImage
import UIKit

var floatingViewCenter = CGPoint.zero
var isShowBigView = false
var miniImgDownloaded = false
var bigImgDownloaded = false

private var miniIageURLKey = "FloatingViewMiniImageURL"
private var bigImageURLKey = "FloatingViewBigImageURL"

// MARK: - SCFloatingWindowReviewView

class SCFloatingWindowReviewView: UIView {

    // MARK: Lifecycle

    init(
        miniImgUrl: String,
        bigImgUrl: String,
        miniSize: CGSize,
        bigSize: CGSize,
        viewProtocol: UIViewController) {
        super.init(frame: .zero)
        self.miniImgUrl = miniImgUrl
        self.bigImgUrl = bigImgUrl
        self.miniSize = miniSize
        self.bigSize = bigSize
        self.viewProtocol = viewProtocol
        isHidden = true
        initUI()
        initLayout()
        loadImage()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var didClickedClosure: ((_ index: Int) -> Void)? //发生点击事件时的回调，index为被点击的action cell索引，从0开始

    
    func downloadedImage(link: String, imageName: String) {
        UserDefaults.standard.removeObject(forKey: bigImageURLKey)
        imageView.downloadedFrom(link: link, imageName: imageName) {
            DispatchQueue.main.async {
                self.isHidden = false
                bigImgDownloaded = true
                UserDefaults.standard.setValue(self.bigImgUrl, forKeyPath: bigImageURLKey)
                print("invite: 大图加载成功")
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func updateMiniViewLayout() {
        miniView.snp.remakeConstraints({
            $0.center.equalTo(floatingViewCenter)
        })
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
        let view = super.hitTest(point, with: event)
        if !isShowBigView {
            if view == miniView.closeBtn {
                return view
            }
            if view != miniView {
                return nil
            }
        }
        return view
    }
    
    @objc
    func detectPan(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            floatingViewCenter = miniView.center
        } else if recognizer.state == .changed {
            let translation = recognizer.translation(in: self)
            let minY = frame.minY + 20
            let maxY = frame.maxY - 10
            
            if miniView.frame.minY <= minY && translation.y <= 0 {
                miniView.frame = CGRect(origin: CGPoint(x: miniView.frame.origin.x, y: minY), size: miniView.frame.size)
                return
            } else if miniView.frame.maxY >= maxY && translation.y >= 0 {
                miniView.frame = CGRect(
                    origin: CGPoint(x: miniView.frame.origin.x, y: maxY - miniView.frame.size.height),
                    size: miniView.frame.size)
                return
            }
            miniView.center = CGPoint(x: floatingViewCenter.x, y: floatingViewCenter.y + translation.y)
        } else {
            floatingViewCenter = miniView.center
            if let closure = didClickedClosure {
                closure(4)
            }
        }
    }
    
    @objc
    func openURL() {
        if let closure = didClickedClosure {
            closure(3)
        }
    }
    
    @objc
    func clickMiniView(_: Any) {
        if let closure = didClickedClosure {
            closure(0)
        }
    }
    
    func showBigImageView() {
        if imageView.image == nil {
            openURL()
            return
        }
        if viewProtocol.navigationController != nil {
            viewProtocol.navigationController?.view.addSubview(self)
            snp.remakeConstraints({
                $0.edges.equalToSuperview()
            })
        }
        backgroundColor = .white
        isShowBigView = true
        bigView.isHidden = false
        miniView.isHidden = true
        
        UIView.animate(withDuration: 0.25) {
            self.bigView.alpha = 1
        }
    }
    
    @objc
    func removeSCFloatingWindowView(_: Any) {
        if let closure = didClickedClosure {
            closure(1)
        }
    }
    
    @objc
    func clickBigViewColseBtn(_: Any) {
        if let closure = didClickedClosure {
            closure(2)
        }
    }
    
    func hideBigImageView() {
        isShowBigView = false
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let _self = self else { return }
            _self.bigView.alpha = 0
            _self.backgroundColor = .clear
        } completion: { [weak self] (_) in
            guard let _self = self else { return }
            _self.bigView.isHidden = true
            _self.miniView.isHidden = false
            if _self.viewProtocol.navigationController != nil {
                _self.viewProtocol.view.addSubview(_self)
                _self.snp.remakeConstraints({
                    $0.edges.equalToSuperview()
                })
            }
        }
    }

    // MARK: Private

    private var blankView: UIView!
    
    private var miniView: SCFloatingWindowView!
    
    private var bigView: UIControl!
    private var imageControl: UIControl!
    private var imageView: UIImageView!
    private var closeBtn: UIButton!
    
    private var miniImgUrl: String!
    private var bigImgUrl: String!
    private var miniSize: CGSize!
    private var bigSize: CGSize!
    private weak var viewProtocol: UIViewController!
    private var needShowBigView = false

    
    private func initUI() {
        blankView = UIView()
        blankView.isUserInteractionEnabled = false
        addSubview(blankView)
        miniView = SCFloatingWindowView(imageUrl: miniImgUrl, imageSize: miniSize)
            .then({
                $0.closeBtn.addTarget(self, action: #selector(removeSCFloatingWindowView(_:)), for: .touchUpInside)
                $0.addTarget(self, action: #selector(clickMiniView(_:)), for: .touchUpInside)
                let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(detectPan(_:)))
                $0.gestureRecognizers = [panRecognizer]
            })
        addSubview(miniView)
        
        bigView = UIControl()
        bigView.alpha = 0
        bigView.isHidden = true
        addSubview(bigView)
        
        imageControl = UIControl()
        imageControl.addTarget(self, action: #selector(openURL), for: .touchUpInside)
        bigView.addSubview(imageControl)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageControl.addSubview(imageView)
        
        closeBtn = UIButton()
            .then({
                $0.addTarget(self, action: #selector(clickBigViewColseBtn(_:)), for: .touchUpInside)
                $0.setImage(UIImage(named: "common_guide_close"), for: .normal)
            })
        bigView.addSubview(closeBtn)
    }
    
    private func initLayout() {
        miniView.snp.makeConstraints({
            if floatingViewCenter != .zero {
                updateMiniViewLayout()
            } else {
                $0.right.equalToSuperview()
                $0.centerY.equalToSuperview().offset(56)
            }
        })
        
        bigView.snp.makeConstraints({
            $0.center.equalToSuperview()
        })
        let screenWidth = UIScreen.main.bounds.width
        imageControl.snp.makeConstraints({
            if bigSize.width >= screenWidth {
                $0.width.equalTo(screenWidth - 70 * scale)
                $0.height.equalTo(bigSize.height / (bigSize.width / (screenWidth - 70 * scale)))
            } else {
                $0.width.equalTo(bigSize.width)
                $0.height.equalTo(bigSize.height)
            }
            $0.top.left.right.equalToSuperview()
        })
        
        imageView.snp.makeConstraints({
            $0.edges.equalToSuperview()
        })
        
        closeBtn.snp.makeConstraints({
            $0.top.equalTo(imageControl.snp.bottom).offset(26)
            $0.centerX.bottom.equalToSuperview()
            $0.width.height.equalTo(44)
        })
    }
    
    private func loadImage() {
        let imageNmae = "floatingViewBigImage"
        let url = UserDefaults.standard.value(forKey: bigImageURLKey) as? String
        if url != nil && url == bigImgUrl {
            do {
                if bigImgUrl.lowercased().hasSuffix("gif") {
                    let url = getDocumentsDirectory().appendingPathComponent(imageNmae + ".gif")
                    let data = try Data(contentsOf: url)
                    imageView.image = UIImage.sd_image(withGIFData: data)
                } else {
                    let url = getDocumentsDirectory().appendingPathComponent(imageNmae + ".png")
                    let data = try Data(contentsOf: url)
                    imageView.image = UIImage.sd_image(with: data,scale: 1)
                }
                isHidden = false
                print("invite: 大图缓存加载成功")
                bigImgDownloaded = true
            } catch {
                print("invite: 大图缓存加载失败")
                downloadedImage(link: bigImgUrl, imageName: imageNmae)
                print(error)
            }
            
        } else {
            downloadedImage(link: bigImgUrl, imageName: imageNmae)
        }
    }
}

// MARK: - SCFloatingWindowView

class SCFloatingWindowView: UIControl {

    // MARK: Lifecycle

    init(imageUrl: String, imageSize: CGSize) {
        super.init(frame: .zero)
        self.imageUrl = imageUrl
        self.imageSize = imageSize
        isHidden = true
        initUI()
        initLayout()
        loadImage()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var image: UIImageView!
    var closeBtn: UIButton!

    
    func downloadedImage(link _: String, imageName: String) {
        UserDefaults.standard.removeObject(forKey: miniIageURLKey)
        image.downloadedFrom(link: imageUrl, imageName: imageName) { [weak self] in
            guard let _self = self else { return }
            DispatchQueue.main.async {
                _self.isHidden = false
                UserDefaults.standard.setValue(_self.imageUrl, forKeyPath: miniIageURLKey)
                print("invite: 小图加载成功")
                miniImgDownloaded = true
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    // MARK: Private

    private var imageUrl: String!
    private var imageSize: CGSize!

    
    private func initUI() {
        image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = false
        addSubview(image)
        
        closeBtn = UIButton()
        closeBtn.setImage(UIImage(named: "common_icon_delete_small_grey"), for: .normal)
        addSubview(closeBtn)
    }
    
    private func initLayout() {
        image.snp.makeConstraints({
            $0.left.top.right.equalToSuperview()
            $0.width.equalTo(imageSize.width)
            $0.height.equalTo(imageSize.height)
        })
        
        closeBtn.snp.makeConstraints({
            $0.top.equalTo(image.snp.bottom).offset(5)
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
        })
    }
    
    private func loadImage() {
        let imageNmae = "floatingViewMiniImage"
        let url = UserDefaults.standard.value(forKey: miniIageURLKey) as? String
        if url != nil && url == imageUrl {
            do {
                if imageUrl.lowercased().hasSuffix("gif") {
                    let url = getDocumentsDirectory().appendingPathComponent(imageNmae + ".gif")
                    let data = try Data(contentsOf: url)
                    image.image = UIImage.sd_image(withGIFData: data)
                } else {
                    let url = getDocumentsDirectory().appendingPathComponent(imageNmae + ".png")
                    let data = try Data(contentsOf: url)
                    image.image = UIImage.sd_image(with: data,scale: 1)
                }
                isHidden = false
                
                print("invite: 小图缓存加载成功")
                miniImgDownloaded = true
            } catch {
                print("invite: 小图缓存加载失败")
                downloadedImage(link: imageUrl, imageName: imageNmae)
                print(error)
            }
        } else {
            downloadedImage(link: imageUrl, imageName: imageNmae)
        }
    }
}

extension UIImageView {
    func downloadedFrom(
        url: URL,
        imageName: String,
        contentMode mode: UIView.ContentMode = .scaleAspectFit,
        callback: (() -> Void)? = nil) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil
            else {
                print("invite 图片下载失败 error: \(String(describing: error?.localizedDescription))")
                return
            }
            let name = imageName + (mimeType.hasSuffix("gif") ? ".gif" : ".png")
            let fullPath = self.getDocumentsDirectory().appendingPathComponent(name)
            do {
                let manager = FileManager.default
                if manager.fileExists(atPath: fullPath.path) {
                    try manager.removeItem(at: fullPath)
                }
                try data.write(to: fullPath)
            } catch(let error) {
                print("invite 图片保存失败失败 error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async() {
                if mimeType.hasSuffix("gif") {
                    self.image = UIImage.sd_image(withGIFData: data)
                } else {
                    self.image = UIImage.sd_image(with: data)
                }
            }
            callback?()
        }.resume()
    }
    
    func downloadedFrom(
        link: String,
        imageName: String,
        contentMode mode: UIView.ContentMode = .scaleAspectFit,
        callback: (() -> Void)? = nil) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, imageName: imageName, contentMode: mode, callback: callback)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
