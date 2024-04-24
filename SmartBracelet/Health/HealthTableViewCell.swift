//
//  HealthTableViewCell.swift
//  SmartBracelet
//
//  Created by anker on 2024/4/14.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class HealthTableViewCell: UITableViewCell {
    
    let containerView = UIView()
    let iconImageView = UIImageView()
    let leftTitleLabel = UILabel()
    let rightTitleLabel = UILabel()
    let temImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        // 添加容器视图到cell
        addSubview(containerView)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.backgroundColor = UIColor.white
        containerView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(6)
            make.bottom.equalTo(-6)
        }

        // 将子视图添加到容器视图中
        containerView.addSubview(iconImageView)
        containerView.addSubview(leftTitleLabel)
        leftTitleLabel.font = UIFont.title()
        leftTitleLabel.textColor = UIColor.text_primary
        containerView.addSubview(rightTitleLabel)
        
        containerView.addSubview(temImageView)
        
        // 配置子视图的约束或者frame
        // 注意：现在我们将约束添加到containerView上，而不是cell本身
        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.top.equalTo(20)
            make.width.height.equalTo(44)
        }
        
        leftTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
        }
        
        rightTitleLabel.snp.makeConstraints { make in
            make.trailing.equalTo(-16)
            make.centerY.equalTo(iconImageView)
        }
        
        temImageView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.height.equalTo(97)
        }

        // 设置子视图的约束
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 可以添加一个方法来配置cell
    func configureCell(icon: UIImage?, leftTitle: String, rightTitle: NSMutableAttributedString) {
        iconImageView.image = icon
        leftTitleLabel.text = leftTitle
        rightTitleLabel.attributedText = rightTitle
    }
    
    // 设置子视图的约束的方法
    private func setupConstraints() {
        // 使用Auto Layout或者其他布局框架来设置约束
        // 例如:
         iconImageView.translatesAutoresizingMaskIntoConstraints = false
         leftTitleLabel.translatesAutoresizingMaskIntoConstraints = false
         rightTitleLabel.translatesAutoresizingMaskIntoConstraints = false
         //NSLayoutConstraint.activate([...])
    }
}
