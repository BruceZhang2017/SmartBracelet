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
    private let shadowView = UIView()
    let containerView = UIView()
    private let accentBarView = UIView()
    private let iconBackgroundView = UIView()
    let iconImageView = UIImageView()
    let leftTitleLabel = UILabel()
    let rightTitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    
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
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        contentView.clipsToBounds = false
        
        shadowView.backgroundColor = UIColor.clear
        shadowView.layer.shadowColor = UIColor.brand.withAlphaComponent(0.10).cgColor
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 18
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        contentView.addSubview(shadowView)
        
        containerView.layer.cornerRadius = 24
        containerView.layer.cornerCurve = .continuous
        containerView.clipsToBounds = true
        containerView.backgroundColor = UIColor.white
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.brand.withAlphaComponent(0.08).cgColor
        shadowView.addSubview(containerView)
        
        accentBarView.layer.cornerRadius = 2.5
        accentBarView.layer.cornerCurve = .continuous
        containerView.addSubview(accentBarView)
        
        iconBackgroundView.backgroundColor = UIColor.fill
        iconBackgroundView.layer.cornerRadius = 21
        iconBackgroundView.layer.cornerCurve = .continuous
        containerView.addSubview(iconBackgroundView)
        
        iconImageView.contentMode = .scaleAspectFit
        iconBackgroundView.addSubview(iconImageView)
        
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor.text_third
        chevronImageView.contentMode = .scaleAspectFit
        containerView.addSubview(chevronImageView)
        
        leftTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        leftTitleLabel.textColor = UIColor.text_primary
        leftTitleLabel.numberOfLines = 2
        containerView.addSubview(leftTitleLabel)
        
        rightTitleLabel.textAlignment = .left
        rightTitleLabel.numberOfLines = 3
        rightTitleLabel.adjustsFontSizeToFitWidth = true
        rightTitleLabel.minimumScaleFactor = 0.75
        containerView.addSubview(rightTitleLabel)
    }
    
    private func setupConstraints() {
        [shadowView, containerView, accentBarView, iconBackgroundView, iconImageView, leftTitleLabel, rightTitleLabel, chevronImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            containerView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
            
            accentBarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            accentBarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            accentBarView.widthAnchor.constraint(equalToConstant: 28),
            accentBarView.heightAnchor.constraint(equalToConstant: 4),
            
            iconBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            iconBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 42),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 42),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            chevronImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            
            leftTitleLabel.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 12),
            leftTitleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 19),
            leftTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -8),
            
            rightTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            rightTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            rightTitleLabel.topAnchor.constraint(greaterThanOrEqualTo: iconBackgroundView.bottomAnchor, constant: 14),
            rightTitleLabel.topAnchor.constraint(greaterThanOrEqualTo: leftTitleLabel.bottomAnchor, constant: 12),
            rightTitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    //  MARK: - Configuration
    func configureCell(icon: UIImage?, leftTitle: String, rightTitle: NSMutableAttributedString, accentColor: UIColor) {
        accentBarView.backgroundColor = accentColor
        iconBackgroundView.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconImageView.tintColor = accentColor
        iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        leftTitleLabel.text = leftTitle
        rightTitleLabel.attributedText = rightTitle
        chevronImageView.tintColor = accentColor.withAlphaComponent(0.62)
        containerView.backgroundColor = accentColor.withAlphaComponent(0.05)
        containerView.layer.borderColor = accentColor.withAlphaComponent(0.10).cgColor
        shadowView.layer.shadowColor = accentColor.withAlphaComponent(0.12).cgColor
    }
    
    // 重写prepareForReuse方法，重置单元格状态
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        leftTitleLabel.text = nil
        rightTitleLabel.attributedText = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: containerView.layer.cornerRadius).cgPath
    }
    
    func setHighlightedState(_ highlighted: Bool) {
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            self.shadowView.layer.shadowRadius = highlighted ? 12 : 18
            self.shadowView.layer.shadowOpacity = highlighted ? 0.78 : 1
        }
    }
}
