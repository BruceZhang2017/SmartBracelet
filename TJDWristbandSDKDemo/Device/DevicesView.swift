//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DevicesView.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/8/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DevicesView: UIView {
    var collectionView : UICollectionView!
    weak var delegate: DevicesViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollection()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCollection() {
        let padding: CGFloat = 20
        let layout = CyclicCardFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = padding
        layout.sectionInset = UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0)
        let itemW = (ScreenWidth - padding * 2) / 2
        layout.itemSize = CGSize(width: itemW, height: 110)
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 200), collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.collectionViewLayout = layout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CyclicCardCell.self, forCellWithReuseIdentifier: NSStringFromClass(CyclicCardCell.self))
        addSubview(self.collectionView)
        collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
    }

}

extension DevicesView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(CyclicCardCell.self), for: indexPath) as! CyclicCardCell
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        cell.layer.cornerRadius = 10
//        let index = indexArr[indexPath.row]
//        cell.index = index
        cell.cardImgView.image = UIImage(named: "produce_image_no.2")
        cell.cardNameLabel.text = "小蜗牛"
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CyclicCardCell
        print("点击第\(cell.index + 1)张图片")
        delegate?.callbackTap(index: indexPath.row)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
//        let pointInView = view.convert(collectionView.center, to: collectionView)
//        let indexPathNow = collectionView.indexPathForItem(at: pointInView)
//        let index = (indexPathNow?.row ?? 0) % imageArr.count
//        let curIndexStr = String(format: "滚动至第%d张", index + 1)
//        print(curIndexStr)
//        showLabel.text = curIndexStr
//
//        // 动画停止, 重新定位到 第50组(中间那组) 模型
//        collectionView.scrollToItem(at: NSIndexPath.init(item: groupCount / 2 * imageArr.count + index, section: 0) as IndexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
    }
}

protocol DevicesViewDelegate: NSObjectProtocol {
    func callbackTap(index: Int)
}
