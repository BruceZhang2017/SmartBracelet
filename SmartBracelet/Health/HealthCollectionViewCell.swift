//
//  HealthCollectionViewCell.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/14.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImage {
    static func ecgHeartIcon(size: CGFloat = 64) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let heartStroke = UIColor(red: 0.24, green: 0.53, blue: 0.97, alpha: 1.0)
            let ecgStroke = UIColor(red: 1.00, green: 0.23, blue: 0.29, alpha: 1.0)
            let heartRect = CGRect(x: 2, y: 2, width: size - 4, height: size - 4)

            let heart = UIBezierPath()
            let w = heartRect.width
            let h = heartRect.height
            let x0 = heartRect.minX
            let y0 = heartRect.minY
            heart.move(to: CGPoint(x: x0 + w * 0.50, y: y0 + h * 0.92))
            heart.addCurve(to: CGPoint(x: x0 + w * 0.08, y: y0 + h * 0.40),
                           controlPoint1: CGPoint(x: x0 + w * 0.50, y: y0 + h * 0.80),
                           controlPoint2: CGPoint(x: x0 + w * 0.10, y: y0 + h * 0.60))
            heart.addCurve(to: CGPoint(x: x0 + w * 0.50, y: y0 + h * 0.18),
                           controlPoint1: CGPoint(x: x0 + w * 0.06, y: y0 + h * 0.20),
                           controlPoint2: CGPoint(x: x0 + w * 0.30, y: y0 + h * 0.10))
            heart.addCurve(to: CGPoint(x: x0 + w * 0.92, y: y0 + h * 0.40),
                           controlPoint1: CGPoint(x: x0 + w * 0.70, y: y0 + h * 0.10),
                           controlPoint2: CGPoint(x: x0 + w * 0.94, y: y0 + h * 0.20))
            heart.addCurve(to: CGPoint(x: x0 + w * 0.50, y: y0 + h * 0.92),
                           controlPoint1: CGPoint(x: x0 + w * 0.90, y: y0 + h * 0.60),
                           controlPoint2: CGPoint(x: x0 + w * 0.50, y: y0 + h * 0.80))
            heart.close()
            heart.lineWidth = max(2.0, size * 0.045)
            heartStroke.setStroke()
            heart.stroke()

            let ecg = UIBezierPath()
            ecg.lineWidth = max(2.0, size * 0.038)
            ecg.lineCapStyle = .round
            ecg.lineJoinStyle = .round
            let midY = y0 + h * 0.56
            ecg.move(to: CGPoint(x: x0 + w * 0.08, y: midY))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.30, y: midY))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.35, y: y0 + h * 0.72))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.42, y: y0 + h * 0.24))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.50, y: y0 + h * 0.80))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.58, y: y0 + h * 0.36))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.64, y: midY))
            ecg.addLine(to: CGPoint(x: x0 + w * 0.92, y: midY))
            ecgStroke.setStroke()
            ecg.stroke()
        }
    }

    static func femaleCycleIcon(size: CGFloat = 64) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.78, weight: .regular)
            let image = UIImage(systemName: "heart.circle.fill", withConfiguration: configuration)?
                .withTintColor(UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0), renderingMode: .alwaysOriginal)
            image?.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}

class HealthCollectionViewCell: UICollectionViewCell {
    
    //  MARK: - UI Components
    let containerView = UIView()
    let iconImageView = UIImageView()
    let arrowImageView = UIImageView()
    let leftTitleLabel = UILabel()
    let leftSubtitleLabel = UILabel()
    let rightTitleLabel = UILabel()

