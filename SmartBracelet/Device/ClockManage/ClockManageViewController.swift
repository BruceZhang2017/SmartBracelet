//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ClockManageViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/4.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Segmentio
import SnapKit

class ClockManageViewController: BaseViewController {
    @IBOutlet weak var segmentio: Segmentio!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bleSelf.getImagePushSettings()
        title = "dial_management".localized()
        let mine = SegmentioItem(title: "自定义表盘".localized(), image: nil)
        let market = SegmentioItem(title: "device_dial_mall".localized(), image: nil)
        let state = SegmentioStates(
                    defaultState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.systemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    ),
                    selectedState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.systemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    ),
                    highlightedState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.boldSystemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    )
        )
        let options = SegmentioOptions(
                    backgroundColor: .white,
                    segmentPosition: SegmentioPosition.fixed(maxVisibleItems: 4),
                    scrollEnabled: true,
                    indicatorOptions: SegmentioIndicatorOptions(type: .bottom, ratio: 0.3, height: 2, color: .k3ACF95),
                    horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(type: .none, height: 0, color: .clear),
                    verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(ratio: 0, color: .clear),
                    imageContentMode: .center,
                    labelTextAlignment: .center,
                    segmentStates: state
        )
        
        segmentio.setup(
            content: [market, mine],
            style: .onlyLabel,
            options: options
        )
        segmentio.selectedSegmentioIndex = 0
        segmentio.valueDidChange = {
            [weak self] segmentio, segmentIndex in
            self?.scrollView.contentOffset = CGPoint(x: Int(ScreenWidth) * segmentIndex, y: 0)
        }
        automaticallyAdjustsScrollViewInsets = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        scrollView.bounces = false
        scrollView.delegate = self
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleStop), name: Notification.Name("UploadImageViewController"), object: nil)
        needStop = false 
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleStop() {
        needStop = true
    }
    
    private func setupUI() {
        if contentView.subviews.count >= 2 {
            return
        }
        let storyboard = UIStoryboard(name: "Device", bundle: nil)

        let marketClockVC = storyboard.instantiateViewController(withIdentifier: "MarketClockViewController") as! MarketClockViewController
        contentView.addSubview(marketClockVC.view)
        marketClockVC.bShowDetail = true
        addChild(marketClockVC)
        marketClockVC.view.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.width.equalTo(ScreenWidth)
            $0.top.bottom.equalToSuperview()
        }
        
        let myClockVC = storyboard.instantiateViewController(withIdentifier: "MyClockViewController") as! MyClockViewController
        contentView.addSubview(myClockVC.view)
        addChild(myClockVC)
        myClockVC.view.snp.makeConstraints {
            $0.left.equalTo(marketClockVC.view.snp.right)
            $0.width.equalTo(ScreenWidth)
            $0.top.bottom.equalToSuperview()
        }
        
        contentViewWidthConstraint.constant = ScreenWidth * 2
    }

}

extension ClockManageViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }
}
