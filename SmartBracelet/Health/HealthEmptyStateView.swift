//
//  HealthEmptyStateView.swift
//  SmartBracelet
//
//  Created by GPT on 2026/6/28.
//

import UIKit

final class HealthEmptyStateView: UIView {
    private let cardView = UIView()
    private let artworkContainerView = UIView()
    private let primaryDecorationView = UIView()
    private let secondaryDecorationView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private let overlayGradientLayer = CAGradientLayer()
    
    var primaryAction: (() -> Void)?
    var secondaryAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        overlayGradientLayer.frame = artworkContainerView.bounds
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: cardView.layer.cornerRadius).cgPath
        primaryDecorationView.layer.cornerRadius = primaryDecorationView.bounds.height / 2
        secondaryDecorationView.layer.cornerRadius = secondaryDecorationView.bounds.height / 2
    }
    
    func configure(image: UIImage?, title: String, subtitle: String, primaryTitle: String?, secondaryTitle: String?) {
        imageView.image = image
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        primaryButton.setTitle(primaryTitle, for: .normal)
        secondaryButton.setTitle(secondaryTitle, for: .normal)
        
        primaryButton.isHidden = primaryTitle == nil
        secondaryButton.isHidden = secondaryTitle == nil
        buttonStackView.isHidden = primaryTitle == nil && secondaryTitle == nil
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        cardView.layer.cornerRadius = 28
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowColor = UIColor.brand.withAlphaComponent(0.12).cgColor
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowRadius = 22
        cardView.layer.shadowOffset = CGSize(width: 0, height: 12)
        addSubview(cardView)
        
        artworkContainerView.layer.cornerRadius = 22
        artworkContainerView.layer.cornerCurve = .continuous
        artworkContainerView.layer.masksToBounds = true
        artworkContainerView.backgroundColor = UIColor(hex: 0xF4F9FF)
        cardView.addSubview(artworkContainerView)
        
        overlayGradientLayer.colors = [
            UIColor.brand.withAlphaComponent(0.10).cgColor,
            UIColor(hex: 0x63B6FF).withAlphaComponent(0.18).cgColor
        ]
        overlayGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        overlayGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        artworkContainerView.layer.insertSublayer(overlayGradientLayer, at: 0)
        
        primaryDecorationView.backgroundColor = UIColor.brand.withAlphaComponent(0.12)
        secondaryDecorationView.backgroundColor = UIColor(hex: 0x63B6FF).withAlphaComponent(0.16)
        artworkContainerView.addSubview(primaryDecorationView)
        artworkContainerView.addSubview(secondaryDecorationView)
        
        imageView.contentMode = .scaleAspectFit
        artworkContainerView.addSubview(imageView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.text_primary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        cardView.addSubview(titleLabel)
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor.text_secondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        cardView.addSubview(subtitleLabel)
        
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        cardView.addSubview(buttonStackView)
        
        configurePrimaryButton(primaryButton)
        configureSecondaryButton(secondaryButton)
        
        primaryButton.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)
        secondaryButton.addTarget(self, action: #selector(handleSecondaryAction), for: .touchUpInside)
        
        buttonStackView.addArrangedSubview(primaryButton)
        buttonStackView.addArrangedSubview(secondaryButton)
    }
    
    private func setupConstraints() {
        [cardView, artworkContainerView, primaryDecorationView, secondaryDecorationView, imageView, titleLabel, subtitleLabel, buttonStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            
            artworkContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            artworkContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            artworkContainerView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            artworkContainerView.heightAnchor.constraint(equalToConstant: 184),
            
            primaryDecorationView.widthAnchor.constraint(equalToConstant: 130),
            primaryDecorationView.heightAnchor.constraint(equalToConstant: 130),
            primaryDecorationView.trailingAnchor.constraint(equalTo: artworkContainerView.trailingAnchor, constant: 36),
            primaryDecorationView.topAnchor.constraint(equalTo: artworkContainerView.topAnchor, constant: -32),
            
            secondaryDecorationView.widthAnchor.constraint(equalToConstant: 100),
            secondaryDecorationView.heightAnchor.constraint(equalToConstant: 100),
            secondaryDecorationView.leadingAnchor.constraint(equalTo: artworkContainerView.leadingAnchor, constant: -18),
            secondaryDecorationView.bottomAnchor.constraint(equalTo: artworkContainerView.bottomAnchor, constant: 28),
            
            imageView.centerXAnchor.constraint(equalTo: artworkContainerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: artworkContainerView.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: artworkContainerView.widthAnchor, multiplier: 0.72),
            imageView.heightAnchor.constraint(equalToConstant: 132),
            
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: artworkContainerView.bottomAnchor, constant: 20),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 28),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -28),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            
            buttonStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            buttonStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 22),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50),
            buttonStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -22)
        ])
    }
    
    private func configurePrimaryButton(_ button: UIButton) {
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor.brand
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
    
    private func configureSecondaryButton(_ button: UIButton) {
        button.setTitleColor(UIColor.brand, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor.brand.withAlphaComponent(0.08)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.brand.withAlphaComponent(0.16).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
    
    @objc private func handlePrimaryAction() {
        primaryAction?()
    }
    
    @objc private func handleSecondaryAction() {
        secondaryAction?()
    }
}