    private var iconTrailingConstraint: NSLayoutConstraint!
    private var iconBottomConstraint: NSLayoutConstraint!
    private var iconLeadingConstraint: NSLayoutConstraint!
    private var iconCenterYConstraint: NSLayoutConstraint!
    private var iconLargeWidthConstraint: NSLayoutConstraint!
    private var iconLargeHeightConstraint: NSLayoutConstraint!
    private var iconSmallWidthConstraint: NSLayoutConstraint!
    private var iconSmallHeightConstraint: NSLayoutConstraint!
    private var titleLeadingToContainerConstraint: NSLayoutConstraint!
    private var titleLeadingToIconConstraint: NSLayoutConstraint!
    private var titleTrailingToContainerConstraint: NSLayoutConstraint!
    private var titleTrailingToArrowConstraint: NSLayoutConstraint!
    private var titleTopConstraint: NSLayoutConstraint!
    
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
        
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.backgroundColor = UIColor.white
        containerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.addSubview(containerView)
        
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)

        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = UIColor(red: 0.56, green: 0.59, blue: 0.63, alpha: 1.0)
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.isHidden = true
        containerView.addSubview(arrowImageView)
        
        leftTitleLabel.font = UIFont.body()
        leftTitleLabel.textColor = UIColor.text_primary
        leftTitleLabel.numberOfLines = 1
        containerView.addSubview(leftTitleLabel)
        
        leftSubtitleLabel.font = UIFont.body2()
        leftSubtitleLabel.textColor = UIColor.text_secondary
        leftSubtitleLabel.numberOfLines = 2
        leftSubtitleLabel.lineBreakMode = .byWordWrapping
        leftSubtitleLabel.isHidden = true
        containerView.addSubview(leftSubtitleLabel)
        
        rightTitleLabel.textAlignment = .right
        containerView.addSubview(rightTitleLabel)
    }
    
    private func setupConstraints() {
        [containerView, iconImageView, arrowImageView, leftTitleLabel, leftSubtitleLabel, rightTitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleTopConstraint = leftTitleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20)
        titleLeadingToContainerConstraint = leftTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18)
        titleLeadingToIconConstraint = leftTitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12)
        titleTrailingToContainerConstraint = leftTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18)
        titleTrailingToArrowConstraint = leftTitleLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -12)

        iconTrailingConstraint = iconImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18)
        iconBottomConstraint = iconImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        iconLeadingConstraint = iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        iconCenterYConstraint = iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        iconLargeWidthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: 64)
        iconLargeHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: 64)
        iconSmallWidthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: 40)
        iconSmallHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: 40)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleTopConstraint,
            titleLeadingToContainerConstraint,
            titleTrailingToContainerConstraint,
            
            leftSubtitleLabel.leadingAnchor.constraint(equalTo: leftTitleLabel.leadingAnchor),
            leftSubtitleLabel.topAnchor.constraint(equalTo: leftTitleLabel.bottomAnchor, constant: 6),
            leftSubtitleLabel.trailingAnchor.constraint(equalTo: leftTitleLabel.trailingAnchor),
            
            iconTrailingConstraint,
            iconBottomConstraint,
            iconLargeWidthConstraint,
            iconLargeHeightConstraint,
            
            rightTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            rightTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            rightTitleLabel.topAnchor.constraint(equalTo: leftSubtitleLabel.bottomAnchor, constant: 12),

            arrowImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    //  MARK: - Configuration
    func configureCell(icon: UIImage?, leftTitle: String, rightTitle: NSMutableAttributedString) {
        configure(icon: icon, title: leftTitle, subtitle: nil, rightTitle: rightTitle, style: .normal)
    }
    
    enum HealthCardStyle {
        case normal
        case ecg
        case femaleHealth
    }
    
    func configure(icon: UIImage?, title: String, subtitle: String?, rightTitle: NSMutableAttributedString, style: HealthCardStyle) {
        leftTitleLabel.text = title
        leftSubtitleLabel.text = subtitle
        leftSubtitleLabel.isHidden = subtitle?.isEmpty ?? true
        rightTitleLabel.attributedText = rightTitle
        rightTitleLabel.isHidden = false
        arrowImageView.isHidden = true
        titleTopConstraint.constant = 20
        titleLeadingToContainerConstraint.isActive = true
        titleTrailingToContainerConstraint.isActive = true
        titleLeadingToIconConstraint.isActive = false
        titleTrailingToArrowConstraint.isActive = false
        iconTrailingConstraint.isActive = true
        iconBottomConstraint.isActive = true
        iconLargeWidthConstraint.isActive = true
        iconLargeHeightConstraint.isActive = true
        iconLeadingConstraint.isActive = false
        iconCenterYConstraint.isActive = false
        iconSmallWidthConstraint.isActive = false
        iconSmallHeightConstraint.isActive = false
        
        switch style {
        case .normal:
            iconImageView.image = icon
            iconImageView.tintColor = nil
            containerView.backgroundColor = UIColor.white
            leftTitleLabel.textColor = UIColor.text_primary
            leftSubtitleLabel.textColor = UIColor.text_secondary
        case .ecg:
            iconImageView.image = icon ?? UIImage.ecgHeartIcon(size: 64)
            iconImageView.tintColor = nil
            containerView.backgroundColor = UIColor.white
            leftTitleLabel.textColor = UIColor.text_primary
            leftSubtitleLabel.textColor = UIColor.text_secondary
            rightTitleLabel.isHidden = true
            arrowImageView.isHidden = false
            titleTrailingToContainerConstraint.isActive = false
            titleTrailingToArrowConstraint.isActive = true
        case .femaleHealth:
            iconImageView.image = icon ?? UIImage.femaleCycleIcon(size: 64)
            iconImageView.tintColor = nil
            containerView.backgroundColor = UIColor.white
            leftTitleLabel.textColor = UIColor.text_primary
            leftSubtitleLabel.textColor = UIColor.text_secondary
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        leftTitleLabel.text = nil
        leftSubtitleLabel.text = nil
        leftSubtitleLabel.isHidden = true
        rightTitleLabel.attributedText = nil
        rightTitleLabel.isHidden = false
        arrowImageView.isHidden = true
        iconImageView.tintColor = nil
        containerView.backgroundColor = UIColor.white
    }
}
