//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SportRecordMonthView.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/17.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit

class SportRecordMonthView: UITableViewHeaderFooterView {
    var contView: UIView!
    var collectionView: UICollectionView!
    var selectedIndex = 0
    var delegate: SportRecordMonthViewDelegate?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initializeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        contentView.backgroundColor = UIColor.color(hex: "F2F2F2")
        contView = UIView().then {
            $0.backgroundColor = UIColor.white
        }
        contentView.addSubview(contView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ScreenWidth / 6, height: 46)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout).then {
            $0.backgroundColor = UIColor.white
            $0.dataSource = self
            $0.delegate = self
            $0.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false 
        }
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.top.equalTo(14)
        }
    }
}

extension SportRecordMonthView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        var selectedImageView = cell.contentView.viewWithTag(2) as? UIImageView
        if selectedImageView == nil {
            selectedImageView = UIImageView().then {
                $0.layer.cornerRadius = 11
                $0.backgroundColor = UIColor.color(hex: "D5D5D5")
                $0.clipsToBounds = true
                $0.isHidden = true
                $0.tag = 2
            }
            cell.contentView.addSubview(selectedImageView!)
        }
        selectedImageView?.snp.makeConstraints {
            $0.width.equalTo(45)
            $0.height.equalTo(22)
            $0.center.equalToSuperview()
        }
        selectedImageView?.isHidden = indexPath.row != selectedIndex
        var label = cell.contentView.viewWithTag(1) as? UILabel
        if label == nil {
            label = UILabel().then {
                $0.textColor = UIColor.color(hex: "727272")
                $0.font = UIFont.systemFont(ofSize: 14)
                $0.tag = 1
                $0.textAlignment = .center
            }
            cell.contentView.addSubview(label!)
        }
        label?.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        label?.text = "\(indexPath.row + 1)月"
        return cell
    }
}

extension SportRecordMonthView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        collectionView.reloadData()
        delegate?.callbackSelectedMonth(indexPath.row)
    }
}

protocol SportRecordMonthViewDelegate: NSObjectProtocol {
    func callbackSelectedMonth(_ value: Int)
}
