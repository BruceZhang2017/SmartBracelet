//
//  HeartRateView.swift
//  SmartBracelet
//
//  Created by anker on 2021/4/17.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class HeartRateView: UIView {
    var collectionView: UICollectionView!
    var heartRateArray = Array(repeating: 0, count: 24)
    
    override init(frame: CGRect) { // 建议width - 242, height 50
        super.init(frame: frame)
        backgroundColor = UIColor.white
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 10, height: 50)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout).then {
            $0.backgroundColor = UIColor.white
            $0.dataSource = self
            $0.delegate = self
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false
            $0.register(HeartRateCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        }
        addSubview(collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension HeartRateView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return heartRateArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! HeartRateCollectionViewCell
        cell.value = CGFloat(heartRateArray[indexPath.row])
        cell.refreshUI()
        return cell
    }
    
    
}

extension HeartRateView: UICollectionViewDelegateFlowLayout {
    
}
