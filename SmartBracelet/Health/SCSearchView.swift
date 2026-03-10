//
// * Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// * The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.

//
//  SCSearchView.swift
//  SoundCore
//
//  Created by bruce on 2018/3/9.
//  Copyright © 2018年 team. All rights reserved.
//

import ModuleCommon
import UIKit

public class SCSearchView: UIView {

    // MARK: Public

    public var waterWaveTimer: Timer?
    
    public var waterRippleView1: UIView!
    public var waterRippleView2: UIView!
    public var waterRippleView3: UIView!
    
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        Bundle.ModuleConnect?.loadNibNamed("SCSearchView", owner: self, options: nil)
//    }
    
    public class func viewFromNIB() -> SCSearchView {
        let views = Bundle.ModuleConnect?.loadNibNamed("SCSearchView", owner: nil, options: nil)
        return views![0] as! SCSearchView
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .bg_white
        searchLabel.textAlignment = .center
        
        waterWaveViewWidthConstraint.constant = waterWaveWidth
        
        waveView.layer.opacity = 0
        waveView.insertGradientLayer(
            size: CGSize(width: waterWaveWidth, height: waterWaveWidth),
            isHaveShadow: false,
            cornerRadius: waterWaveWidth / 2,
            direction:.upToDownAndLeftToRight,
            colors: [
                UIColor(red:122, green:239, blue:255),
                UIColor(red:54, green:207, blue:255),
                UIColor(red:86,green:154, blue:255)
            ])
        addWaterRipple()
        
        searchLabel.font = UIFont.t15L
        searchLabel.textColor = .text_2
      
        imageView.image = UIImage.svgImage("search_ic_logod")
        
        waterWaveView.backgroundColor = .clear
    }
    
    public func setText(_ text: String? = nil) {
        searchLabel.text = text ?? "cnn_searching_device".localized()
    }
    
    public func startAnimation() {
        if waterWaveTimer == nil {
            waterWaveTimer = Timer.scheduledTimer(
                timeInterval: 1.51,
                target: self,
                selector: #selector(waterRippleAnimation),
                userInfo: nil,
                repeats: true)
            waterWaveTimer?.fire()
            RunLoop.main.add(waterWaveTimer!, forMode: RunLoop.Mode.common)
            waveView.layer.opacity = 1
            
        }
    }
    
    public func stopAnimation() {
        waterWaveTimer?.invalidate()
        waterWaveTimer = nil
        waveView.layer.opacity = 0
    }

    // MARK: Internal

    @IBOutlet weak var waterWaveView: UIView!
    @IBOutlet weak var waveView: UIView!
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var waterWaveViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!

    // MARK: Private

    private let waterWaveWidth: CGFloat = 160 * scale
    private let wavePreWidth: CGFloat = 105 * scale
    private let waterRippleView1PreWidth: CGFloat = 180 * scale
    private let waterRippleView2PreWidth: CGFloat = 263 * scale
    private let waterRippleView3PreWidth: CGFloat = 391 * scale
    private let waveWidth: CGFloat = 260 * scale
    private let waterRippleView1Width: CGFloat = 456 * scale
    private let waterRippleView2Width: CGFloat = 672 * scale
    private let waterRippleView3Width: CGFloat = 874 * scale
    private let waveSufWidth: CGFloat = 292 * scale
    private let waterRippleView1SufWidth: CGFloat = 512 * scale
    private let waterRippleView2SufWidth: CGFloat = 767 * scale
    private let waterRippleView3SufWidth: CGFloat = 924 * scale
    
