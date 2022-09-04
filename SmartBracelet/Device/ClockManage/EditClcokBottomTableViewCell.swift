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
        print("当前点击的是：\(indexPath.item)")
        index = indexPath.item
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
        cell.bigImageView.isHidden = index != indexPath.item

        return cell
    }
    
    
    
}

protocol EditClcokBottomTableViewCellDelegate: NSObjectProtocol {
    func callbackForSelectColor(collectionView: UICollectionView, index: Int)
}
