//
//  EditClcokBottomTableViewCell.swift
//  SmartBracelet
//
//  Created by anker on 2021/12/12.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class EditClcokBottomTableViewCell: UITableViewCell {
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    var colors: [UIColor] = [UIColor.white, UIColor.black, UIColor.yellow,
                             UIColor(red: 232/255.0, green: 149/255.0, blue: 102/255.0, alpha: 1),
                             UIColor(red: 229/255.0, green: 120/255.0, blue: 131/255.0, alpha: 1),
                             UIColor(red: 171/255.0, green: 140/255.0, blue: 218/255.0, alpha: 1),
                             UIColor(red: 121/255.0, green: 168/255.0, blue: 232/255.0, alpha: 1),
                             UIColor(red: 154/255.0, green: 227/255.0, blue: 224/255.0, alpha: 1),
                             UIColor(red: 155/255.0, green: 226/255.0, blue: 163/255.0, alpha: 1)]
    var index = 0
    weak var delegate: EditClcokBottomTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView?.isScrollEnabled = false
        colorLabel.text = "text_color".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func rgbToUIColor(rgb: Int) -> UIColor {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    func colorDistance(color1: UIColor, color2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let redDiff = r1 - r2
        let greenDiff = g1 - g2
        let blueDiff = b1 - b2
        
        return sqrt(redDiff * redDiff + greenDiff * greenDiff + blueDiff * blueDiff)
    }

    func dialColorToIndex(dialColor: Int) -> Int? {
        let targetColor = rgbToUIColor(rgb: dialColor)
        var closestIndex: Int?
        var smallestDistance: CGFloat = .greatestFiniteMagnitude
        
        for (index, color) in colors.enumerated() {
            let distance = colorDistance(color1: targetColor, color2: color)
            if distance < smallestDistance {
                smallestDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }

    func indexToDialColor(index: Int) -> Int? {
        guard index >= 0 && index < colors.count else {
            return nil
        }
        
        let color = colors[index]
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let red = Int(r * 255) << 16
        let green = Int(g * 255) << 8
        let blue = Int(b * 255)
        
        return red | green | blue
    }

}

extension EditClcokBottomTableViewCell: UICollectionViewDelegateFlowLayout {
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
        return CGSize(width: ScreenWidth / 9, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isXGZT {
            index = indexToDialColor(index: indexPath.item) ?? 0
        } else {
            index = indexPath.item
        }
        XLogger.shared.log("当前点击的是：\(index)")
        delegate?.callbackForSelectColor(collectionView: collectionView, index: index)
    }
}

extension EditClcokBottomTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! EditClockCollectionViewCell
        cell.bigImageView.layer.backgroundColor = UIColor.black.cgColor
        cell.smallImageVIew.layer.backgroundColor = colors[indexPath.item].cgColor
        if isXGZT {
            let i = dialColorToIndex(dialColor: index) ?? 0
            XLogger.shared.log("当前选中是：\(i)")
            cell.bigImageView.isHidden = i != indexPath.item
        } else {
            cell.bigImageView.isHidden = index != indexPath.item
        }
        

        return cell
    }
    
    
    
}

protocol EditClcokBottomTableViewCellDelegate: NSObjectProtocol {
    func callbackForSelectColor(collectionView: UICollectionView, index: Int)
}
