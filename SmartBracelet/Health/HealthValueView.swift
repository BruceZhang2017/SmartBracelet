//
//  HealthValueView.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class HealthValueView: UIView {
    
    let topLabel = UILabel()
    let imageView = UIImageView()
    let bottomLabel = UILabel()
    let descLabel = UILabel()
    let detailLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        // 设置视图的圆角
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // 上左和上右圆角
        clipsToBounds = true
        
        // 配置顶部标签
        topLabel.text = "qushi".localized()
        topLabel.textColor = UIColor.text_primary
        topLabel.font = UIFont.subtitle()
        addSubview(topLabel)
        
        // 配置图片视图
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "health_null_data") // 替换为你的图片名
        addSubview(imageView)
        
        // 配置底部标签
        bottomLabel.text = "null_data".localized()
        bottomLabel.textAlignment = .center
        bottomLabel.textColor = UIColor.text_secondary
        bottomLabel.font = UIFont.subtitle()
        addSubview(bottomLabel)
        
        detailLabel.text = ""
        detailLabel.textAlignment = .center
        detailLabel.textColor = UIColor.text_third
        detailLabel.font = UIFont.body2()
        detailLabel.numberOfLines = 2
        addSubview(detailLabel)
        
        descLabel.text = ""
        descLabel.textColor = UIColor.text_third
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .right
        descLabel.font = UIFont.body2()
        addSubview(descLabel)
    }
    
    private func setupConstraints() {
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 顶部标签约束
            topLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            topLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            // 图片视图约束
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 82),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 139),
            imageView.widthAnchor.constraint(equalToConstant: 144),
            
            // 底部标签约束
            bottomLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            bottomLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            detailLabel.topAnchor.constraint(equalTo: bottomLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 42),
            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -42)
        ])
        
        descLabel.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.left.equalTo(100)
            make.centerY.equalTo(topLabel)
        }
    }
    
    public func refreshView(isHideNull: Bool) {
        imageView.isHidden = isHideNull
        bottomLabel.isHidden = isHideNull
        detailLabel.isHidden = isHideNull
    }
    
    public func refreshLabel(text: String) {
        descLabel.text = text
    }
    
    public func configureEmptyState(imageName: String?, title: String, subtitle: String) {
        if let imageName {
            imageView.image = UIImage(named: imageName) ?? UIImage(named: "health_null_data")
        }
        bottomLabel.text = title
        detailLabel.text = subtitle
    }
}
