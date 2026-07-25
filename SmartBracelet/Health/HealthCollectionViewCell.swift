//
//  HealthCollectionViewCell.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/14.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

class HealthCollectionViewCell: UICollectionViewCell {
    
    //  MARK: - UI Components
    let containerView = UIView()
    let iconImageView = UIImageView()
    let leftTitleLabel = UILabel()
    let rightTitleLabel = UILabel()
    
    //  MARK: - Reuse Identifier
    static let reuseIdentifier = "HealthCollectionViewCell"
    
    //  MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //  MARK: - Setup
    private func setupViews() {
        // 基础配置
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        // 容器视图
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.backgroundColor = UIColor.white
        containerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.addSubview(containerView)
        
        // 图标配置
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        // 左侧标题
        leftTitleLabel.font = UIFont.body()
        leftTitleLabel.textColor = UIColor.text_primary
        leftTitleLabel.numberOfLines = 2
        leftTitleLabel.lineBreakMode = .byWordWrapping
        leftTitleLabel.adjustsFontSizeToFitWidth = true
        leftTitleLabel.minimumScaleFactor = 0.75
        containerView.addSubview(leftTitleLabel)
        
        // 右侧数值
        rightTitleLabel.textAlignment = .right
        containerView.addSubview(rightTitleLabel)
    }
    
    private func setupConstraints() {
        // 禁用 autoresizing mask
        [containerView, iconImageView, leftTitleLabel, rightTitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // 容器视图约束 - 充满整个contentView
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // 图标约束
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 50),
            iconImageView.widthAnchor.constraint(equalToConstant: 44),
            iconImageView.heightAnchor.constraint(equalToConstant: 44),
            
            // 左侧标题约束
            leftTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            leftTitleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            leftTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // 右侧数值约束 - 直接与容器右侧对齐
            rightTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            rightTitleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 105)
        ])
    }
    
    //  MARK: - Configuration
    func configureCell(icon: UIImage?, leftTitle: String, rightTitle: NSMutableAttributedString) {
        iconImageView.image = icon
        leftTitleLabel.text = leftTitle
        rightTitleLabel.attributedText = rightTitle
    }
    
    // 重写prepareForReuse方法，重置单元格状态
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        leftTitleLabel.text = nil
        rightTitleLabel.attributedText = nil
    }
}
