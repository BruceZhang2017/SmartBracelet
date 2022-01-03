//
//  CustomImageFooterView.swift
//  SmartBracelet
//
//  Created by anker on 2022/1/3.
//  Copyright © 2022 tjd. All rights reserved.
//

import UIKit

class CustomImageFooterView: UIView {
    var collectionView: UICollectionView!
    weak var delegate: CustomImageFooterViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.headerReferenceSize = .zero
        flowLayout.footerReferenceSize = .zero
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 160), collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.white
        addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension CustomImageFooterView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ScreenWidth / 4, height: 160)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("当前点击的是：\(indexPath.item)")
        delegate?.callbackForSelectImage(collectionView: collectionView, index: indexPath.item)
    }
}

extension CustomImageFooterView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        var iv = cell.viewWithTag(1) as? UIImageView
        if iv == nil {
            iv = UIImageView()
            cell.contentView.addSubview(iv!)
            iv?.snp.makeConstraints {
                $0.width.equalTo(80)
                $0.height.equalTo(160)
                $0.center.equalToSuperview()
            }
            iv?.tag = 1
        }
        iv?.image = UIImage(named: "\(indexPath.row + 1)_80_160")
        cell.backgroundColor = UIColor.white
        return cell
    }
    
    
    
}

protocol CustomImageFooterViewDelegate: NSObjectProtocol {
    func callbackForSelectImage(collectionView: UICollectionView, index: Int)
}
