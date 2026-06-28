//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  HealthDetailViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK
import RealmSwift

class HealthDetailViewController: BaseViewController {
    private struct DetailNarrativePresentation {
        let chipText: String
        let titleText: String
        let detailText: String
    }
    
    let lineChartView: LineChartView = LineChartView()
    let barChartView: BarChartView = BarChartView()
    private let headerBackgroundView = UIView()
    private let heroDecorationImageView = UIImageView(image: UIImage(named: "health_dashboard_hero"))
    private let primaryDecorationView = UIView()
    private let secondaryDecorationView = UIView()
    private let summaryChipLabel: DetailInsetLabel = {
        let label = DetailInsetLabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        return label
    }()
    private let summaryTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    private let summaryDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.82)
        label.numberOfLines = 2
        return label
    }()
    private let dateCapsuleView = UIView()
    let dateLabel: UILabel = UILabel() // 日期
    let prevDayButton: UIButton = UIButton(type: .custom) // 前一个
    let nextDayButton: UIButton = UIButton(type: .custom) // 后一个
    let valueView = HealthValueView()
    let fanView = FanView() // 步数和睡眠view
    let roundView = RoundView() // 血压和睡眠view
    let testView = TestView()
    public var colors: [UIColor]!
    var commonCalendarView: CommonCalendarView?
    var type = 0 // 0 步数 1 热量 2 心率 3 睡眠
    var mDate: Date = Date()
    var totalValue = 0 // 总步数
    var totalKM = 0 // 总公里
    var measureAsync: Async?
    var mTimer: Timer?
    var alpha: CGFloat = 0.3
    var maxValue = 0
    private let headerGradientLayer = CAGradientLayer()
    private var hasAnimatedEntrance = false
    private let lineChartMarker = HealthChartMarkerView()
    private let barChartMarker = HealthChartMarkerView()
    var prefersSharedTransition = false
    private let chartHighlightGlowView = UIView()
    private let chartHighlightInnerView = UIView()
    private let chartHighlightGuideLayer = CAShapeLayer()
    private let chartHighlightPulseLayer = CAShapeLayer()
    private let chartHighlightGradientLayer = CAGradientLayer()
    
    var sharedTransitionTargetView: UIView {
        headerBackgroundView
    }
    
    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0xF4F6FA)
        navigationController?.navigationBar.tintColor = .white
        
        dateLabel.textColor = UIColor.white
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(chooseDate))
        dateLabel.isUserInteractionEnabled = true
        tap.numberOfTapsRequired = 1
        dateLabel.addGestureRecognizer(tap)
        
        prevDayButton.setImage(UIImage(named: "health_pre_date"), for: .normal)
        prevDayButton.addTarget(self, action: #selector(prevDayTapped), for: .touchUpInside)
        view.addSubview(prevDayButton)
        prevDayButton.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalTo(dateLabel.snp.centerY)
            make.trailing.equalTo(dateLabel.snp.leading).offset(-2)
        }
        
        nextDayButton.setImage(UIImage(named: "health_next_date"), for: .normal)
        nextDayButton.addTarget(self, action: #selector(nextDayTapped), for: .touchUpInside)
        view.addSubview(nextDayButton)
        nextDayButton.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalTo(dateLabel.snp.centerY)
            make.leading.equalTo(dateLabel.snp.trailing).offset(2)
        }
        
        view.addSubview(valueView)
        valueView.backgroundColor = UIColor.white
        let h = screenWidth <= 375 ? 320.0 : 388.0
        valueView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.height.equalTo(valueView.snp.width).multipliedBy(h/375.0)
        }
        styleValueCard()
        configureHeroBackground()
        configureDateControls()
        configureTrendSectionPresentation()
        setupChartSelectionFeedbackView()
        
        view.addSubview(roundView)
        roundView.backgroundColor = UIColor.clear
        roundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(dateLabel.snp.bottom).offset(18)
            make.bottom.equalTo(valueView.snp.top).offset(-18)
        }
        
        view.addSubview(fanView)
        fanView.backgroundColor = UIColor.clear
        fanView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(dateLabel.snp.bottom).offset(18)
            make.bottom.equalTo(valueView.snp.top).offset(-18)
        }
        
        view.addSubview(testView)
        testView.backgroundColor = UIColor.clear
        testView.delegate = self 
        testView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(dateLabel.snp.bottom).offset(18)
            make.bottom.equalTo(valueView.snp.top).offset(-18)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("healthDetail"), object: nil)
        
        if type == 0 {
            title = "health_step".localized()
            fanView.isHidden = false
            roundView.isHidden = true
            testView.isHidden = true
            let m = NSMutableAttributedString()
            m.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            m.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let c = NSMutableAttributedString()
            c.append(NSAttributedString(string: "-- ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            c.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            fanView.setupView(titles: ["health_distance".localized(), "consumption".localized()], values: [m, c], title: "today_step".localized(), value: b)
        }
        if type == 2 {
            title = "health_heart_rate".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            roundView.setupView(value: b)
            valueView.refreshLabel(text: "heart_desc".localized())
            addTest()
        }
        if type == 3 {
            title = "health_sleep".localized()
            fanView.isHidden = false
            roundView.isHidden = true
            testView.isHidden = true
            let qing = NSMutableAttributedString()
            qing.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            qing.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let qian = NSMutableAttributedString()
            qian.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            qian.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let shen = NSMutableAttributedString()
            shen.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            shen.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
            b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
            fanView.setupView(titles: ["health_detail_sleep_awake".localized(), "health_detail_sleep_light".localized(), "health_detail_sleep_deep".localized()], values: [qing, qian, shen], title: "today_sleep".localized(), value: b)
        }
        if type == 4 {
            title = "health_blood_pressure".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            valueView.refreshLabel(text: "blood_pressure_desc".localized())
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
            roundView.setupView(value: b)
            addTest()
        }
        if type == 5 {
            title = "health_blood_oxygen".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            roundView.setupView(value: b)
            addTest()
            
        }
        
        if type == 3 {
            setBarChartView()
        } else {
            setupChart()
        }
        [dateCapsuleView, dateLabel, prevDayButton, nextDayButton].forEach {
            view.bringSubviewToFront($0)
        }
        refreshDisplayedDetail(animated: false)
        
        // 创建一个自定义的返回按钮
        let backButton = UIBarButtonItem(image: UIImage(named: "health_back_white"), style: .plain, target: self, action: #selector(backButtonTapped))
        
        // 将自定义的返回按钮设置为左侧按钮
        self.navigationItem.leftBarButtonItem = backButton
        
        // 如果你不希望保留原有的返回按钮文本，可以将其设置为空字符串
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    private func configureHeroBackground() {
        headerBackgroundView.layer.cornerRadius = 34
        headerBackgroundView.layer.cornerCurve = .continuous
        headerBackgroundView.layer.masksToBounds = true
        view.insertSubview(headerBackgroundView, at: 0)
        headerBackgroundView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(valueView.snp.top).offset(-18)
        }
        
        let palette = resolvedAccentColors()
        headerGradientLayer.colors = palette.map { $0.cgColor }
        headerGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        headerGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        headerBackgroundView.layer.insertSublayer(headerGradientLayer, at: 0)
        
        heroDecorationImageView.alpha = 0
        heroDecorationImageView.contentMode = .scaleAspectFill
        primaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        secondaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        
        [heroDecorationImageView, primaryDecorationView, secondaryDecorationView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerBackgroundView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            heroDecorationImageView.trailingAnchor.constraint(equalTo: headerBackgroundView.trailingAnchor, constant: 24),
            heroDecorationImageView.bottomAnchor.constraint(equalTo: headerBackgroundView.bottomAnchor, constant: 36),
            heroDecorationImageView.widthAnchor.constraint(equalTo: headerBackgroundView.widthAnchor, multiplier: 0.58),
            heroDecorationImageView.heightAnchor.constraint(equalTo: headerBackgroundView.heightAnchor, multiplier: 0.46),
            
            primaryDecorationView.widthAnchor.constraint(equalToConstant: 160),
            primaryDecorationView.heightAnchor.constraint(equalToConstant: 160),
            primaryDecorationView.trailingAnchor.constraint(equalTo: headerBackgroundView.trailingAnchor, constant: 58),
            primaryDecorationView.topAnchor.constraint(equalTo: headerBackgroundView.topAnchor, constant: -44),
            
            secondaryDecorationView.widthAnchor.constraint(equalToConstant: 120),
            secondaryDecorationView.heightAnchor.constraint(equalToConstant: 120),
            secondaryDecorationView.leadingAnchor.constraint(equalTo: headerBackgroundView.leadingAnchor, constant: -34),
            secondaryDecorationView.bottomAnchor.constraint(equalTo: headerBackgroundView.bottomAnchor, constant: 48)
        ])
    }
    
    private func configureDateControls() {
        dateCapsuleView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        dateCapsuleView.layer.cornerRadius = 20
        dateCapsuleView.layer.cornerCurve = .continuous
        dateCapsuleView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        dateCapsuleView.layer.borderWidth = 1
        view.insertSubview(dateCapsuleView, belowSubview: dateLabel)
        dateCapsuleView.snp.makeConstraints { make in
            make.center.equalTo(dateLabel)
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(152)
        }
        
        styleHeaderControlButton(prevDayButton)
        styleHeaderControlButton(nextDayButton)
    }
    
    private func configureNarrativeSummary() {
        [summaryChipLabel, summaryTitleLabel, summaryDetailLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            summaryChipLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            summaryChipLabel.topAnchor.constraint(equalTo: dateCapsuleView.bottomAnchor, constant: 12),
            
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryChipLabel.leadingAnchor),
            summaryTitleLabel.topAnchor.constraint(equalTo: summaryChipLabel.bottomAnchor, constant: 10),
            summaryTitleLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.54),
            
            summaryDetailLabel.leadingAnchor.constraint(equalTo: summaryTitleLabel.leadingAnchor),
            summaryDetailLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 6),
            summaryDetailLabel.widthAnchor.constraint(equalTo: summaryTitleLabel.widthAnchor),
            summaryDetailLabel.bottomAnchor.constraint(lessThanOrEqualTo: valueView.topAnchor, constant: -110)
        ])
        
        updateNarrativeSummary(defaultNarrativePresentation())
    }
    
    private func configureTrendSectionPresentation() {
        valueView.topLabel.text = trendSectionTitle()
        valueView.refreshLabel(text: trendSectionHelperText())
    }
    
    private func styleHeaderControlButton(_ button: UIButton) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        button.layer.cornerRadius = 18
        button.layer.cornerCurve = .continuous
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        button.layer.borderWidth = 1
        addInteractiveFeedback(to: button)
    }
    
    private func styleValueCard() {
        valueView.layer.cornerRadius = 30
        valueView.layer.cornerCurve = .continuous
        valueView.layer.masksToBounds = false
        valueView.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        valueView.layer.shadowOpacity = 1
        valueView.layer.shadowRadius = 18
        valueView.layer.shadowOffset = CGSize(width: 0, height: 12)
        valueView.layer.borderWidth = 1
        valueView.layer.borderColor = UIColor(hex: 0xE8EEF7).cgColor
    }
    
    private func setupChartSelectionFeedbackView() {
        chartHighlightGlowView.layer.cornerRadius = 18
        chartHighlightGlowView.layer.shadowColor = resolvedAccentColors().first?.withAlphaComponent(0.92).cgColor
        chartHighlightGlowView.layer.shadowOpacity = 0.55
        chartHighlightGlowView.layer.shadowRadius = 16
        chartHighlightGlowView.layer.shadowOffset = .zero
        chartHighlightGlowView.isHidden = true
        chartHighlightGlowView.isUserInteractionEnabled = false
        chartHighlightGlowView.layer.insertSublayer(chartHighlightGradientLayer, at: 0)
        chartHighlightGradientLayer.colors = detailHighlightColors().map { $0.cgColor }
        chartHighlightGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        chartHighlightGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        chartHighlightInnerView.backgroundColor = UIColor.white
        chartHighlightInnerView.layer.cornerRadius = 5
        chartHighlightInnerView.isUserInteractionEnabled = false
        chartHighlightGlowView.addSubview(chartHighlightInnerView)
        chartHighlightInnerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartHighlightInnerView.centerXAnchor.constraint(equalTo: chartHighlightGlowView.centerXAnchor),
            chartHighlightInnerView.centerYAnchor.constraint(equalTo: chartHighlightGlowView.centerYAnchor),
            chartHighlightInnerView.widthAnchor.constraint(equalToConstant: 10),
            chartHighlightInnerView.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        chartHighlightGuideLayer.strokeColor = resolvedAccentColors().first?.withAlphaComponent(0.62).cgColor
        chartHighlightGuideLayer.lineWidth = 1
        chartHighlightGuideLayer.lineDashPattern = [4, 6]
        chartHighlightGuideLayer.fillColor = UIColor.clear.cgColor
        
        chartHighlightPulseLayer.strokeColor = resolvedAccentColors().first?.withAlphaComponent(0.48).cgColor
        chartHighlightPulseLayer.fillColor = UIColor.clear.cgColor
        chartHighlightPulseLayer.lineWidth = 2
        chartHighlightPulseLayer.opacity = 0
    }
    
    func prepareForSharedTransition() {
        prefersSharedTransition = true
        [headerBackgroundView, currentActiveInsightView(), valueView, dateCapsuleView, prevDayButton, nextDayButton, summaryChipLabel, summaryTitleLabel, summaryDetailLabel].forEach {
            $0.alpha = 0
        }
    }
    
    func completeSharedTransition() {
        [headerBackgroundView, currentActiveInsightView(), valueView, dateCapsuleView, prevDayButton, nextDayButton, summaryChipLabel, summaryTitleLabel, summaryDetailLabel].forEach {
            $0.alpha = 1
        }
        hasAnimatedEntrance = true
    }
    
    private func resolvedAccentColors() -> [UIColor] {
        if let colors, colors.count >= 2 {
            return colors
        }
        switch type {
        case 2:
            return [UIColor.kFF5E46, UIColor(hex: 0xFF8D64)]
        case 3:
            return [UIColor.k7A61FF, UIColor(hex: 0xA78BFF)]
        case 4:
            return [UIColor.kFFB642, UIColor(hex: 0xFF8A54)]
        case 5:
            return [UIColor.k08CCCC, UIColor(hex: 0x4B8DFF)]
        default:
            return [UIColor.kFFB642, UIColor.kFF5E46]
        }
    }
    
    private func refreshDisplayedDetail(animated: Bool) {
        dateLabel.text = mDate.stringFromYmd()
        chartHighlightGradientLayer.colors = detailHighlightColors().map { $0.cgColor }
        configureTrendSectionPresentation()
        updateNarrativeSummary(defaultNarrativePresentation())
        if animated {
            animateDetailRefresh()
        }
        if type == 3 {
            setBarData()
        } else {
            setChartViewData()
        }
    }
    
    private func animateDetailRefresh() {
        let activeView = currentActiveInsightView()
        [activeView, valueView].forEach { view in
            view.layer.removeAnimation(forKey: "health.detail.refresh")
            view.transform = .identity
            view.alpha = 1
        }
        clearChartSelectionFeedback(animated: false)
    }
    
    private func currentActiveInsightView() -> UIView {
        if !testView.isHidden {
            return testView
        }
        return fanView.isHidden ? roundView : fanView
    }
    
    private func animateDetailEntranceIfNeeded() {
        guard !hasAnimatedEntrance else {
            return
        }
        hasAnimatedEntrance = true
        let views = [dateCapsuleView, prevDayButton, nextDayButton, summaryChipLabel, summaryTitleLabel, summaryDetailLabel, currentActiveInsightView(), valueView]
        for view in views {
            view.alpha = 1
            view.transform = .identity
        }
    }
    
    private func animateHeroTap(on view: UIView) {
        view.layer.removeAllAnimations()
        view.transform = .identity
    }
    
    private func addInteractiveFeedback(to button: UIButton) {
        button.addTarget(self, action: #selector(handleInteractivePressDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(handleInteractivePressUp(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel, .touchUpOutside])
    }
    
    @objc private func handleInteractivePressDown(_ sender: UIButton) {
        sender.layer.removeAllAnimations()
        sender.transform = .identity
    }
    
    @objc private func handleInteractivePressUp(_ sender: UIButton) {
        sender.layer.removeAllAnimations()
        sender.transform = .identity
    }
    
    func getBitValue(of number: Int, at position: Int) -> Int {
        // 使用位运算获取指定位置的位值
        let bitValue = (number >> position) & 1
        return bitValue
    }
    
    private func addTest() {
        let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
        if bk {
            return
        }
        
        if bleSelf.isConnected == false && XGZTBlueToothManager.shared.device == nil {
            return
        }
        
        if isXGZT {
            return
        }
        
//        if (type == 2 && isXGZT) && (XGZTBlueToothManager.shared.device?.brandID ?? 0) == 0 {
//            return
//        }
//        
//        if (type == 5 && isXGZT) && (XGZTBlueToothManager.shared.device?.brandID ?? 0) == 0  {
//            return
//        }
        
        if screenHeight <= 667 {
            // 创建一个UIBarButtonItem
            let rightButton = UIBarButtonItem(title: "health_start_test".localized(), style: .plain, target: self, action: #selector(self.rightBarButtonAction))
            // 设置字体颜色
            rightButton.tintColor = UIColor.white
            // 将UIBarButtonItem设置为navigationItem的右侧按钮
            self.navigationItem.rightBarButtonItem = rightButton
        } else {
            let testButton = UIButton(type: .custom)
            testButton.tag = 8888
            testButton.setTitle("health_start_test".localized(), for: .normal)
            testButton.setTitleColor(UIColor.white, for: .normal)
            testButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            testButton.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
            testButton.layer.borderWidth = 1.0
            testButton.layer.cornerRadius = 22
            testButton.layer.cornerCurve = .continuous
            // 添加按钮到视图中
            view.addSubview(testButton)
            testButton.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(150)
                make.height.equalTo(44)
                make.bottom.equalTo(valueView.snp.top).offset(-10)
            }
            addInteractiveFeedback(to: testButton)
            testButton.addTarget(self, action: #selector(rightBarButtonAction), for: .touchUpInside)
        }
        
    }
    
    // UIBarButtonItem的点击事件处理器
    @objc func rightBarButtonAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if screenHeight <= 667 {
            // 隐藏按钮
            self.navigationItem.rightBarButtonItem = nil
            // 或者，如果你想保持按钮但仅仅是禁用它，可以这样做：
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            if let btn = view.viewWithTag(8888) as? UIButton {
                btn.isHidden = true
            }
        }
        
        roundView.isHidden = true
        fanView.isHidden = true
        testView.isHidden = false
        animateDetailRefresh()
        handleStartTest() // 启动测试
        
        
    }
    
    @objc func backButtonTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // 在这里处理返回按钮的点击事件
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if prefersSharedTransition {
            prefersSharedTransition = false
        } else {
            animateDetailEntranceIfNeeded()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearChartSelectionFeedback(animated: false)
        UINavigationBar.appearance().tintColor = UIColor.text_primary
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerGradientLayer.frame = headerBackgroundView.bounds
        valueView.layer.shadowPath = UIBezierPath(roundedRect: valueView.bounds, cornerRadius: valueView.layer.cornerRadius).cgPath
        primaryDecorationView.layer.cornerRadius = primaryDecorationView.bounds.height / 2
        secondaryDecorationView.layer.cornerRadius = secondaryDecorationView.bounds.height / 2
        chartHighlightGlowView.bounds = CGRect(x: 0, y: 0, width: 36, height: 36)
        chartHighlightGlowView.layer.cornerRadius = 18
        chartHighlightGradientLayer.frame = chartHighlightGlowView.bounds
        chartHighlightGradientLayer.cornerRadius = chartHighlightGlowView.layer.cornerRadius
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 前一天按钮点击事件
    @objc func prevDayTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateHeroTap(on: prevDayButton)
        mDate = Calendar.current.date(byAdding: .day, value: -1, to: mDate)!
        refreshDisplayedDetail(animated: true)
    }

    // 后一天按钮点击事件
    @objc func nextDayTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateHeroTap(on: nextDayButton)
        mDate = Calendar.current.date(byAdding: .day, value: 1, to: mDate)!
        refreshDisplayedDetail(animated: true)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if testView.isHidden == false {
            testView.stop()
            if type == 0 {
                fanView.isHidden = false
                roundView.isHidden = true
                testView.isHidden = true
            }
            if type == 2 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
            }
            if type == 3 {
                fanView.isHidden = false
                roundView.isHidden = true
                testView.isHidden = true
            }
            if type == 4 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
            }
            if type == 5 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
                
            }
            if type == 2 || type == 4 || type == 5 {
                if screenHeight <= 667 {
                    addTest()
                } else {
                    if let btn = view.viewWithTag(8888) as? UIButton {
                        btn.isHidden = false
                    }
                }
            }
        }
        refreshDisplayedDetail(animated: true)
    }
    
    /// 设置图表
    private func setupChart() {
        if type == 0 && bleSelf.bleModel.isBond == false {
            valueView.isHidden = true
        }
        valueView.addSubview(lineChartView)
        lineChartView.snp.makeConstraints { make in
            make.leading.equalTo(15)
            make.trailing.equalTo(-15)
            make.top.equalTo(50)
            make.bottom.equalTo(-10)
        }
        
        lineChartView.delegate = self
        
        lineChartView.chartDescription?.enabled = false
        lineChartView.dragEnabled = false
        lineChartView.setScaleEnabled(false)
        lineChartView.pinchZoomEnabled = false
        
        lineChartView.xAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.axisMinimum = Double(0)
        lineChartView.xAxis.axisMaximum = Double(23)
        lineChartView.xAxis.setLabelCount(24, force: true)
        lineChartView.xAxis.gridColor = UIColor.clear
        lineChartView.xAxis.drawGridLinesEnabled = true
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
        
        lineChartView.leftAxis.labelTextColor = UIColor.clear
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.leftAxis.axisMaximum = 5
        lineChartView.leftAxis.setLabelCount(6, force: true)
        lineChartView.leftAxis.gridColor = UIColor.clear
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        
        lineChartView.rightAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.rightAxis.axisMinimum = 0
        if type == 0 {
            lineChartView.rightAxis.axisMaximum = 5000
        } else if type == 2 {
            lineChartView.rightAxis.axisMaximum = 200
        } else if type == 4 {
            lineChartView.rightAxis.axisMaximum = 200
        } else if type == 5 {
            lineChartView.rightAxis.axisMaximum = 100
        }
        lineChartView.rightAxis.setLabelCount(6, force: true)
        lineChartView.rightAxis.gridColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.rightAxis.drawGridLinesEnabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.legend.form = .none
        lineChartView.highlightPerTapEnabled = true
        lineChartView.highlightPerDragEnabled = false
        lineChartView.dragDecelerationEnabled = false
        lineChartView.extraTopOffset = 24
        lineChartView.drawMarkers = true
        lineChartMarker.chartView = lineChartView
        lineChartMarker.formatter = { [weak self] entry in
            let hour = Int(entry.x.rounded())
            let display = self?.detailMarkerDisplay(for: entry.y)
            return ("\(hour):00", display?.value ?? "\(Int(entry.y.rounded()))", display?.detail)
        }
        lineChartView.marker = lineChartMarker
        lineChartView.layer.addSublayer(chartHighlightGuideLayer)
        lineChartView.layer.addSublayer(chartHighlightPulseLayer)
        lineChartView.addSubview(chartHighlightGlowView)
    }
    
    func setChartViewData() {
        var values: [ChartDataEntry] = []
        initializeData { [weak self] v in
            // Handle the values array here
            values += v
            let palette = self?.resolvedAccentColors() ?? [UIColor.brand, UIColor.brand]
            let primaryColor = palette.first ?? UIColor.brand
            let secondaryColor = palette.count > 1 ? palette[1] : primaryColor.withAlphaComponent(0.75)
            let set1 = LineChartDataSet(entries: values, label: "")
            set1.drawIconsEnabled = false
            
            set1.setColor(primaryColor)
            set1.lineWidth = 2.2
            set1.valueFont = .systemFont(ofSize: 9)
            set1.formLineWidth = 0.5
            set1.mode = .horizontalBezier
            set1.drawValuesEnabled = false // 不要绘制值
            set1.drawCirclesEnabled = true
            set1.circleHoleRadius = 1.8
            set1.circleRadius = 2.6
            set1.setCircleColor(UIColor.white.withAlphaComponent(0.78))
            set1.circleHoleColor = primaryColor
            set1.highlightColor = UIColor.white
            set1.highlightLineWidth = 0
            set1.drawHorizontalHighlightIndicatorEnabled = false
            set1.drawVerticalHighlightIndicatorEnabled = false
            
            let gradientColors = [primaryColor.withAlphaComponent(0.36).cgColor,
                                  secondaryColor.withAlphaComponent(0.06).cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!

            set1.fillAlpha = 1
            set1.fill = Fill(linearGradient: gradient, angle: 90)
            set1.drawFilledEnabled = true
            
            let data = LineChartData(dataSet: set1)

            self?.lineChartView.data = data
            self?.lineChartView.highlightValue(nil, callDelegate: false)
            self?.clearChartSelectionFeedback(animated: false)
            self?.lineChartView.transform = .identity
            self?.lineChartView.alpha = 1
            
            let hasData = self?.hasMeaningfulValues(values) ?? false
            self?.updateDetailEmptyState(isEmpty: !hasData)
            self?.lineChartView.isHidden = !hasData
            self?.updateNarrativeSummary(self?.narrativePresentationForLineEntries(values, hasData: hasData) ?? self?.defaultNarrativePresentation() ?? DetailNarrativePresentation(chipText: "", titleText: "", detailText: ""))
        }
        
    }
    
    func setBarChartView() {
        valueView.addSubview(barChartView)
        barChartView.snp.makeConstraints { make in
            make.leading.equalTo(15)
            make.trailing.equalTo(-15)
            make.top.equalTo(50)
            make.bottom.equalTo(-10)
        }
        barChartView.delegate = self
        
        barChartView.chartDescription?.enabled = false
        barChartView.dragEnabled = false
        barChartView.setScaleEnabled(false)
        barChartView.pinchZoomEnabled = false
        
        barChartView.xAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        barChartView.xAxis.avoidFirstLastClippingEnabled = true
        barChartView.xAxis.axisMinimum = Double(0)
        barChartView.xAxis.axisMaximum = Double(4)
        barChartView.xAxis.setLabelCount(5, force: true)
        barChartView.xAxis.gridColor = UIColor.clear
        barChartView.xAxis.drawGridLinesEnabled = true
        barChartView.xAxis.drawAxisLineEnabled = false
        barChartView.xAxis.labelPosition = .bottom
        let xAxisFormatter = CustomXAxisFormatter()
        xAxisFormatter.labels = [" ", "health_detail_sleep_awake".localized(), "health_detail_sleep_light".localized(), "health_detail_sleep_deep".localized(), " "]
        barChartView.xAxis.valueFormatter = xAxisFormatter
        barChartView.xAxis.granularity = 1 // 设置粒度以避免重复值
        
        barChartView.leftAxis.labelTextColor = UIColor.clear
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.axisMaximum = 5
        barChartView.leftAxis.setLabelCount(6, force: true)
        barChartView.leftAxis.gridColor = UIColor.clear
        barChartView.leftAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.drawAxisLineEnabled = false
        
        barChartView.rightAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        barChartView.rightAxis.axisMinimum = 0
 
        barChartView.rightAxis.axisMaximum = 500 // 12小时
        
        barChartView.rightAxis.setLabelCount(6, force: true)
        barChartView.rightAxis.gridColor = UIColor(hex: 0x9097A0, alpha: 1)
        barChartView.rightAxis.drawGridLinesEnabled = true
        barChartView.rightAxis.drawAxisLineEnabled = false
        barChartView.legend.form = .none
        barChartView.highlightPerTapEnabled = true
        barChartView.highlightPerDragEnabled = false
        barChartView.fitBars = true
        barChartView.extraTopOffset = 24
        barChartView.drawMarkers = true
        barChartMarker.chartView = barChartView
        barChartMarker.formatter = { [weak self] entry in
            let valueText = self?.sleepMarkerValueText(for: entry.y) ?? ""
            return (self?.sleepStageTitle(for: Int(entry.x.rounded())) ?? "", valueText, "health_sleep".localized())
        }
        barChartView.marker = barChartMarker
        barChartView.layer.addSublayer(chartHighlightGuideLayer)
        barChartView.layer.addSublayer(chartHighlightPulseLayer)
        barChartView.addSubview(chartHighlightGlowView)
    }
    
    func setBarData() {
        var values: [BarChartDataEntry] = []
        initializeBarData { [weak self] updatedValues in
            // 使用 updatedValues 进行后续操作
            values += updatedValues
            let palette = self?.resolvedAccentColors() ?? [UIColor.k7A61FF, UIColor.k7A61FF]
            let primaryColor = palette.first ?? UIColor.k7A61FF
            let secondaryColor = palette.count > 1 ? palette[1] : primaryColor.withAlphaComponent(0.8)
            let set1 = BarChartDataSet(entries: values, label: "")
            set1.drawIconsEnabled = false
            
            let data = BarChartData(dataSet: set1)
            data.barWidth = 0.5
            self?.barChartView.data = data
            self?.barChartView.highlightValue(nil, callDelegate: false)
            self?.clearChartSelectionFeedback(animated: false)
            self?.barChartView.transform = .identity
            self?.barChartView.alpha = 1
            
            let hasData = self?.hasMeaningfulBarValues(values) ?? false
            self?.updateDetailEmptyState(isEmpty: !hasData)
            self?.barChartView.isHidden = !hasData
            self?.updateNarrativeSummary(self?.narrativePresentationForBarEntries(values, hasData: hasData) ?? self?.defaultNarrativePresentation() ?? DetailNarrativePresentation(chipText: "", titleText: "", detailText: ""))
            
            set1.drawValuesEnabled = false // 不要绘制值
            // 设置柱状图的颜色
            set1.colors = [primaryColor, secondaryColor]
            set1.highlightColor = UIColor.white.withAlphaComponent(0.92)
            set1.highlightAlpha = 0.55
            set1.drawValuesEnabled = false
        }
        
        
    }
    
    private func initializeData(completion: @escaping ([ChartDataEntry]) -> Void) {
        var values: [ChartDataEntry] = []
        for i in 0..<24 {
            values.append(ChartDataEntry(x: Double(i), y: Double(0)))
        }
        
        if type == 0 { // 步数
            if isXGZT {
                totalValue = 0
                totalKM = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readXGZTDBStep { [weak self] stepObj in
                    var value = 0
                    if stepObj.count > 0 {
                        value = stepObj.first?.step ?? 0
                    }
                    var distance = Int(XGZTBlueToothManager.shared.device?.height ?? 0) * 415 / 1000
                    var unit = value * distance
                    var v = unit * Int(XGZTBlueToothManager.shared.device?.weight ?? 0) * 55
                    var truncated = (Float(v) / 10000).rounded(.towardZero) / 1000

                    if self?.mDate.isToday() ?? false {
                        value = XGZTBlueToothManager.shared.device?.currentStep ?? 0
                        distance = Int(XGZTBlueToothManager.shared.device?.height ?? 0) * 415 / 1000
                        unit = value * distance
                        v = unit * Int(XGZTBlueToothManager.shared.device?.weight ?? 0) * 55
                        truncated = (Float(v) / 10000).rounded(.towardZero) / 1000
                    }
                    self?.totalValue = value
                    let m = NSMutableAttributedString()
                    if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                        let new = (Float(unit) / Float(100000)) * 62 / 100
                        let truncated = (new * 1000).rounded(.towardZero)/1000
                        m.append(NSAttributedString(string: String(format: "%.3f", Float(truncated)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        m.append(NSAttributedString(string: "mile".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    } else {
                        m.append(NSAttributedString(string: String(format: "%.3f", Float(unit) / Float(100000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        m.append(NSAttributedString(string: "health_walk_unit".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    }
                    let c = NSMutableAttributedString()
                    c.append(NSAttributedString(string: String(format: "%.3f", Float(truncated)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    c.append(NSAttributedString(string: "health_kilo_calorie".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(value)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_step_noun".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))

                    self?.fanView.refreshValue(values: [m, c], value: b)
                    var goal = UserDefaults.standard.integer(forKey: "Goal")
                    if goal == 0 {
                        goal = 8000
                    }
                    self?.fanView.setProgress(CGFloat(self?.totalValue ?? 0) / CGFloat(goal))
                    
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                totalValue = 0
                totalKM = 0
                let array = readDBStep()
                var scale = 1000
                if array.count > 0 {
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].step
                        totalValue += value
                        totalKM += array[i].distance
                        let x = (array[i].timeStamp - Int(zero)) / 3600
                        let item = values[x]
                        values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(scale) + item.y)
                        if value > maxValue {
                            maxValue = value
                        }
                    }
                    if maxValue <= 50 {
                        lineChartView.rightAxis.axisMaximum = 50
                        for i in 0..<values.count {
                            values[i].y *= 100
                        }
                        scale = 100
                    } else if maxValue <= 500 {
                        lineChartView.rightAxis.axisMaximum = 500
                        for i in 0..<values.count {
                            values[i].y *= 10
                        }
                        scale = 10
                    } else {
                        lineChartView.rightAxis.axisMaximum = 5000
                        scale = 1000
                    }
                    lineChartView.notifyDataSetChanged()
                }

                var totalValue1 = 0
                let array1 = readDBStep()
                if array1.count > 0 {
                    for i in 0..<array1.count {
                        let value = array1[i].cal // 热量
                        totalValue1 += value
                    }
                }

                if array1.count > 0 && bleSelf.step > totalValue && mDate.isToday() {
                    let zero = mDate.zeroTimeStamp()
                    let x = (Int(Date().timeIntervalSince1970) - Int(zero)) / 3600
                    values[x].y += Double((bleSelf.step - totalValue)) / Double(scale)
                    totalValue = bleSelf.step
                    totalKM = bleSelf.distance
                    totalValue1 = bleSelf.cal
                    lineChartView.notifyDataSetChanged()
                }

                let m = NSMutableAttributedString()
                if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                    let new = (Float(totalKM) / Float(1000)) * 62 / 100
                    let truncated = (new * 1000).rounded(.towardZero)/1000
                    m.append(NSAttributedString(string: String(format: "%.2f", Float(truncated)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    m.append(NSAttributedString(string: "mile".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                } else {
                    m.append(NSAttributedString(string: String(format: "%.2f", Float(totalKM) / Float(1000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    m.append(NSAttributedString(string: "health_walk_unit".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                }
                
                let c = NSMutableAttributedString()
                c.append(NSAttributedString(string: String(format: "%.2f", Float(totalValue1) / Float(1000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                c.append(NSAttributedString(string: "health_kilo_calorie".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                let b = NSMutableAttributedString()
                b.append(NSAttributedString(string: "\(totalValue)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                b.append(NSAttributedString(string: "health_step_noun".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))

                fanView.refreshValue(values: [m, c], value: b)
                var goal = UserDefaults.standard.integer(forKey: "Goal")
                if goal == 0 {
                    goal = bleSelf.userInfo.stepGoal
                }
                fanView.setProgress(CGFloat(totalValue) / CGFloat(goal))
                completion(values)
            }
        } else if type == 2 { // 心率
            if isXGZT {
                var count = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readXGZTDBHeart { [weak self] heartObjs in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    let array = heartObjs
                    if array.count > 0 {
                        count = array.count
                        let zero = self.mDate.zeroTimeStampUTC()
                        for i in 0..<array.count {
                            let value = array[i].heart
                            let x = (array[i].time - Int(zero)) / 3660
                            if x >= 0 && x < 24 {
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
                            }
                            XLogger.shared.log("历史心率数据: \(value) \(array[i].time)")
                        }
                        XLogger.shared.log("获取到数据的数量为：\(array.count)")
                    }
                    if count > 0 {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(array.last?.heart ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(CGFloat(array.last?.heart ?? 0) / 200)
                    } else {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(0)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                var count = 0
                let array = readDBHeart()
                if array.count > 0 {
                    count = array.count
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].heartRate
                        let x = (array[i].timeStamp - Int(zero)) / 3660
                        if x >= 0 && x < 24 {
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
                        }
                    }
                    XLogger.shared.log("获取到数据的数量为：\(array.count)")
                }
                if count > 0 {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(array.last?.heartRate ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(CGFloat(array.last?.heartRate ?? 0) / 200)
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
        } else if type == 4 { // 血压
            if isXGZT {
                var count = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readPressure { [weak self] pressureObjs in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    let array = pressureObjs
                    if array.count > 0 {
                        count = array.count
                        let zero = self.mDate.zeroTimeStampUTC()
                        for i in 0..<array.count {
                            let value = array[i].max
                            let x = (array[i].time - Int(zero)) / 3660
                            if x >= 0 && x < 24 {
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
                            }
                        }
                        XLogger.shared.log("获取到数据的数量为：\(array.count)")
                    }
                    if count > 0 {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(array.last?.max ?? 0)/\(array.last?.min ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                        b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(CGFloat(array.last?.max ?? 0) / 200)
                    } else {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                        b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(0)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                var count = 0
                let array = readPressure()
                if array.count > 0 {
                    count = array.count
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].max
                        let x = (array[i].timeStamp - Int(zero)) / 3660
                        if x >= 0 && x < 24 {
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
                        }
                    }
                    XLogger.shared.log("获取到数据的数量为：\(array.count)")
                }
                if count > 0 {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(array.last?.max ?? 0)/\(array.last?.min ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                    b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(CGFloat(array.last?.max ?? 0) / 200)
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                    b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
            
        } else if type == 5 { // 血氧
            if isXGZT {
                var count = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readXGZTBlood { [weak self] oxgenObjs in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    let array = oxgenObjs
                    XLogger.shared.log("从数据库里读取到的血氧数据数量为：\(array.count)")
                    if array.count > 0 {
                        count = array.count
                        let zero = self.mDate.zeroTimeStampUTC()
                        for i in 0..<array.count {
                            let value = array[i].oxgen
                            let x = (array[i].time - Int(zero)) / 3660
                            if x >= 0 && x < 24 {
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(20))
                            }
                        }
                        XLogger.shared.log("获取到数据的数量为：\(array.count)")
                    }
                    if count > 0 {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(array.last?.oxgen ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(CGFloat(array.last?.oxgen ?? 0) / 200)
                    } else {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(0)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                var count = 0
                let array = readBlood()
                XLogger.shared.log("从数据库里读取到的血氧数据数量为：\(array.count)")
                if array.count > 0 {
                    count = array.count
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].oxygen
                        let x = (array[i].timeStamp - Int(zero)) / 3660
                        if x >= 0 && x < 24 {
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(20))
                        }
                    }
                    XLogger.shared.log("获取到数据的数量为：\(array.count)")
                }
                if count > 0 {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(array.last?.oxygen ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(CGFloat(array.last?.oxygen ?? 0) / 200)
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
        }
    }
    
    private func initializeBarData(completion: @escaping ([BarChartDataEntry]) -> Void) {
        var values: [BarChartDataEntry] = []
        for i in 0...4 {
            values.append(BarChartDataEntry(x: Double(i), y: Double(0)))
        }
        if type == 3 { // 睡眠
            if isXGZT {
                readXGZTDBSleep { [weak self] v in
                    guard let self = self else { return }
                    let array = v
                    if array.count > 0 {
                        let total = array[0].light + array[0].deep
                        let h = total / 60
                        let m = total % 60
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(h)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_hour".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        b.append(NSAttributedString(string: "\(m)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        if array.count > 0 {
                            let m1 = array[0].awake
                            let m2 = array[0].light
                            let m3 = array[0].deep
                            let qing = NSMutableAttributedString()
                            qing.append(NSAttributedString(string: "\(m1)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                            qing.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                            let qian = NSMutableAttributedString()
                            qian.append(NSAttributedString(string: "\(m2)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                            qian.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                            let shen = NSMutableAttributedString()
                            shen.append(NSAttributedString(string: "\(m3)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                            shen.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                            self.fanView.refreshValue(values: [qing, qian, shen], value: b)
                            self.fanView.setProgress(CGFloat(total) / (60*12))
                            values[1] = BarChartDataEntry(x: Double(1), y: Double(m1) / 100)
                            values[2] = BarChartDataEntry(x: Double(2), y: Double(m2) / 100)
                            values[3] = BarChartDataEntry(x: Double(3), y: Double(m3) / 100)
                        }
                    } else {
                        let qing = NSMutableAttributedString()
                        qing.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qing.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let qian = NSMutableAttributedString()
                        qian.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qian.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let shen = NSMutableAttributedString()
                        shen.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        shen.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                        b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                        self.fanView.refreshValue(values: [qing, qian, shen], value: b)
                        self.fanView.setProgress(0)
                    }
                    completion(values)
                }
            } else {
                let array = readDBSleep()
                if array.count > 0 {
                    let a = array.map { item -> SleepModel in
                        let model = SleepModel()
                        model.timeStamp = item.timeStamp
                        model.totalCount = item.totalCount
                        model.indexOfTotal = item.indexOfTotal
                        model.mac = item.mac
                        model.uuidString = item.uuidString
                        model.state = item.state
                        model.day = item.day
                        return model
                    }
                    let arr = BLEManager.shared.readSleepData(array: a) // 获得睡眠时间
                    let total = arr[1] + arr[2]
                    let h = total / 60
                    let m = total % 60
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(h)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_hour".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    b.append(NSAttributedString(string: "\(m)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    if arr.count == 3 {
                        let m1 = arr[2]
                        let m2 = arr[1]
                        let m3 = arr[0]
                        let qing = NSMutableAttributedString()
                        qing.append(NSAttributedString(string: "\(m1)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qing.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let qian = NSMutableAttributedString()
                        qian.append(NSAttributedString(string: "\(m2)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qian.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let shen = NSMutableAttributedString()
                        shen.append(NSAttributedString(string: "\(m3)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        shen.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        fanView.refreshValue(values: [qing, qian, shen], value: b)
                        fanView.setProgress(CGFloat(total) / (60*12))
                        values[1] = BarChartDataEntry(x: Double(1), y: Double(m1) / 100)
                        values[2] = BarChartDataEntry(x: Double(2), y: Double(m2) / 100)
                        values[3] = BarChartDataEntry(x: Double(3), y: Double(m3) / 100)
                    }
                } else {
                    let qing = NSMutableAttributedString()
                    qing.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    qing.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let qian = NSMutableAttributedString()
                    qian.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    qian.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let shen = NSMutableAttributedString()
                    shen.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    shen.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                    b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                    fanView.refreshValue(values: [qing, qian, shen], value: b)
                    fanView.setProgress(0)
                }
                completion(values)
            }
        } else {
            completion(values)
        }
    }
    
    /// 选择日期
    @objc func chooseDate() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateHeroTap(on: dateCapsuleView)
        let pickerView = TTADataPickerView(title: "health_select_time".localized(), type: .text, delegate: nil)
        pickerView.type = .date
        pickerView.delegate = self
        pickerView.show {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = UIColor(white: 1.0, alpha: 0.01)
            })
        }
    }
    
    @IBAction func pushToGoal(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Sport", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SetTargetCViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HealthDetailViewController: ChartViewDelegate {
    // ChartViewDelegate 方法
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        UISelectionFeedbackGenerator().selectionChanged()
        let targetView = chartView == lineChartView ? lineChartView : barChartView
        targetView.layer.removeAnimation(forKey: "health.chart.select")
        renderChartSelectionFeedback(on: targetView, highlight: highlight)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        chartView.highlightValue(nil, callDelegate: false)
        clearChartSelectionFeedback(animated: true)
    }
}

extension HealthDetailViewController {
    private func renderChartSelectionFeedback(on chartView: ChartViewBase, highlight: Highlight) {
        let point = chartView.getMarkerPosition(highlight: highlight)
        if chartHighlightGlowView.superview !== chartView {
            chartHighlightGlowView.removeFromSuperview()
            chartView.addSubview(chartHighlightGlowView)
        }
        if chartHighlightGuideLayer.superlayer !== chartView.layer {
            chartHighlightGuideLayer.removeFromSuperlayer()
            chartView.layer.addSublayer(chartHighlightGuideLayer)
        }
        if chartHighlightPulseLayer.superlayer !== chartView.layer {
            chartHighlightPulseLayer.removeFromSuperlayer()
            chartView.layer.addSublayer(chartHighlightPulseLayer)
        }
        
        chartHighlightGlowView.isHidden = false
        chartHighlightGlowView.center = point
        chartHighlightGlowView.transform = .identity
        chartHighlightGlowView.alpha = 1
        chartHighlightGlowView.layer.shadowColor = resolvedAccentColors().first?.withAlphaComponent(0.92).cgColor
        chartHighlightGuideLayer.strokeColor = resolvedAccentColors().first?.withAlphaComponent(0.62).cgColor
        chartHighlightPulseLayer.strokeColor = resolvedAccentColors().first?.withAlphaComponent(0.48).cgColor
        chartHighlightGradientLayer.colors = detailHighlightColors().map { $0.cgColor }
        
        let lineTop = max(10, point.y - 96)
        let lineBottom = min(chartView.bounds.height - 14, point.y + 96)
        let guidePath = UIBezierPath()
        guidePath.move(to: CGPoint(x: point.x, y: lineTop))
        guidePath.addLine(to: CGPoint(x: point.x, y: lineBottom))
        chartHighlightGuideLayer.path = guidePath.cgPath
        chartHighlightGuideLayer.opacity = 1
        
        let pulsePath = UIBezierPath(ovalIn: CGRect(x: point.x - 14, y: point.y - 14, width: 28, height: 28))
        chartHighlightPulseLayer.path = pulsePath.cgPath
        chartHighlightPulseLayer.removeAllAnimations()
        chartHighlightPulseLayer.opacity = 0.32
    }
    
    private func clearChartSelectionFeedback(animated: Bool) {
        let updates = {
            self.chartHighlightGlowView.alpha = 0
            self.chartHighlightGlowView.transform = .identity
            self.chartHighlightGuideLayer.opacity = 0
            self.chartHighlightPulseLayer.opacity = 0
        }
        
        let completion: (Bool) -> Void = { _ in
            self.chartHighlightGlowView.isHidden = true
            self.chartHighlightGlowView.transform = .identity
            self.chartHighlightGuideLayer.path = nil
            self.chartHighlightPulseLayer.path = nil
        }
        
        guard animated else {
            updates()
            completion(true)
            return
        }
        
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: updates, completion: completion)
    }
    
    private func detailHighlightColors() -> [UIColor] {
        let palette = resolvedAccentColors()
        let leading = palette.first ?? UIColor.brand
        let trailing = palette.count > 1 ? palette[1] : leading.withAlphaComponent(0.75)
        return [leading.withAlphaComponent(0.92), trailing.withAlphaComponent(0.70)]
    }
    
    private func hasMeaningfulValues(_ values: [ChartDataEntry]) -> Bool {
        values.contains { $0.y > 0.001 }
    }
    
    private func hasMeaningfulBarValues(_ values: [BarChartDataEntry]) -> Bool {
        values.contains { $0.y > 0.001 }
    }
    
    private func updateDetailEmptyState(isEmpty: Bool) {
        let configuration = detailEmptyStateConfiguration()
        valueView.configureEmptyState(imageName: configuration.imageName, title: configuration.title, subtitle: configuration.subtitle)
        valueView.refreshView(isHideNull: !isEmpty)
    }
    
    private func updateNarrativeSummary(_ presentation: DetailNarrativePresentation) {
        summaryChipLabel.text = presentation.chipText
        summaryTitleLabel.text = presentation.titleText
        summaryDetailLabel.text = presentation.detailText
    }
    
    private func defaultNarrativePresentation() -> DetailNarrativePresentation {
        let context = selectedDateContextText()
        switch type {
        case 0:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)重点查看活动分布与累计节奏",
                detailText: "上方关键值展示当天总步数，下方趋势图按小时拆解活动变化，适合快速判断全天活跃区间。"
            )
        case 2:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)重点查看心率波动与峰值时段",
                detailText: "先看上方关键值，再结合下方曲线判断当天心率是否稳定，以及高点出现在哪个时间段。"
            )
        case 3:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)重点查看睡眠结构与阶段占比",
                detailText: "上方关键值展示总体睡眠情况，下方柱状图进一步拆出清醒、浅睡和深睡的结构分布。"
            )
        case 4:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)重点查看血压峰值与全天变化",
                detailText: "先确认关键值区的主读数，再通过下方趋势图判断当天波动是否集中在某一时段。"
            )
        case 5:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)重点查看血氧稳定度与高低点",
                detailText: "上方关键值负责快速读数，下方趋势图帮助你判断全天血氧是否稳定，以及低点出现在哪个时段。"
            )
        default:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)健康详情",
                detailText: "这里会结合关键值与趋势图，帮助你更快理解当天健康数据。"
            )
        }
    }
    
    private func narrativePresentationForLineEntries(_ values: [ChartDataEntry], hasData: Bool) -> DetailNarrativePresentation {
        guard hasData, let peakEntry = values.filter({ $0.y > 0.001 }).max(by: { $0.y < $1.y }) else {
            return defaultNarrativePresentation()
        }
        
        let context = selectedDateContextText()
        let peakHour = Int(peakEntry.x.rounded())
        let peakDisplay = detailMarkerDisplay(for: peakEntry.y)
        let latestDisplay = detailMarkerDisplay(for: values.last(where: { $0.y > 0.001 })?.y ?? peakEntry.y)
        let peakValueText = peakDisplay.detail.map { "\(peakDisplay.value) \($0)" } ?? peakDisplay.value
        let latestValueText = latestDisplay.detail.map { "\(latestDisplay.value) \($0)" } ?? latestDisplay.value
        
        switch type {
        case 0:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)活动高峰出现在 \(peakHour):00 左右",
                detailText: "当前峰值约为 \(peakValueText)，最后一次有效记录约为 \(latestValueText)。下方趋势图可继续查看全天活动推进节奏。"
            )
        case 2:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)最高心率出现在 \(peakHour):00 左右",
                detailText: "峰值约为 \(peakValueText)，最近一次有效记录约为 \(latestValueText)。轻触曲线可继续查看具体时段读数。"
            )
        case 4:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)血压高点出现在 \(peakHour):00 左右",
                detailText: "当前图表峰值约为 \(peakValueText)，最后一次有效记录约为 \(latestValueText)。下方趋势图用于判断当天波动区间。"
            )
        case 5:
            return DetailNarrativePresentation(
                chipText: narrativeChipText(),
                titleText: "\(context)血氧高点出现在 \(peakHour):00 左右",
                detailText: "当前峰值约为 \(peakValueText)，最近一次有效记录约为 \(latestValueText)。你可以继续在下方查看全天稳定度变化。"
            )
        default:
            return defaultNarrativePresentation()
        }
    }
    
    private func narrativePresentationForBarEntries(_ values: [BarChartDataEntry], hasData: Bool) -> DetailNarrativePresentation {
        guard hasData else {
            return defaultNarrativePresentation()
        }
        
        let validValues = values.filter { $0.y > 0.001 }
        guard let dominantEntry = validValues.max(by: { $0.y < $1.y }) else {
            return defaultNarrativePresentation()
        }
        
        let stageTitle = sleepStageTitle(for: Int(dominantEntry.x.rounded()))
        let stageDuration = sleepMarkerValueText(for: dominantEntry.y)
        let totalDuration = sleepMarkerValueText(for: validValues.reduce(0) { $0 + $1.y })
        let context = selectedDateContextText()
        
        return DetailNarrativePresentation(
            chipText: narrativeChipText(),
            titleText: "\(context)\(stageTitle)占比最高",
            detailText: "当前总睡眠时长约为 \(totalDuration)，其中 \(stageTitle) 约 \(stageDuration)。下方柱状图可继续查看各睡眠阶段分布。"
        )
    }
    
    private func narrativeChipText() -> String {
        Calendar.current.isDateInToday(mDate) ? "今日摘要" : "历史回顾"
    }
    
    private func selectedDateContextText() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(mDate) {
            return "今天"
        }
        if calendar.isDateInYesterday(mDate) {
            return "昨天"
        }
        return mDate.stringFromYmd()
    }
    
    private func trendSectionTitle() -> String {
        switch type {
        case 3:
            return "睡眠趋势"
        case 2:
            return "心率趋势"
        case 4:
            return "血压趋势"
        case 5:
            return "血氧趋势"
        default:
            return "活动趋势"
        }
    }
    
    private func trendSectionHelperText() -> String {
        switch type {
        case 3:
            return "按阶段查看 \(selectedDateContextText()) 的睡眠结构"
        default:
            return "轻触图表查看 \(selectedDateContextText()) 的具体时段数据"
        }
    }
    
    private func detailEmptyStateConfiguration() -> (imageName: String, title: String, subtitle: String) {
        switch type {
        case 0:
            return ("health_empty_metrics", "null_data".localized(), "qushi".localized().capitalized)
        case 2:
            return ("health_empty_disconnected", "null_data".localized(), "heart_desc".localized())
        case 3:
            return ("health_empty_metrics", "null_data".localized(), "health_sleep".localized())
        case 4:
            return ("health_empty_device", "null_data".localized(), "blood_pressure_desc".localized())
        case 5:
            return ("health_empty_metrics", "null_data".localized(), "health_blood_oxygen".localized())
        default:
            return ("health_empty_metrics", "null_data".localized(), "qushi".localized())
        }
    }
    
    private func detailMarkerDisplay(for value: Double) -> (value: String, detail: String?) {
        switch type {
        case 0:
            return ("\(Int(value.rounded()))", "health_step_noun".localized())
        case 2:
            return ("\(Int(value.rounded()))", "health_value_p_minute".localized())
        case 4:
            return ("\(Int(value.rounded()))", "MMHG")
        case 5:
            return ("\(Int(value.rounded()))", "SPO2")
        default:
            return ("\(Int(value.rounded()))", nil)
        }
    }
    
    private func sleepStageTitle(for index: Int) -> String {
        switch index {
        case 1:
            return "health_detail_sleep_awake".localized()
        case 2:
            return "health_detail_sleep_light".localized()
        case 3:
            return "health_detail_sleep_deep".localized()
        default:
            return "health_sleep".localized()
        }
    }
    
    private func sleepMarkerValueText(for value: Double) -> String {
        let minutes = Int((value * 100).rounded())
        let hour = minutes / 60
        let minute = minutes % 60
        if hour > 0 {
            return "\(hour)\("health_hour".localized()) \(minute)\("health_minute".localized())"
        }
        return "\(minute)\("health_minute".localized())"
    }
}

private final class DetailInsetLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

extension HealthDetailViewController: CommonCalendarViewProtocol {
    func callbackForHide(_ date: Date) {
        commonCalendarView?.isHidden = true
        mDate = date
        refreshDisplayedDetail(animated: true)
    }
}

extension HealthDetailViewController {
    func changeTimeToWeek(_ value: Int) -> String {
        switch value {
        case 0:
            return "week_7".localized()
        case 1:
            return "week_1".localized()
        case 2:
            return "week_2".localized()
        case 3:
            return "week_3".localized()
        case 4:
            return "week_4".localized()
        case 5:
            return "week_5".localized()
        default:
            return "week_6".localized()
        }
    }
}

extension HealthDetailViewController {
    func readDBStep() -> [DStepModel] {
        XLogger.shared.log("你想查询的设备的mac地址是：\(lastestDeviceMac)")
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DStepModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readXGZTDBStep(completion: @escaping ([StepObj]) -> Void) {
        DatabaseManager.shared.getStepObj(byDate: mDate.stringFromYmd()) { results in
            let objs = results?.map { $0 } ?? []
            completion(objs)
        }
    }
    
    
    func readDBHeart() -> [DHeartRateModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DHeartRateModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readXGZTDBHeart(completion: @escaping ([HeartObj]) -> Void) {
        DatabaseManager.shared.getHeartObj(byDate: mDate.stringFromYmd()) { results in
            let heartObjs = results?.map { $0 } ?? []
            completion(heartObjs)
        }
    }
    
    
    func readDBSleep() -> [DSleepModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DSleepModel.er.array("timeStamp>=\(stamp - 2 * 60 * 60) AND timeStamp<\(stamp + 10 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
        
    }
    
    func readXGZTDBSleep(completion: @escaping ([SleepObj]) -> Void) {
        if mDate.isToday() {
            let sleep = XGZTBlueToothManager.shared.device?.currentSleepArray ?? [0, 0, 0]
            if sleep[0] + sleep[1] + sleep[2] > 0 {
                let sleepObj = SleepObj()
                sleepObj.date = mDate.stringFromYmd()
                sleepObj.mac = lastestDeviceMac
                sleepObj.awake = sleep[0]
                sleepObj.light = sleep[1]
                sleepObj.deep = sleep[2]
                completion([sleepObj])
                return
            }
        }
        DatabaseManager.shared.getSleepObj(byDate: mDate.stringFromYmd()) { results in
            let objs = results?.map { $0 } ?? []
            completion(objs)
        }
        
    }
    
    func readPressure() -> [DBloodModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DBloodModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readPressure(completion: @escaping ([BloodObj]) -> Void) {
        DatabaseManager.shared.getBloodObj(byDate: mDate.stringFromYmd()) { results in
            let objs = results?.map { $0 } ?? []
            completion(objs)
        }
    }
    
    func readBlood() -> [DOxygenModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DOxygenModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readXGZTBlood(completion: @escaping ([OxgenObj]) -> Void) {
        DatabaseManager.shared.getOxgenObj(byDate: mDate.stringFromYmd()) { results in
            let oxgenObjs = results?.map { $0 } ?? []
            completion(oxgenObjs)
        }
    }
}

extension HealthDetailViewController: TTADataPickerViewDelegate {
    // when the pickerView type is `.text`, you clicked the done button, you will get the titles you selected just now from the `titles` parameter
    func dataPickerView(_ pickerView: TTADataPickerView, didSelectTitles titles: [String]) {
        //showLabel.text = titles.joined(separator: " ")
    }
    // when the pickerView type is NOT `.text`, you clicked the done button, you will get the date you selected just now from the `date` parameters
    func dataPickerView(_ pickerView: TTADataPickerView, didSelectDate date: Date) {
        mDate = date
        refreshDisplayedDetail(animated: true)
    }
    // when the pickerView  has been changed, this function will be called, and you will get the row and component which changed just now
    func dataPickerView(_ pickerView: TTADataPickerView, didChange row: Int, inComponent component: Int) {
        XLogger.shared.log(#function)
    }
    // when you clicked the cancel button, this function will be called firstly
    func dataPickerViewWillCancel(_ pickerView: TTADataPickerView) {
        XLogger.shared.log(#function)
    }
    // when you clicked the cancel button, this function will be called at the last
    func dataPickerViewDidCancel(_ pickerView: TTADataPickerView) {
        XLogger.shared.log(#function)
    }
}

extension HealthDetailViewController: TestViewDelegate {
    func handleStartTest() {
        if isXGZT{
            if type == 2 {
                XGZTCommand.startTest(cmdType: 0, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                    
                }
            }
            if type == 4 {
                XGZTCommand.startTest(cmdType: 2, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }
            
            if type == 5 {
                XGZTCommand.startTest(cmdType: 1, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }
            return
        }
        if type == 2 {
            bleSelf.startMeasure(WristbandMeasureType.heart)
            testView.testing()
            measureAsync = Async.main(after: 30) {
                // do something for update UI
                
            }
        }
        if type == 4 {
            bleSelf.startMeasure(WristbandMeasureType.blood)
            testView.testing()
            measureAsync = Async.main(after: 30) {
                // do something for update UI
            }
        }
        
        if type == 5 {
            bleSelf.startMeasure(WristbandMeasureType.oxygen)
            testView.testing()
            measureAsync = Async.main(after: 30) {
                // do something for update UI
            }
        }
    }
}

class CustomXAxisFormatter: NSObject, IAxisValueFormatter {
    var labels: [String] = []

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard labels.indices.contains(index) else {
            return ""
        }
        return labels[index]
    }
}
