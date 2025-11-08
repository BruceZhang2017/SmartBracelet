//
//  VerticalLabelsCollectionCell.swift
//  Adorone
//
//  Created by WuJunjie on 2017/12/12.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import UIKit

class VerticalLabelsCollectionCell: UICollectionViewCell {
    var labels = VerticalLabels1()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(labels)
        labels.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
