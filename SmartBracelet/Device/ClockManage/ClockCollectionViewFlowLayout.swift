//
//  ClockCollectionViewFlowLayout.swift
//  SmartBracelet
//
//  Created by anker on 2021/7/29.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class ClockCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        let attributes = super.layoutAttributesForElements(in: rect)
        
        if attributes?.count == 1 {
            
            if let currentAttribute = attributes?.first {
                currentAttribute.frame = CGRect(x: self.sectionInset.left, y: currentAttribute.frame.origin.y, width: currentAttribute.frame.size.width, height: currentAttribute.frame.size.height)
            }
            
        }
       
        return attributes
        
    }
    
}
