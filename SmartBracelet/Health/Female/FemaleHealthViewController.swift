//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  FemaleHealthViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2025/12/04.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

class FemaleHealthViewController: BaseViewController {

    // MARK: - Properties

    /// 是否隐藏最后一次月经日期选项（从周期设置进入时隐藏）
    var hideLastPeriodDateOption: Bool = false {
        didSet {
            updateStartButtonTitle()
            if isViewLoaded {
                updateLastPeriodVisibility()
            }
        }
    }

    private var hasAnimatedEntrance = false
    private let heroGradientLayer = CAGradientLayer()
    private let ctaGradientLayer = CAGradientLayer()
    private var cycleLengthBottomConstraint: Constraint?
    private var lastPeriodBottomConstraint: Constraint?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        return view
    }()

    private let contentView = UIView()

    private let heroCardView = UIView()
    private let heroPrimaryGlowView = UIView()
    private let heroSecondaryGlowView = UIView()

    private let heroBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_title".localized().uppercased()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = UIColor(red: 0.74, green: 0.16, blue: 0.44, alpha: 1.0)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        label.textAlignment = .center
        label.layer.cornerRadius = 13
        label.layer.masksToBounds = true
        return label
    }()

    private let heroTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_subtitle".localized()
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let heroSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.84)
        label.numberOfLines = 0
        return label
    }()

    private let heroArtworkContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        view.layer.cornerRadius = 42
        return view
    }()

    private let heroArtworkRingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        view.layer.cornerRadius = 32
        return view
    }()

    private let heroArtworkIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "heart.text.square.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let summaryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let periodPreviewCardView = UIView()
    private let cyclePreviewCardView = UIView()

    private let periodPreviewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_period_days".localized()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.76)
        return label
    }()

    private let cyclePreviewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_cycle_length".localized()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.76)
        return label
    }()

    private let periodPreviewValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let cyclePreviewValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let sectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_start_prediction".localized()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(red: 0.76, green: 0.28, blue: 0.49, alpha: 1.0)
        return label
    }()

    private let questionLabel1: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_period_days".localized()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(hex: 0x8D6672)
        label.numberOfLines = 0
        return label
    }()

    private let periodDaysContainerView = UIView()
    private let periodDaysIconContainerView = UIView()
    private let periodDaysIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "drop.fill"))
        imageView.tintColor = UIColor(red: 0.92, green: 0.30, blue: 0.53, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let periodDaysTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_period_days".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(hex: 0x25212B)
        return label
    }()

    private let periodDaysCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_period_days".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: 0x9097A0)
        label.numberOfLines = 2
        return label
    }()

    private let periodDaysValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = UIColor(red: 0.84, green: 0.25, blue: 0.47, alpha: 1.0)
        label.textAlignment = .right
        return label
    }()

    private let periodDaysArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0xB9A7AF)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let questionLabel2: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_cycle_length".localized()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(hex: 0x8D6672)
        label.numberOfLines = 0
        return label
    }()

    private let cycleLengthContainerView = UIView()
    private let cycleLengthIconContainerView = UIView()
    private let cycleLengthIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "waveform.path.ecg"))
        imageView.tintColor = UIColor(red: 0.48, green: 0.35, blue: 0.94, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let cycleLengthTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_cycle_length".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(hex: 0x25212B)
        return label
    }()

    private let cycleLengthCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_cycle_length".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: 0x9097A0)
        label.numberOfLines = 2
        return label
    }()

    private let cycleLengthValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = UIColor(red: 0.41, green: 0.34, blue: 0.89, alpha: 1.0)
        label.textAlignment = .right
        return label
    }()

    private let cycleLengthArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0xB9A7AF)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let questionLabel3: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_last_period".localized()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(hex: 0x8D6672)
        label.numberOfLines = 0
        return label
    }()

    private let lastPeriodContainerView = UIView()
    private let lastPeriodIconContainerView = UIView()
    private let lastPeriodIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "calendar"))
        imageView.tintColor = UIColor(red: 0.95, green: 0.56, blue: 0.39, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let lastPeriodTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_last_period_start_date".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(hex: 0x25212B)
        label.numberOfLines = 2
        return label
    }()

    private let lastPeriodCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_last_period".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: 0x9097A0)
        label.numberOfLines = 2
        return label
    }()

    private let lastPeriodValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(red: 0.89, green: 0.48, blue: 0.29, alpha: 1.0)
        label.textAlignment = .right
        return label
    }()

    private let lastPeriodArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0xB9A7AF)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let footerHintLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_subtitle".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: 0x9E8690)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let startPredictionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 26
        button.layer.cornerCurve = .continuous
        button.layer.shadowColor = UIColor(red: 0.93, green: 0.37, blue: 0.58, alpha: 0.34).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 16
        button.layer.shadowOffset = CGSize(width: 0, height: 10)
        return button
    }()

    // MARK: - Data

    private var periodDays: Int = 7 {
        didSet {
            updatePeriodDaysPresentation()
            saveFemaleHealthData()
        }
    }

    private var cycleLength: Int = 28 {
        didSet {
            updateCycleLengthPresentation()
            saveFemaleHealthData()
        }
    }

    private var lastPeriodDate: Date = Date() {
        didSet {
            updateLastPeriodPresentation()
            saveFemaleHealthData()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()

        title = "female_cycle_title".localized()

        setupUI()
        loadFemaleHealthData()
        updateStartButtonTitle()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradientLayer.frame = heroCardView.bounds
        ctaGradientLayer.frame = startPredictionButton.bounds
        startPredictionButton.layer.shadowPath = UIBezierPath(
            roundedRect: startPredictionButton.bounds,
            cornerRadius: startPredictionButton.layer.cornerRadius
        ).cgPath
        [heroPrimaryGlowView, heroSecondaryGlowView].forEach { glowView in
            glowView.layer.cornerRadius = glowView.bounds.height / 2
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntranceIfNeeded()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xFFF7FA)

        heroCardView.layer.cornerRadius = 30
        heroCardView.layer.cornerCurve = .continuous
        heroCardView.layer.masksToBounds = true

        heroGradientLayer.colors = [
            UIColor(red: 0.98, green: 0.45, blue: 0.67, alpha: 1.0).cgColor,
            UIColor(red: 0.72, green: 0.39, blue: 0.96, alpha: 1.0).cgColor
        ]
        heroGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        heroGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        heroCardView.layer.insertSublayer(heroGradientLayer, at: 0)

        heroPrimaryGlowView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        heroSecondaryGlowView.backgroundColor = UIColor.white.withAlphaComponent(0.12)

        [periodPreviewCardView, cyclePreviewCardView].forEach { view in
            view.backgroundColor = UIColor.white.withAlphaComponent(0.14)
            view.layer.cornerRadius = 18
            view.layer.cornerCurve = .continuous
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        }

        ctaGradientLayer.colors = [
            UIColor(red: 0.98, green: 0.45, blue: 0.67, alpha: 1.0).cgColor,
            UIColor(red: 0.82, green: 0.28, blue: 0.55, alpha: 1.0).cgColor
        ]
        ctaGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        ctaGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        startPredictionButton.layer.insertSublayer(ctaGradientLayer, at: 0)

        view.addSubview(startPredictionButton)
        view.addSubview(footerHintLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(startPredictionButton.snp.top).offset(-16)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        startPredictionButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-18)
            make.height.equalTo(52)
        }

        footerHintLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalTo(startPredictionButton.snp.top).offset(-10)
        }

        contentView.addSubview(heroCardView)
        heroCardView.addSubview(heroPrimaryGlowView)
        heroCardView.addSubview(heroSecondaryGlowView)
        heroCardView.addSubview(heroBadgeLabel)
        heroCardView.addSubview(heroTitleLabel)
        heroCardView.addSubview(heroSubtitleLabel)
        heroCardView.addSubview(heroArtworkContainerView)
        heroArtworkContainerView.addSubview(heroArtworkRingView)
        heroArtworkContainerView.addSubview(heroArtworkIconView)
        heroCardView.addSubview(summaryStackView)

        summaryStackView.addArrangedSubview(periodPreviewCardView)
        summaryStackView.addArrangedSubview(cyclePreviewCardView)
        periodPreviewCardView.addSubview(periodPreviewTitleLabel)
        periodPreviewCardView.addSubview(periodPreviewValueLabel)
        cyclePreviewCardView.addSubview(cyclePreviewTitleLabel)
        cyclePreviewCardView.addSubview(cyclePreviewValueLabel)

        contentView.addSubview(sectionHeaderLabel)
        contentView.addSubview(questionLabel1)
        contentView.addSubview(periodDaysContainerView)
        contentView.addSubview(questionLabel2)
        contentView.addSubview(cycleLengthContainerView)
        contentView.addSubview(questionLabel3)
        contentView.addSubview(lastPeriodContainerView)

        setupOptionCard(
            containerView: periodDaysContainerView,
            iconContainerView: periodDaysIconContainerView,
            iconImageView: periodDaysIconImageView,
            titleLabel: periodDaysTitleLabel,
            captionLabel: periodDaysCaptionLabel,
            valueLabel: periodDaysValueLabel,
            arrowImageView: periodDaysArrowImageView,
            iconBackgroundColor: UIColor(red: 1.0, green: 0.92, blue: 0.95, alpha: 1.0)
        )
        setupOptionCard(
            containerView: cycleLengthContainerView,
            iconContainerView: cycleLengthIconContainerView,
            iconImageView: cycleLengthIconImageView,
            titleLabel: cycleLengthTitleLabel,
            captionLabel: cycleLengthCaptionLabel,
            valueLabel: cycleLengthValueLabel,
            arrowImageView: cycleLengthArrowImageView,
            iconBackgroundColor: UIColor(red: 0.93, green: 0.91, blue: 1.0, alpha: 1.0)
        )
        setupOptionCard(
            containerView: lastPeriodContainerView,
            iconContainerView: lastPeriodIconContainerView,
            iconImageView: lastPeriodIconImageView,
            titleLabel: lastPeriodTitleLabel,
            captionLabel: lastPeriodCaptionLabel,
            valueLabel: lastPeriodValueLabel,
            arrowImageView: lastPeriodArrowImageView,
            iconBackgroundColor: UIColor(red: 1.0, green: 0.94, blue: 0.89, alpha: 1.0)
        )

        heroCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(246)
        }

        heroPrimaryGlowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(54)
            make.top.equalToSuperview().offset(-42)
            make.width.height.equalTo(180)
        }

        heroSecondaryGlowView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(-30)
            make.bottom.equalToSuperview().offset(48)
            make.width.height.equalTo(120)
        }

        heroBadgeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(22)
            make.height.equalTo(26)
            make.width.greaterThanOrEqualTo(98)
        }

        heroTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(heroBadgeLabel)
            make.top.equalTo(heroBadgeLabel.snp.bottom).offset(14)
            make.trailing.equalTo(heroArtworkContainerView.snp.leading).offset(-16)
        }

        heroSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(heroTitleLabel)
            make.top.equalTo(heroTitleLabel.snp.bottom).offset(8)
            make.trailing.equalTo(heroArtworkContainerView.snp.leading).offset(-16)
        }

        heroArtworkContainerView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalToSuperview().offset(28)
            make.width.height.equalTo(84)
        }

        heroArtworkRingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(64)
        }

        heroArtworkIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(36)
        }

        summaryStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.bottom.equalToSuperview().offset(-18)
            make.height.equalTo(82)
        }

        periodPreviewTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        periodPreviewValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(periodPreviewTitleLabel)
            make.trailing.equalTo(periodPreviewTitleLabel)
            make.bottom.equalToSuperview().offset(-14)
        }

        cyclePreviewTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        cyclePreviewValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(cyclePreviewTitleLabel)
            make.trailing.equalTo(cyclePreviewTitleLabel)
            make.bottom.equalToSuperview().offset(-14)
        }

        sectionHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(heroCardView.snp.bottom).offset(26)
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
        }

        questionLabel1.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
        }

        periodDaysContainerView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel1.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(86)
        }

        questionLabel2.snp.makeConstraints { make in
            make.top.equalTo(periodDaysContainerView.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
        }

        cycleLengthContainerView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel2.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(86)
            cycleLengthBottomConstraint = make.bottom.equalToSuperview().offset(-24).constraint
        }

        questionLabel3.snp.makeConstraints { make in
            make.top.equalTo(cycleLengthContainerView.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
        }

        lastPeriodContainerView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel3.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(92)
            lastPeriodBottomConstraint = make.bottom.equalToSuperview().offset(-24).constraint
        }

        updateLastPeriodVisibility()

        let periodDaysTap = UITapGestureRecognizer(target: self, action: #selector(periodDaysTapped))
        periodDaysContainerView.addGestureRecognizer(periodDaysTap)
        let cycleLengthTap = UITapGestureRecognizer(target: self, action: #selector(cycleLengthTapped))
        cycleLengthContainerView.addGestureRecognizer(cycleLengthTap)
        let lastPeriodTap = UITapGestureRecognizer(target: self, action: #selector(lastPeriodTapped))
        lastPeriodContainerView.addGestureRecognizer(lastPeriodTap)

        startPredictionButton.addTarget(self, action: #selector(startPredictionTapped), for: .touchUpInside)
        startPredictionButton.addTarget(self, action: #selector(handleCTAButtonPressDown), for: .touchDown)
        startPredictionButton.addTarget(self, action: #selector(handleCTAButtonPressCancel), for: [.touchUpInside, .touchDragExit, .touchCancel, .touchUpOutside])

        updatePeriodDaysPresentation()
        updateCycleLengthPresentation()
        updateLastPeriodPresentation()
        updateHeroSubtitle()
    }

    private func setupOptionCard(
        containerView: UIView,
        iconContainerView: UIView,
        iconImageView: UIImageView,
        titleLabel: UILabel,
        captionLabel: UILabel,
        valueLabel: UILabel,
        arrowImageView: UIImageView,
        iconBackgroundColor: UIColor
    ) {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 24
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.97, green: 0.88, blue: 0.91, alpha: 1.0).cgColor
        containerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 18
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)

        iconContainerView.backgroundColor = iconBackgroundColor
        iconContainerView.layer.cornerRadius = 20
        iconContainerView.layer.cornerCurve = .continuous

        [iconContainerView, titleLabel, captionLabel, valueLabel, arrowImageView].forEach {
            containerView.addSubview($0)
        }
        iconContainerView.addSubview(iconImageView)

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(14)
            make.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
        }

        captionLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
        }

        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Presentation

    private func updatePeriodDaysPresentation() {
        let text = "\(periodDays)" + "female_cycle_days_unit".localized()
        periodDaysValueLabel.text = text
        periodPreviewValueLabel.text = text
        updateHeroSubtitle()
    }

    private func updateCycleLengthPresentation() {
        let text = "\(cycleLength)" + "female_cycle_days_unit".localized()
        cycleLengthValueLabel.text = text
        cyclePreviewValueLabel.text = text
        updateHeroSubtitle()
    }

    private func updateLastPeriodPresentation() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        lastPeriodValueLabel.text = formatter.string(from: lastPeriodDate)
        updateHeroSubtitle()
    }

    private func updateHeroSubtitle() {
        let dateText = lastPeriodValueLabel.text ?? ""
        if hideLastPeriodDateOption {
            heroSubtitleLabel.text = "female_cycle_question_cycle_length".localized()
        } else {
            heroSubtitleLabel.text = "\(dateText)  |  \(periodDays)" + "female_cycle_days_unit".localized() + " / \(cycleLength)" + "female_cycle_days_unit".localized()
        }
    }

    private func updateStartButtonTitle() {
        let title = hideLastPeriodDateOption ? "female_cycle_save".localized() : "female_cycle_start_prediction".localized()
        startPredictionButton.setTitle(title, for: .normal)
    }

    private func updateLastPeriodVisibility() {
        questionLabel3.isHidden = hideLastPeriodDateOption
        lastPeriodContainerView.isHidden = hideLastPeriodDateOption
        if hideLastPeriodDateOption {
            lastPeriodBottomConstraint?.deactivate()
            cycleLengthBottomConstraint?.activate()
        } else {
            cycleLengthBottomConstraint?.deactivate()
            lastPeriodBottomConstraint?.activate()
        }
        view.layoutIfNeeded()
    }

    private func animateEntranceIfNeeded() {
        guard !hasAnimatedEntrance else {
            return
        }
        hasAnimatedEntrance = true
        let animatedViews: [UIView] = [heroCardView, sectionHeaderLabel, periodDaysContainerView, cycleLengthContainerView, lastPeriodContainerView, startPredictionButton]
        for (index, targetView) in animatedViews.enumerated() {
            targetView.alpha = hideLastPeriodDateOption && targetView === lastPeriodContainerView ? 0 : 0
            targetView.transform = CGAffineTransform(translationX: 0, y: 22).scaledBy(x: 0.98, y: 0.98)
            UIView.animate(
                withDuration: 0.62,
                delay: min(Double(index) * 0.06, 0.28),
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.16,
                options: [.allowUserInteraction, .curveEaseOut]
            ) {
                targetView.alpha = (self.hideLastPeriodDateOption && targetView === self.lastPeriodContainerView) ? 0 : 1
                targetView.transform = .identity
            }
        }
    }

    private func animateSelection(on targetView: UIView, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            targetView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        } completion: { _ in
            UIView.animate(withDuration: 0.26, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.18, options: [.allowUserInteraction, .curveEaseOut]) {
                targetView.transform = .identity
            } completion: { _ in
                completion?()
            }
        }
    }

    // MARK: - Actions

    @objc private func handleCTAButtonPressDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.startPredictionButton.transform = CGAffineTransform(scaleX: 0.985, y: 0.985)
        }
    }

    @objc private func handleCTAButtonPressCancel() {
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.startPredictionButton.transform = .identity
        }
    }

    @objc private func periodDaysTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateSelection(on: periodDaysContainerView) { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "female_cycle_select_period_days".localized(), message: nil, preferredStyle: .actionSheet)

            for days in 3...10 {
                let action = UIAlertAction(title: "\(days)" + "female_cycle_days_unit".localized(), style: .default) { [weak self] _ in
                    self?.periodDays = days
                }
                alert.addAction(action)
            }

            alert.addAction(UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil))

            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.periodDaysContainerView
                popoverController.sourceRect = self.periodDaysContainerView.bounds
            }

            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc private func cycleLengthTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateSelection(on: cycleLengthContainerView) { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "female_cycle_select_cycle_length".localized(), message: nil, preferredStyle: .actionSheet)

            for days in 21...35 {
                let action = UIAlertAction(title: "\(days)" + "female_cycle_days_unit".localized(), style: .default) { [weak self] _ in
                    self?.cycleLength = days
                }
                alert.addAction(action)
            }

            alert.addAction(UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil))

            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.cycleLengthContainerView
                popoverController.sourceRect = self.cycleLengthContainerView.bounds
            }

            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc private func lastPeriodTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateSelection(on: lastPeriodContainerView) { [weak self] in
            guard let self else { return }
            let pickerView = TTADataPickerView(title: "female_cycle_select_date".localized(), type: .date, delegate: self)
            pickerView.show {
                UIView.animate(withDuration: 0.3) {
                    self.view.backgroundColor = UIColor(white: 1.0, alpha: 0.01)
                }
            }
        }
    }

    @objc private func startPredictionTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if hideLastPeriodDateOption {
            saveFemaleHealthData()
            navigationController?.popViewController(animated: true)
        } else {
            let vc = FemaleCycleCalendarViewController()
            vc.hidesBottomBarWhenPushed = true

            if var viewControllers = navigationController?.viewControllers {
                viewControllers.removeLast()
                viewControllers.append(vc)
                navigationController?.setViewControllers(viewControllers, animated: true)
            }
        }
    }

    // MARK: - Data Management

    private func saveFemaleHealthData() {
        FemaleCycleDataManager.shared.updateCycleConfiguration(
            periodDays: periodDays,
            cycleLength: cycleLength,
            lastPeriodDate: lastPeriodDate
        )
        XLogger.shared.log("保存女性健康配置: periodDays=\(periodDays), cycleLength=\(cycleLength), lastPeriodDate=\(lastPeriodDate)")
    }

    private func loadFemaleHealthData() {
        let config = FemaleCycleDataManager.shared.getCycleConfiguration()

        if config.periodDays > 0 {
            periodDays = config.periodDays
        }

        if config.cycleLength > 0 {
            cycleLength = config.cycleLength
        }

        lastPeriodDate = config.lastPeriodDate

        XLogger.shared.log("加载女性健康配置: periodDays=\(periodDays), cycleLength=\(cycleLength), lastPeriodDate=\(lastPeriodDate)")
    }
}

// MARK: - TTADataPickerViewDelegate

extension FemaleHealthViewController: TTADataPickerViewDelegate {
    func dataPickerView(_ pickerView: TTADataPickerView, didSelectTitles titles: [String]) {
        // Not used for date picker
    }

    func dataPickerView(_ pickerView: TTADataPickerView, didSelectDate date: Date) {
        lastPeriodDate = date
    }

    func dataPickerView(_ pickerView: TTADataPickerView, didChange row: Int, inComponent component: Int) {
        // Optional
    }

    func dataPickerViewWillCancel(_ pickerView: TTADataPickerView) {
        // Optional
    }

    func dataPickerViewDidCancel(_ pickerView: TTADataPickerView) {
        // Optional
    }
}

// MARK: - UIColor Extension

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
