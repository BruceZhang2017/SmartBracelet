//
//  HealthValueView.swift
//  SmartBracelet
//
//  Created by anker on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class HealthValueView: UIView {
    
    let topLabel = UILabel()
    let imageView = UIImageView()
    let bottomLabel = UILabel()
    let descLabel = UILabel()
    
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
        topLabel.text = "趋势"
        topLabel.textColor = UIColor.text_primary
        topLabel.font = UIFont.subtitle()
        addSubview(topLabel)
        
        // 配置图片视图
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "health_null_data") // 替换为你的图片名
        addSubview(imageView)
        
        // 配置底部标签
        bottomLabel.text = "暂无数据"
        bottomLabel.textAlignment = .center
        bottomLabel.textColor = UIColor.text_secondary
        bottomLabel.font = UIFont.subtitle()
        addSubview(bottomLabel)
        
        descLabel.text = ""
        descLabel.textColor = UIColor.text_third
        descLabel.font = UIFont.body2()
        addSubview(descLabel)
    }
    
    private func setupConstraints() {
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            bottomLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        descLabel.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalTo(topLabel)
        }
    }
    
    public func refreshView(isHideNull: Bool) {
        imageView.isHidden = isHideNull
        bottomLabel.isHidden = isHideNull
    }
    
    public func refreshLabel(text: String) {
        descLabel.text = text
    }
}
