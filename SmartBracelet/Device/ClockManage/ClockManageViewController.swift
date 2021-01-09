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
        title = "表盘管理"
        let mine = SegmentioItem(title: "我的表盘", image: nil)
        let market = SegmentioItem(title: "表盘市场", image: nil)
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
            content: [mine, market],
            style: .onlyLabel,
            options: options
        )
        segmentio.selectedSegmentioIndex = 0
        segmentio.valueDidChange = {
            [weak self] segmentio, segmentIndex in
            self?.scrollView.contentOffset = CGPoint(x: Int(ScreenWidth) * segmentIndex, y: 0)
        }
        
        setupUI()
    }
    
    private func setupUI() {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let myClockVC = storyboard.instantiateViewController(withIdentifier: "MyClockViewController") as! MyClockViewController
        contentView.addSubview(myClockVC.view)
        myClockVC.bShowDetail = true
        addChild(myClockVC)
        myClockVC.view.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.width.equalTo(ScreenWidth)
            $0.top.bottom.equalToSuperview()
        }
        let marketClockVC = storyboard.instantiateViewController(withIdentifier: "MarketClockViewController") as! MarketClockViewController
        contentView.addSubview(marketClockVC.view)
        marketClockVC.bShowDetail = true
        addChild(marketClockVC)
        marketClockVC.view.snp.makeConstraints {
            $0.left.equalTo(myClockVC.view.snp.right)
            $0.width.equalTo(ScreenWidth)
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview()
        }
        contentViewWidthConstraint.constant = ScreenWidth * 2
    }

}
