//
//  SportDetailView.swift
//  LifeFit
//
//  Created by tjd on 2018/11/28.
//  Copyright © 2018年 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK

class SportDetailView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var collection: UICollectionView!
    var isInMainView = false
    var valueArray: [Double] = [0, 0, 0] {
        didSet {
            collection.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize.init(width: floor(kWuScreenWidth/3), height: 100)
        
        collection = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        collection.adhere(toSuperView: self).layout { (make) in
            make.edges.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
                make.register(ImageLabelsCollectionCell.self, forCellWithReuseIdentifier: ImageLabelsCollectionCell.wuClassName())
                make.contentInsetAdjustmentBehavior = .never
                
        }
    }
    
    let titleArray = ["sport_pace".localized(), "sport_duration".localized(), "consumption".localized()]
    // MARK: - collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageLabelsCollectionCell.wuClassName(), for: indexPath) as! ImageLabelsCollectionCell
        cell.nameLabel.text = titleArray[indexPath.row]
        
        if indexPath.row == 0 {
            cell.valueLabel.text = Int(valueArray[0]).stringSpeedFromSecond()
        }
        if indexPath.row == 1 {
            cell.valueLabel.text = Int(valueArray[1]).stringHmsFromSecond()
        }
        if indexPath.row == 2 {
            cell.valueLabel.text = valueArray[2].stringFloor(2)
        }
        if isInMainView {
            cell.nameLabel.font.withSize(15)
            cell.valueLabel.font.withSize(30)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: floor(collectionView.frame.size.width/3), height: floor(collectionView.frame.size.height))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
