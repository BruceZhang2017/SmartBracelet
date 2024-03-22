//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  SCReviewView.swift
//  SoundCore
//
//  Created by ACC-Timo on 2019/9/10.
//  Copyright © 2019 team. All rights reserved.
//
//  封装邀请评论、亚马逊邀评等功能的弹框视图

import UIKit

// MARK: - SCReviewView

class SCReviewView: UIView {

    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(viewInfo: SCReviewView.ViewInfo) {
        super.init(frame: .zero)
        self.viewInfo = viewInfo
        initializeUI()
        initializeLayout()
    }

    // MARK: Internal

    var didClickedClosure: ((_ index: Int) -> Void)? //发生点击事件时的回调，index为被点击的action cell索引，从0开始
    
    var panelView: UIView! //白色圆角容器视图
    var arcBGView: UIView! //圆弧背景
    var imageView: UIImageView! //顶部图片
    var titleLabel: UILabel! //标题
    var actionsTableView: UITableView! //可点击视图列表
    var viewInfo: SCReviewView.ViewInfo! //整体视图初始化信息

    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    func initializeUI() {
        backgroundColor = .white.withAlphaComponent(0.01)

        panelView = UIView().then {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 14
            $0.clipsToBounds = true
        }
        
        imageView = UIImageView().then {
            $0.image = viewInfo.image
        }
        
        titleLabel = UILabel().then {
            $0.textAlignment = .center
            $0.textColor = .black
            $0.font = UIFont.systemFont(ofSize: 18)
            $0.text = viewInfo.title
            $0.numberOfLines = 0
        }

        arcBGView = UIView().then {
            $0.backgroundColor = .white
        }
        
        actionsTableView = UITableView().then {
            $0.backgroundColor = .clear
            $0.separatorColor = .black
            $0.isScrollEnabled = false
            $0.tableFooterView = UIView(frame: .zero)
            $0.dataSource = self
            $0.delegate = self
            $0.register(UITableViewCell.self, forCellReuseIdentifier: actionCellIdentifier)
        }
    }
    
    func  initializeLayout() {
        panelView.do {
            addSubview($0)
            $0.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.width.equalTo(280)
            }
        }
        
        imageView.do {
            panelView.addSubview($0)
            $0.snp.makeConstraints {
                $0.top.equalToSuperview().inset(viewInfo.imageTop)
                $0.centerX.equalToSuperview()
                $0.size.equalTo(viewInfo.imageSize)
            }
        }
        
        titleLabel.do {
            panelView.addSubview($0)
            $0.snp.makeConstraints {
                $0.top.equalTo(imageView.snp.bottom).offset(viewInfo.spaceBetweenImageAndTitle)
                $0.left.right.equalToSuperview().inset(10)
            }
        }

        arcBGView.do {
            panelView.addSubview($0)
            panelView.sendSubviewToBack($0)
            $0.snp.makeConstraints {
                $0.top.left.right.equalToSuperview()
                $0.bottom.equalTo(titleLabel.snp.bottom).offset(viewInfo.spaceBetweenArcBGAndTitle)
            }
        }
        
        actionsTableView.do {
            panelView.addSubview($0)
            $0.snp.makeConstraints {
                $0.top.equalTo(arcBGView.snp.bottom)
                $0.left.right.equalToSuperview()
                $0.height.equalTo(heightOfActionCell * CGFloat(viewInfo.actionsInfo.count))
                $0.bottom.equalToSuperview()
            }
        }
        
        layoutIfNeeded()
    }

    // MARK: Private

    private let heightOfActionCell: CGFloat = 85 //每个可点击的cell的高度
    private let actionCellIdentifier = "actionCellIdentifier"

}

// MARK: UITableViewDataSource

extension SCReviewView: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewInfo.actionsInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: actionCellIdentifier, for: indexPath)
        guard indexPath.row < viewInfo.actionsInfo.count else { return cell }
        //分割线
        if indexPath.row == viewInfo.actionsInfo.count - 1 {
            //隐藏分割线
//            cell.hideSeparator()
        } else {
            //显示分割线
//            cell.showSeparactor()
        }
        //选中状态
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = selectedBackgroundView
        //cell的内容
        let actionInfo = viewInfo.actionsInfo[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.font = actionInfo.titleFont
        cell.textLabel?.textColor = .black
        cell.textLabel?.text = actionInfo.title
        if let image = actionInfo.image {
            let tempImageView = UIImageView(frame: CGRect(origin: .zero, size: actionInfo.image?.size ?? .zero))
            tempImageView.image = image
            cell.accessoryView = tempImageView
            cell.textLabel?.textAlignment = .left
        } else {
            cell.accessoryView = nil
            cell.textLabel?.textAlignment = .center
        }
        return cell
    }
}

// MARK: UITableViewDelegate

extension SCReviewView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let closure = didClickedClosure {
            closure(indexPath.row)
        }
    }
    
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return heightOfActionCell
    }
}

extension SCReviewView {
    /// 整体视图初始化信息，其默认值为最常用的页面的相关参数
    struct ViewInfo {
        var image: UIImage //顶部图片
        var imageSize = CGSize(width: 49, height: 49) //图片大小
        var imageTop: CGFloat = 24 //图片与父视图顶部距离
        var title: String //标题文案
        var spaceBetweenImageAndTitle: CGFloat = 20 //图片底部和标题顶部之间的距离
        var spaceBetweenArcBGAndTitle: CGFloat = 26 //标题底部和圆弧底部之间的距离
        var actionsInfo: [SCReviewView.ActionInfo] //可点击视图，每个action占一行，视图会根据数组从上往下自动填充视图
    }

    /// 可点击视图的初始化信息
    struct ActionInfo {
        var title = "invite_comment_btn_no_review".localized()  //文字标题
        var titleFont = UIFont.systemFont(ofSize: 18) //标题字体
        var image: UIImage? = nil //图片，如果有图片则标题和图片水平排列，标题居左，标题居右
    }
}