    private let waterWaveRadius = 90

    
    private func addWaterRipple() {
        
        waterRippleView1 = UIView(frame: CGRect(
            x: -(waterRippleView1Width - waterWaveWidth) / 2,
            y: -(waterRippleView1Width - waterWaveWidth) / 2,
            width: waterRippleView1Width,
            height: waterRippleView1Width))
        waterRippleView1?.layer.cornerRadius = CGFloat(waterRippleView1Width / 2)
        waterRippleView1?.insertGradientLayer(
            size: (waterRippleView1?.bounds.size)!,
            isHaveShadow: false,
            cornerRadius: waterRippleView1!.bounds.size.height / 2)
        waterWaveView.insertSubview(waterRippleView1!, belowSubview: waveView)
        
        waterRippleView2 = UIView(frame: CGRect(
            x: -(waterRippleView2Width - waterWaveWidth) / 2,
            y: -(waterRippleView2Width - waterWaveWidth) / 2,
            width: waterRippleView2Width,
            height: waterRippleView2Width))
        waterRippleView2?.layer.cornerRadius = CGFloat(waterRippleView2Width / 2)
        waterRippleView2?.insertGradientLayer(
            size: (waterRippleView2?.bounds.size)!,
            isHaveShadow: false,
            cornerRadius: waterRippleView2!.bounds.size.height / 2)
        waterWaveView.insertSubview(waterRippleView2!, belowSubview: waterRippleView1!)
        
        waterRippleView3 = UIView(frame: CGRect(
            x: -(waterRippleView3Width - waterWaveWidth) / 2,
            y: -(waterRippleView3Width - waterWaveWidth) / 2,
            width: waterRippleView3Width,
            height: waterRippleView3Width))
        waterRippleView3?.layer.cornerRadius = CGFloat(waterRippleView3Width / 2)
        waterRippleView3?.insertGradientLayer(
            size: (waterRippleView3?.bounds.size)!,
            isHaveShadow: false,
            cornerRadius: waterRippleView3!.bounds.size.height / 2)
        waterWaveView.insertSubview(waterRippleView3!, belowSubview: waterRippleView2!)
        
        waterRippleView1.alpha = 0
        waterRippleView2.alpha = 0
        waterRippleView3.alpha = 0
    }
    
    // 设置水波纹动画
    @objc
    private func waterRippleAnimation() {
        waterRippleView1.transform = CGAffineTransform(
            scaleX: waterRippleView1PreWidth / waterRippleView1Width,
            y: waterRippleView1PreWidth / waterRippleView1Width)
        waterRippleView2.transform = CGAffineTransform(
            scaleX: waterRippleView1PreWidth / waterRippleView1Width,
            y: waterRippleView1PreWidth / waterRippleView1Width)
        waterRippleView3.transform = CGAffineTransform(
            scaleX: waterRippleView1PreWidth / waterRippleView1Width,
            y: waterRippleView1PreWidth / waterRippleView1Width)
        isHidden = false
        
        UIView.animate(withDuration: 0.9, delay: 0, options: .curveEaseIn, animations: {
            [weak self] in
                self?.waterRippleView1?.transform = CGAffineTransform.identity
                self?.waterRippleView2?.transform = CGAffineTransform.identity
                self?.waterRippleView3?.transform = CGAffineTransform.identity
                self?.waterRippleView1?.alpha = 0.12
                self?.waterRippleView2?.alpha = 0.08
                self?.waterRippleView3?.alpha = 0.07
        }) { [weak self] (_) in
            self?.hideWaterView()
        }
    }
    
    private func hideWaterView() {
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut, animations: {
            [weak self] in
                self?.waterRippleView1?.transform = CGAffineTransform(
                    scaleX: self!.waterRippleView1SufWidth / self!.waterRippleView1Width,
                    y: self!.waterRippleView1SufWidth / self!.waterRippleView1Width)
                self?.waterRippleView2?.transform = CGAffineTransform(
                    scaleX: self!.waterRippleView2SufWidth / self!.waterRippleView2Width,
                    y: self!.waterRippleView2SufWidth / self!.waterRippleView2Width)
                self?.waterRippleView3?.transform = CGAffineTransform(
                    scaleX: self!.waterRippleView3SufWidth / self!.waterRippleView3Width,
                    y: self!.waterRippleView3SufWidth / self!.waterRippleView3Width)
                self?.waterRippleView1?.alpha = 0.0
                self?.waterRippleView2?.alpha = 0.0
                self?.waterRippleView3?.alpha = 0.0
        }) { [weak self] (_) in
            self?.waterRippleView1?.transform = CGAffineTransform.identity
            self?.waterRippleView2?.transform = CGAffineTransform.identity
            self?.waterRippleView3?.transform = CGAffineTransform.identity
        }
    }
}
