//
//  VerticalLabels.swift
//  Adorone
//
//  Created by WuJunjie on 2017/12/12.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import UIKit
import SnapKit

enum VerticalLabelsAlignment {
    case center
    case left
    case right
}

//垂直显示的两个label
class VerticalLabels: UIView {
    private var content = UIView()
    var nameLabel = UILabel()
    var nameLabel1 = UILabel()
    var spaceConstraint: Constraint!
    var alignment = VerticalLabelsAlignment.center {
        didSet {
            setAlignment(alignment)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(content)
        content.snp.makeConstraints { (make) in
            make.width.height.lessThanOrEqualToSuperview()
            make.center.equalToSuperview()
        }
        
        content.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        nameLabel.textColor = UIColor.red
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byCharWrapping
        
        content.addSubview(nameLabel1)
        nameLabel1.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualToSuperview()
            spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        nameLabel1.textColor = UIColor.red
        nameLabel1.font = UIFont.systemFont(ofSize: 16)
        nameLabel1.numberOfLines = 0
        nameLabel1.lineBreakMode = .byCharWrapping
    }
    
    func setAlignment(_ align: VerticalLabelsAlignment) {
        if align == .center {
            content.layout { (make) in
                make.width.height.lessThanOrEqualToSuperview()
                make.center.equalToSuperview()
            }
            
            nameLabel.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            nameLabel1.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        }
        
        if align == .left {
            content.layout { (make) in
                make.width.height.lessThanOrEqualToSuperview()
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            nameLabel.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                make.top.equalToSuperview()
                 make.left.equalToSuperview()
            }
            
            nameLabel1.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
            }
        }
        
        if align == .right {
            content.layout { (make) in
                make.width.height.lessThanOrEqualToSuperview()
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            nameLabel.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            nameLabel1.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
                make.bottom.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


class VerticalLabels1: UIView {
    private var content = UIView()
    var nameLabel = UILabel()
    var nameLabel1 = UILabel()
    var nameLabel2 = UILabel()
    var spaceConstraint: Constraint!
    var spaceConstraint1: Constraint!
    var alignment = VerticalLabelsAlignment.center {
        didSet {
            setAlignment(alignment)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        content.adhere(toSuperView: self).layout { (make) in
            make.width.height.lessThanOrEqualToSuperview()
            make.center.equalToSuperview()
            }
            .config { (make) in
                
        }
        
        nameLabel.adhere(toSuperView: content).layout { (make) in
            make.width.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            }
            .config { (make) in
                make.textColor = UIColor.red
                make.font = UIFont.systemFont(ofSize: 16)
                make.numberOfLines = 0
                make.lineBreakMode = .byCharWrapping
        }
        
        nameLabel1.adhere(toSuperView: content).layout { (make) in
            make.width.lessThanOrEqualToSuperview()
            spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
            make.centerX.equalToSuperview()
            }
            .config { (make) in
                make.textColor = UIColor.red
                make.font = UIFont.systemFont(ofSize: 16)
                make.numberOfLines = 0
                make.lineBreakMode = .byCharWrapping
        }
        
        nameLabel2.adhere(toSuperView: content).layout { (make) in
            spaceConstraint1 = make.top.equalTo(nameLabel1.snp.bottom).offset(5).constraint
            make.width.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            }
            .config { (make) in
                make.textColor = UIColor.red
                make.font = UIFont.systemFont(ofSize: 16)
                make.numberOfLines = 0
                make.lineBreakMode = .byCharWrapping
        }
    }
    
    func setAlignment(_ align: VerticalLabelsAlignment) {
        if align == .center {
            content.layout { (make) in
                make.width.height.lessThanOrEqualToSuperview()
                make.center.equalToSuperview()
            }
            
            nameLabel.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            nameLabel1.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
                make.centerX.equalToSuperview()
            }
            
            nameLabel2.adhere(toSuperView: content).layout { (make) in
                spaceConstraint1 = make.top.equalTo(nameLabel1.snp.bottom).offset(5).constraint
                make.width.lessThanOrEqualToSuperview()
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview()
                }
                .config { (make) in
                    make.textColor = UIColor.red
                    make.font = UIFont.systemFont(ofSize: 16)
                    make.numberOfLines = 0
                    make.lineBreakMode = .byCharWrapping
            }
        }
        
        if align == .left {
            content.layout { (make) in
                make.width.height.lessThanOrEqualToSuperview()
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            nameLabel.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                make.top.equalToSuperview()
                make.left.equalToSuperview()
            }
            
            nameLabel1.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
                make.left.equalToSuperview()
            }
            
            nameLabel2.adhere(toSuperView: content).layout { (make) in
                spaceConstraint1 = make.top.equalTo(nameLabel1.snp.bottom).offset(5).constraint
                make.width.lessThanOrEqualToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
                }
                .config { (make) in
                    make.textColor = UIColor.red
                    make.font = UIFont.systemFont(ofSize: 16)
                    make.numberOfLines = 0
                    make.lineBreakMode = .byCharWrapping
            }
        }
        
        if align == .right {
            content.layout { (make) in
                make.width.height.lessThanOrEqualToSuperview()
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            nameLabel.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            nameLabel1.layout { (make) in
                make.width.lessThanOrEqualToSuperview()
                spaceConstraint = make.top.equalTo(nameLabel.snp.bottom).offset(5).constraint
                make.right.equalToSuperview()
            }
            
            nameLabel2.adhere(toSuperView: content).layout { (make) in
                spaceConstraint1 = make.top.equalTo(nameLabel1.snp.bottom).offset(5).constraint
                make.width.lessThanOrEqualToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
                }
                .config { (make) in
                    make.textColor = UIColor.red
                    make.font = UIFont.systemFont(ofSize: 16)
                    make.numberOfLines = 0
                    make.lineBreakMode = .byCharWrapping
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
