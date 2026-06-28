//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  FemaleCycleCalendarViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2025/12/09.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

class FemaleCycleCalendarViewController: BaseViewController {

    private enum CyclePhaseStyle {
        case period
        case ovulation
        case safe
    }

    // MARK: - Properties

    // 数据管理器
    private let dataManager = FemaleCycleDataManager.shared
    private var hasAnimatedEntrance = false
    private let heroGradientLayer = CAGradientLayer()
    private var lastRenderedPhase: CyclePhaseStyle?
    private var lastAnimatedRecommendationKey: String?
    private let contentScrollView = UIScrollView()

    private struct SymptomSmartRecommendation {
        let flowLevel: Int
        let painLevel: Int
        let sexualSuggested: Bool
        let moodSuggested: Bool
        let bodySuggested: Bool
        let sexualPriority: Int
        let moodPriority: Int
        let bodyPriority: Int
        let insightText: String?
        let explanationTitle: String?
        let explanationDetail: String?
        let confidenceScore: CGFloat
        let confidenceText: String?
        let sourceChipText: String?
        let driverChipText: String?
        let traceTitle: String?
        let traceItems: [RecommendationTraceItem]
    }

    private struct RecommendationTraceItem {
        let text: String
        let targetRowKind: SymptomRowKind?
        let accentColor: UIColor?
    }

    private struct RecentSymptomHistoryProfile {
        let loggedDays: Int
        let sexualRecordCount: Int
        let moodRecordCount: Int
        let bodyRecordCount: Int
        let sensitiveMoodCount: Int
        let energeticMoodCount: Int
    }

    private var periodDays: Int = 7
    private var cycleLength: Int = 28
    private var lastPeriodDate: Date = Date()
    private var currentDisplayMonth: Date = Date()

    // 经期日期集合
    private var periodDates: Set<String> = []
    // 排卵期日期集合
    private var ovulationDates: Set<String> = []
    // 预测经期日期集合
    private var predictedPeriodDates: Set<String> = []
    // 当前日期
    private let today = Date()

    // 特殊日期标记
    private var periodFirstDay: String?
    private var periodLastDay: String?
    private var ovulationDay: String?
    private var ovulationFirstDay: String?
    private var ovulationLastDay: String?
    private var predictedFirstDay: String?

    // MARK: - UI Components

    private let monthYearContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let heroCardView = UIView()

    private let heroBadgeLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.text = "female_cycle_title".localized().uppercased()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = UIColor(red: 0.76, green: 0.18, blue: 0.43, alpha: 1.0)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        label.contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        label.layer.cornerRadius = 13
        label.layer.masksToBounds = true
        return label
    }()

    private let heroTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let heroSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.82)
        label.numberOfLines = 0
        return label
    }()

    private let selectedDateCapsuleLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        label.contentInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        label.layer.cornerRadius = 15
        label.layer.masksToBounds = true
        return label
    }()

    private let previousMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = UIColor(hex: 0x333333)
        return button
    }()

    private let nextMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = UIColor(hex: 0x333333)
        return button
    }()

    private let monthYearLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(hex: 0x333333)
        label.textAlignment = .center
        return label
    }()

    private let dropdownImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrowtriangle.down.fill")
        imageView.tintColor = UIColor(hex: 0x333333)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let weekdayContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private let legendContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let cycleInfoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xF8F8F8)
        view.layer.cornerRadius = 12
        return view
    }()

    private let cycleInfoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_overview".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(hex: 0x333333)
        return label
    }()

    private let periodDayInfoView: UIView = {
        let view = UIView()
        return view
    }()

    private let cycleLengthInfoView: UIView = {
        let view = UIView()
        return view
    }()

    private let periodValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = UIColor(hex: 0x333333)
        return label
    }()

    private let cycleValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = UIColor(hex: 0x333333)
        return label
    }()

    private let cycleDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_description".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hex: 0x666666)
        label.numberOfLines = 0
        return label
    }()

    private let futureRecordTipLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_future_warning".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hex: 0x999999)
        label.textAlignment = .center
        return label
    }()

    // 记录症状区域
    private let symptomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()

    private let symptomTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_record_symptoms".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(hex: 0x333333)
        return label
    }()

    private let symptomInsightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: 0xAA6A83)
        label.numberOfLines = 2
        return label
    }()

    private let recommendationExplanationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xFFF4F8)
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        view.isHidden = true
        return view
    }()

    private let recommendationExplanationBadgeLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.text = "WHY"
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        label.textColor = UIColor(hex: 0xC55780)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()

    private let recommendationExplanationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(hex: 0x7A3658)
        label.numberOfLines = 1
        return label
    }()

    private let recommendationExplanationDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hex: 0x8D5C72)
        label.numberOfLines = 0
        return label
    }()

    private let recommendationConfidenceCaptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor(hex: 0x96516F)
        return label
    }()

    private let recommendationConfidenceValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textAlignment = .right
        label.textColor = UIColor(hex: 0xC55780)
        return label
    }()

    private let recommendationConfidenceTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.52)
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()

    private let recommendationSourceChipLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        label.layer.cornerRadius = 11
        label.layer.masksToBounds = true
        return label
    }()

    private let recommendationDriverChipLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        label.layer.cornerRadius = 11
        label.layer.masksToBounds = true
        return label
    }()

    private let recommendationMetaStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()

    private let recommendationConfidenceFillView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xF38AB3)
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()

    private let recommendationTraceTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor(hex: 0x96516F)
        label.numberOfLines = 1
        return label
    }()

    private let recommendationTraceStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()

    private let symptomDateCapsuleLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.contentInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        return label
    }()

    private let symptomPhaseBadgeLabel: CalendarInsetLabel = {
        let label = CalendarInsetLabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        label.layer.cornerRadius = 13
        label.layer.masksToBounds = true
        return label
    }()

    private let periodStartSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor(hex: 0xFF69B4)
        return switchControl
    }()

    private enum SymptomRowKind {
        case flow
        case pain
        case sexual
        case mood
        case body
    }

    private var calendarDates: [Date?] = []

    // 当前选中的日期
    private var selectedDate: Date?

    // 症状记录数据
    private var isPeriodStarted: Bool = false
    private var flowLevel: Int = 0 // 0=未选择, 1=少, 2=中, 3=多
    private var painLevel: Int = 0 // 0=未选择, 1=轻微, 2=中等, 3=严重
    private var sexualActivity: Int = 0 // 0=无, 1=保护性行为, 2=无保护性行为
    private var mood: Int = 0 // 0=未选择, 1=平静, 2=开心, 3=放松, 4=活力满满, 5=敏感, 6=焦躁, 7=易怒, 8=悲伤
    private var bodySymptomsCount: Int = 0

    // 流量和痛经视图引用（用于显示/隐藏）
    private var flowRow: UIView?
    private var flowSeparator: UIView?
    private var painRow: UIView?
    private var painSeparator: UIView?
    private var periodStartRow: UIView?
    private var periodStartSeparator: UIView? // 经期开始开关的分隔线
    private var sexualRow: UIView? // 性行为行
    private var sexualSeparator: UIView?
    private var moodRowView: UIView?
    private var moodSeparator: UIView?
    private var bodySymptomsRowView: UIView?
    private var recommendationConfidenceWidthConstraint: Constraint?
    private var currentTraceItems: [RecommendationTraceItem] = []
    private var traceControlsByKind: [SymptomRowKind: [UIControl]] = [:]
    private let flowRecommendationLabel = CalendarInsetLabel()
    private let painRecommendationLabel = CalendarInsetLabel()
    private let sexualRecommendationLabel = CalendarInsetLabel()
    private let moodRecommendationLabel = CalendarInsetLabel()
    private let bodyRecommendationLabel = CalendarInsetLabel()

    // 按钮容器引用（用于刷新按钮状态）
    private var flowOptionsView: UIView?
    private var painOptionsView: UIView?

    // 性行为和心情的值显示标签
    private var sexualValueLabel: UILabel?
    private var moodValueLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()

        title = "female_cycle_title".localized()

        // 默认选中今天
        selectedDate = today

        setupNavigationBar()
        loadFemaleHealthData()
        calculateCycleDates()
        setupUI()
        updateMonthYearLabel()
        generateCalendarDates()
        updateCycleInfo()
        updateSymptomSectionVisibility()
        updateSelectedDateSummary()

        // 注册数据变更通知
        setupNotificationObservers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradientLayer.frame = heroCardView.bounds
        [
            monthYearContainerView,
            weekdayContainerView,
            calendarCollectionView,
            legendContainerView,
            cycleInfoContainerView,
            symptomContainerView
        ].forEach { targetView in
            targetView.layer.shadowPath = UIBezierPath(
                roundedRect: targetView.bounds,
                cornerRadius: targetView.layer.cornerRadius
            ).cgPath
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntranceIfNeeded()
    }

    deinit {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 通知管理

    private func setupNotificationObservers() {
        // 监听周期配置变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCycleConfigurationDidChange),
            name: .cycleConfigurationDidChange,
            object: nil
        )

        // 监听每日数据变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFemaleCycleDataDidChange),
            name: .femaleCycleDataDidChange,
            object: nil
        )
    }

    @objc private func handleCycleConfigurationDidChange() {
        // 重新加载周期配置
        loadFemaleHealthData()
        calculateCycleDates()
        updateCycleInfo(animated: true)
        generateCalendarDates()

        // 如果当前有选中日期，重新加载症状数据
        if let selectedDate = selectedDate {
            loadSymptomData(for: selectedDate)
        }
    }

    @objc private func handleFemaleCycleDataDidChange(notification: Notification) {
        // 刷新日历显示（可能有新的记录标记）
        generateCalendarDates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 重新加载数据并更新显示
        loadFemaleHealthData()
        calculateCycleDates()
        updateCycleInfo()
        generateCalendarDates()
    }

    private func setupNavigationBar() {
        let rightButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(rightBarButtonTapped)
        )
        rightButton.tintColor = UIColor(red: 0.84, green: 0.28, blue: 0.51, alpha: 1.0)
        navigationItem.rightBarButtonItem = rightButton
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xFFF7FA)

        // 创建滚动视图
        contentScrollView.showsVerticalScrollIndicator = true
        contentScrollView.backgroundColor = UIColor(hex: 0xFFF7FA)
        view.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let contentView = UIView()
        contentScrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(contentScrollView)
        }

        heroCardView.layer.cornerRadius = 30
        heroCardView.layer.cornerCurve = .continuous
        heroCardView.layer.masksToBounds = true
        heroGradientLayer.colors = [
            UIColor(red: 0.98, green: 0.48, blue: 0.66, alpha: 1.0).cgColor,
            UIColor(red: 0.73, green: 0.39, blue: 0.95, alpha: 1.0).cgColor
        ]
        heroGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        heroGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        heroCardView.layer.insertSublayer(heroGradientLayer, at: 0)

        contentView.addSubview(heroCardView)
        heroCardView.addSubview(heroBadgeLabel)
        heroCardView.addSubview(heroTitleLabel)
        heroCardView.addSubview(heroSubtitleLabel)
        heroCardView.addSubview(selectedDateCapsuleLabel)

        heroCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(170)
        }

        heroBadgeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(22)
        }

        selectedDateCapsuleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(20)
        }

        heroTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(heroBadgeLabel)
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalTo(heroBadgeLabel.snp.bottom).offset(16)
        }

        heroSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(heroTitleLabel)
            make.trailing.equalTo(heroTitleLabel)
            make.top.equalTo(heroTitleLabel.snp.bottom).offset(8)
        }

        configureCardSurface(heroCardView, cornerRadius: 30, shadowOpacity: 0)

        configureCardSurface(monthYearContainerView, cornerRadius: 22)
        configureCardSurface(weekdayContainerView, cornerRadius: 18)
        configureCardSurface(calendarCollectionView, cornerRadius: 0)
        configureCardSurface(legendContainerView, cornerRadius: 18)
        configureCardSurface(cycleInfoContainerView, cornerRadius: 24)
        configureCardSurface(symptomContainerView, cornerRadius: 24)

        monthYearContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        legendContainerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        previousMonthButton.backgroundColor = UIColor(hex: 0xFFF1F6)
        previousMonthButton.layer.cornerRadius = 16
        previousMonthButton.tintColor = UIColor(red: 0.84, green: 0.28, blue: 0.51, alpha: 1.0)
        nextMonthButton.backgroundColor = UIColor(hex: 0xFFF1F6)
        nextMonthButton.layer.cornerRadius = 16
        nextMonthButton.tintColor = UIColor(red: 0.84, green: 0.28, blue: 0.51, alpha: 1.0)

        monthYearLabel.textColor = UIColor(hex: 0x2E2230)
        dropdownImageView.tintColor = UIColor(red: 0.84, green: 0.28, blue: 0.51, alpha: 1.0)
        futureRecordTipLabel.textColor = UIColor(red: 0.72, green: 0.41, blue: 0.58, alpha: 1.0)
        futureRecordTipLabel.backgroundColor = UIColor(hex: 0xFFF1F6)
        futureRecordTipLabel.layer.cornerRadius = 14
        futureRecordTipLabel.layer.masksToBounds = true

        periodDayInfoView.backgroundColor = UIColor(hex: 0xFFF1F6)
        periodDayInfoView.layer.cornerRadius = 18
        cycleLengthInfoView.backgroundColor = UIColor(hex: 0xF3EEFF)
        cycleLengthInfoView.layer.cornerRadius = 18

        // Month/Year selector
        contentView.addSubview(monthYearContainerView)
        monthYearContainerView.snp.makeConstraints { make in
            make.top.equalTo(heroCardView.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(68)
        }

        monthYearContainerView.addSubview(previousMonthButton)
        previousMonthButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }

        monthYearContainerView.addSubview(nextMonthButton)
        nextMonthButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }

        monthYearContainerView.addSubview(monthYearLabel)
        monthYearLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }

        monthYearContainerView.addSubview(dropdownImageView)
        dropdownImageView.snp.makeConstraints { make in
            make.leading.equalTo(monthYearLabel.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(6)
        }

        previousMonthButton.addTarget(self, action: #selector(previousMonthTapped), for: .touchUpInside)
        nextMonthButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)

        // Weekday headers
        contentView.addSubview(weekdayContainerView)
        weekdayContainerView.snp.makeConstraints { make in
            make.top.equalTo(monthYearContainerView.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(40)
        }

        setupWeekdayHeaders()

        // Calendar collection view
        contentView.addSubview(calendarCollectionView)
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayContainerView.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(312)
        }

        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
        calendarCollectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "CalendarDayCell")

        // Legend
        contentView.addSubview(legendContainerView)
        legendContainerView.snp.makeConstraints { make in
            make.top.equalTo(calendarCollectionView.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(52)
        }

        setupLegend()

        // Cycle info
        contentView.addSubview(cycleInfoContainerView)
        cycleInfoContainerView.snp.makeConstraints { make in
            make.top.equalTo(legendContainerView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        cycleInfoContainerView.addSubview(cycleInfoTitleLabel)
        cycleInfoTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }

        // Period day info
        cycleInfoContainerView.addSubview(periodDayInfoView)
        periodDayInfoView.snp.makeConstraints { make in
            make.top.equalTo(cycleInfoTitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(150)
            make.height.equalTo(60)
        }

        let periodTitleLabel = UILabel()
        periodTitleLabel.text = "female_cycle_period".localized()
        periodTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        periodTitleLabel.textColor = UIColor(hex: 0x666666)
        periodDayInfoView.addSubview(periodTitleLabel)
        periodTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        periodDayInfoView.addSubview(periodValueLabel)
        periodValueLabel.snp.makeConstraints { make in
            make.top.equalTo(periodTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview()
        }

        // Cycle length info
        cycleInfoContainerView.addSubview(cycleLengthInfoView)
        cycleLengthInfoView.snp.makeConstraints { make in
            make.top.equalTo(cycleInfoTitleLabel.snp.bottom).offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(150)
            make.height.equalTo(60)
        }

        let cycleTitleLabel = UILabel()
        cycleTitleLabel.text = "female_cycle_cycle".localized()
        cycleTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        cycleTitleLabel.textColor = UIColor(hex: 0x666666)
        cycleLengthInfoView.addSubview(cycleTitleLabel)
        cycleTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        cycleLengthInfoView.addSubview(cycleValueLabel)
        cycleValueLabel.snp.makeConstraints { make in
            make.top.equalTo(cycleTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview()
        }

        // Cycle description
        cycleInfoContainerView.addSubview(cycleDescriptionLabel)
        cycleDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(periodDayInfoView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        cycleInfoContainerView.addSubview(futureRecordTipLabel)
        futureRecordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(cycleDescriptionLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }

        // Symptom recording section
        setupSymptomRecordingSection(contentView: contentView)
        updateSelectedDateSummary()
    }

    private func configureCardSurface(_ targetView: UIView, cornerRadius: CGFloat, shadowOpacity: Float = 1) {
        targetView.layer.cornerRadius = cornerRadius
        targetView.layer.cornerCurve = .continuous
        targetView.layer.borderWidth = 1
        targetView.layer.borderColor = UIColor.white.withAlphaComponent(0.88).cgColor
        targetView.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        targetView.layer.shadowOpacity = shadowOpacity
        targetView.layer.shadowRadius = 18
        targetView.layer.shadowOffset = CGSize(width: 0, height: 10)
    }

    private func animateEntranceIfNeeded() {
        guard !hasAnimatedEntrance else {
            return
        }
        hasAnimatedEntrance = true
        let animatedViews: [UIView] = [heroCardView, monthYearContainerView, weekdayContainerView, calendarCollectionView, legendContainerView, cycleInfoContainerView, symptomContainerView]
        for (index, targetView) in animatedViews.enumerated() {
            targetView.alpha = 0
            targetView.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.98, y: 0.98)
            UIView.animate(
                withDuration: 0.62,
                delay: min(Double(index) * 0.06, 0.28),
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.16,
                options: [.allowUserInteraction, .curveEaseOut]
            ) {
                targetView.alpha = 1
                targetView.transform = .identity
            }
        }
    }

    private func updateSelectedDateSummary() {
        let displayDate = selectedDate ?? today
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        selectedDateCapsuleLabel.text = formatter.string(from: displayDate).uppercased()
    }

    private func setupSymptomRecordingSection(contentView: UIView) {
        contentView.addSubview(symptomContainerView)
        symptomContainerView.snp.makeConstraints { make in
            make.top.equalTo(cycleInfoContainerView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }

        symptomContainerView.addSubview(symptomTitleLabel)
        symptomContainerView.addSubview(symptomInsightLabel)
        symptomContainerView.addSubview(recommendationExplanationView)
        symptomContainerView.addSubview(symptomDateCapsuleLabel)
        symptomContainerView.addSubview(symptomPhaseBadgeLabel)
        symptomTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(symptomDateCapsuleLabel.snp.leading).offset(-8)
        }

        symptomInsightLabel.snp.makeConstraints { make in
            make.top.equalTo(symptomTitleLabel.snp.bottom).offset(6)
            make.leading.equalTo(symptomTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        recommendationExplanationView.addSubview(recommendationExplanationBadgeLabel)
        recommendationExplanationView.addSubview(recommendationExplanationTitleLabel)
        recommendationExplanationView.addSubview(recommendationExplanationDetailLabel)
        recommendationExplanationView.addSubview(recommendationConfidenceCaptionLabel)
        recommendationExplanationView.addSubview(recommendationConfidenceValueLabel)
        recommendationExplanationView.addSubview(recommendationConfidenceTrackView)
        recommendationExplanationView.addSubview(recommendationMetaStackView)
        recommendationExplanationView.addSubview(recommendationTraceTitleLabel)
        recommendationExplanationView.addSubview(recommendationTraceStackView)
        recommendationConfidenceTrackView.addSubview(recommendationConfidenceFillView)
        recommendationMetaStackView.addArrangedSubview(recommendationSourceChipLabel)
        recommendationMetaStackView.addArrangedSubview(recommendationDriverChipLabel)
        recommendationExplanationView.snp.makeConstraints { make in
            make.top.equalTo(symptomInsightLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        recommendationExplanationBadgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }

        recommendationExplanationTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(recommendationExplanationBadgeLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
        }

        recommendationExplanationDetailLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendationExplanationTitleLabel.snp.bottom).offset(6)
            make.leading.equalTo(recommendationExplanationTitleLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        recommendationMetaStackView.snp.makeConstraints { make in
            make.top.equalTo(recommendationExplanationDetailLabel.snp.bottom).offset(8)
            make.leading.equalTo(recommendationExplanationTitleLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }

        recommendationConfidenceCaptionLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendationMetaStackView.snp.bottom).offset(10)
            make.leading.equalTo(recommendationExplanationTitleLabel)
        }

        recommendationConfidenceValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(recommendationConfidenceCaptionLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.leading.greaterThanOrEqualTo(recommendationConfidenceCaptionLabel.snp.trailing).offset(8)
        }

        recommendationConfidenceTrackView.snp.makeConstraints { make in
            make.top.equalTo(recommendationConfidenceCaptionLabel.snp.bottom).offset(8)
            make.leading.equalTo(recommendationExplanationTitleLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(6)
        }

        recommendationTraceTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendationConfidenceTrackView.snp.bottom).offset(10)
            make.leading.equalTo(recommendationExplanationTitleLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        recommendationTraceStackView.snp.makeConstraints { make in
            make.top.equalTo(recommendationTraceTitleLabel.snp.bottom).offset(8)
            make.leading.equalTo(recommendationExplanationTitleLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }

        recommendationConfidenceFillView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            self.recommendationConfidenceWidthConstraint = make.width.equalToSuperview().multipliedBy(0.56).constraint
        }

        symptomPhaseBadgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(symptomTitleLabel)
        }

        symptomDateCapsuleLabel.snp.makeConstraints { make in
            make.trailing.equalTo(symptomPhaseBadgeLabel.snp.leading).offset(-8)
            make.centerY.equalTo(symptomTitleLabel)
        }

        // 经期开始了吗
        let periodStartRow = createSymptomRow(
            icon: "💧",
            title: "female_cycle_period_started".localized(),
            hasSwitch: true
        )
        self.periodStartRow = periodStartRow
        symptomContainerView.addSubview(periodStartRow)
        periodStartRow.snp.makeConstraints { make in
            make.top.equalTo(recommendationExplanationView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        periodStartRow.addSubview(periodStartSwitch)
        periodStartSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        periodStartSwitch.addTarget(self, action: #selector(periodStartSwitchChanged), for: .valueChanged)

        // 分隔线
        let separator1 = createSeparator()
        periodStartSeparator = separator1
        symptomContainerView.addSubview(separator1)
        separator1.snp.makeConstraints { make in
            make.top.equalTo(periodStartRow.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // 流量
        let flowRowView = createSymptomRow(
            icon: "💧",
            title: "female_cycle_flow".localized(),
            hasSwitch: false
        )
        flowRow = flowRowView
        symptomContainerView.addSubview(flowRowView)
        flowRowView.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        let flowOptionsView = createFlowOptionsView()
        self.flowOptionsView = flowOptionsView // 保存引用
        flowRowView.addSubview(flowOptionsView)
        flowOptionsView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
        configureRecommendationLabel(flowRecommendationLabel, accentColor: UIColor(hex: 0xFF69B4))
        flowRowView.addSubview(flowRecommendationLabel)
        flowRecommendationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(flowOptionsView.snp.leading).offset(-10)
        }

        // 分隔线
        let separator2 = createSeparator()
        flowSeparator = separator2
        symptomContainerView.addSubview(separator2)
        separator2.snp.makeConstraints { make in
            make.top.equalTo(flowRowView.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // 痛经
        let painRowView = createSymptomRow(
            icon: "⚡️",
            title: "female_cycle_pain".localized(),
            hasSwitch: false
        )
        painRow = painRowView
        symptomContainerView.addSubview(painRowView)
        painRowView.snp.makeConstraints { make in
            make.top.equalTo(separator2.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        let painOptionsView = createPainOptionsView()
        self.painOptionsView = painOptionsView // 保存引用
        painRowView.addSubview(painOptionsView)
        painOptionsView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
        configureRecommendationLabel(painRecommendationLabel, accentColor: UIColor(hex: 0xA16AF7))
        painRowView.addSubview(painRecommendationLabel)
        painRecommendationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(painOptionsView.snp.leading).offset(-10)
        }

        // 分隔线
        let separator3 = createSeparator()
        painSeparator = separator3
        symptomContainerView.addSubview(separator3)
        separator3.snp.makeConstraints { make in
            make.top.equalTo(painRowView.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // 性行为
        let sexualRowView = createSymptomRow(
            icon: "💗",
            title: "female_cycle_sexual_activity".localized(),
            hasSwitch: false,
            hasArrow: true
        )
        sexualRow = sexualRowView
        symptomContainerView.addSubview(sexualRowView)
        sexualRowView.snp.makeConstraints { make in
            make.top.equalTo(separator3.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        // 添加性行为值显示标签
        let sexualLabel = UILabel()
        sexualLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        sexualLabel.textColor = UIColor(hex: 0xC55780)
        sexualLabel.text = "female_cycle_none".localized()
        sexualLabel.textAlignment = .right
        sexualLabel.layer.cornerRadius = 13
        sexualLabel.layer.masksToBounds = true
        sexualLabel.backgroundColor = UIColor(hex: 0xFFF0F6)
        self.sexualValueLabel = sexualLabel
        sexualRowView.addSubview(sexualLabel)
        sexualLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
            make.height.equalTo(26)
        }
        configureRecommendationLabel(sexualRecommendationLabel, accentColor: UIColor(hex: 0xE27B9E))
        sexualRowView.addSubview(sexualRecommendationLabel)
        sexualRecommendationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(sexualLabel.snp.leading).offset(-8)
        }

        let sexualTap = UITapGestureRecognizer(target: self, action: #selector(sexualActivityTapped))
        sexualRowView.addGestureRecognizer(sexualTap)

        // 分隔线
        let separator4 = createSeparator()
        sexualSeparator = separator4
        symptomContainerView.addSubview(separator4)
        separator4.snp.makeConstraints { make in
            make.top.equalTo(sexualRow!.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // 心情
        let moodRow = createSymptomRow(
            icon: "😊",
            title: "female_cycle_mood".localized(),
            hasSwitch: false,
            hasArrow: true
        )
        moodRowView = moodRow
        symptomContainerView.addSubview(moodRow)
        moodRow.snp.makeConstraints { make in
            make.top.equalTo(separator4.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        // 添加心情值显示标签
        let moodLabel = UILabel()
        moodLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        moodLabel.textColor = UIColor(hex: 0x7A5BE6)
        moodLabel.text = "female_cycle_none".localized()
        moodLabel.textAlignment = .right
        moodLabel.layer.cornerRadius = 13
        moodLabel.layer.masksToBounds = true
        moodLabel.backgroundColor = UIColor(hex: 0xF3EEFF)
        self.moodValueLabel = moodLabel
        moodRow.addSubview(moodLabel)
        moodLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
            make.height.equalTo(26)
        }
        configureRecommendationLabel(moodRecommendationLabel, accentColor: UIColor(hex: 0x8A63E8))
        moodRow.addSubview(moodRecommendationLabel)
        moodRecommendationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(moodLabel.snp.leading).offset(-8)
        }

        let moodTap = UITapGestureRecognizer(target: self, action: #selector(moodTapped))
        moodRow.addGestureRecognizer(moodTap)

        // 分隔线
        let separator5 = createSeparator()
        moodSeparator = separator5
        symptomContainerView.addSubview(separator5)
        separator5.snp.makeConstraints { make in
            make.top.equalTo(moodRow.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // 身体症状
        let bodyRow = createSymptomRow(
            icon: "💊",
            title: "female_cycle_body_symptoms".localized(),
            hasSwitch: false,
            hasArrow: true
        )
        bodySymptomsRowView = bodyRow
        symptomContainerView.addSubview(bodyRow)
        bodyRow.snp.makeConstraints { make in
            make.top.equalTo(separator5.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-16)
        }
        configureRecommendationLabel(bodyRecommendationLabel, accentColor: UIColor(hex: 0xF08D56))
        bodyRow.addSubview(bodyRecommendationLabel)
        bodyRecommendationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-40)
        }

        let bodyTap = UITapGestureRecognizer(target: self, action: #selector(bodySymptomsTapped))
        bodyRow.addGestureRecognizer(bodyTap)
    }

    private func createSymptomRow(icon: String, title: String, hasSwitch: Bool, hasArrow: Bool = false) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .white

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 24)
        containerView.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(32)
        }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor(hex: 0x333333)
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }

        if hasArrow {
            let arrowImageView = UIImageView()
            arrowImageView.image = UIImage(systemName: "chevron.right")
            arrowImageView.tintColor = UIColor(hex: 0xCCCCCC)
            arrowImageView.contentMode = .scaleAspectFit
            containerView.addSubview(arrowImageView)
            arrowImageView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(16)
            }
        }

        return containerView
    }

    private func configureRecommendationLabel(_ label: CalendarInsetLabel, accentColor: UIColor) {
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.contentInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        label.textColor = accentColor
        label.backgroundColor = accentColor.withAlphaComponent(0.10)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = accentColor.withAlphaComponent(0.10).cgColor
        label.isHidden = true
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor(hex: 0xF0F0F0)
        return separator
    }

    private func createFlowOptionsView() -> UIView {
        let containerView = UIView()

        let button1 = createDropletButton(level: 1, tag: 1)
        let button2 = createDropletButton(level: 2, tag: 2)
        let button3 = createDropletButton(level: 3, tag: 3)

        containerView.addSubview(button1)
        containerView.addSubview(button2)
        containerView.addSubview(button3)

        button1.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        button2.snp.makeConstraints { make in
            make.leading.equalTo(button1.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        button3.snp.makeConstraints { make in
            make.leading.equalTo(button2.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        return containerView
    }

    private func createDropletButton(level: Int, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.adjustsImageWhenHighlighted = false

        // 创建水滴形状的图片 - 累计选中（当前等级<=flowLevel时高亮）
        let image = createDropletImage(
            color: level <= flowLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
        )
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(flowButtonTapped(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(handleMetricButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(handleMetricButtonTouchRelease(_:)), for: [.touchDragExit, .touchCancel, .touchUpOutside])

        return button
    }

    private func createPainOptionsView() -> UIView {
        let containerView = UIView()

        let button1 = createLightningButton(level: 1, tag: 1)
        let button2 = createLightningButton(level: 2, tag: 2)
        let button3 = createLightningButton(level: 3, tag: 3)

        containerView.addSubview(button1)
        containerView.addSubview(button2)
        containerView.addSubview(button3)

        button1.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        button2.snp.makeConstraints { make in
            make.leading.equalTo(button1.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        button3.snp.makeConstraints { make in
            make.leading.equalTo(button2.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        return containerView
    }

    private func createLightningButton(level: Int, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.adjustsImageWhenHighlighted = false

        // 创建闪电形状的图片 - 累计选中（当前等级<=painLevel时高亮）
        let image = createLightningImage(
            color: level <= painLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
        )
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(painButtonTapped(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(handleMetricButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(handleMetricButtonTouchRelease(_:)), for: [.touchDragExit, .touchCancel, .touchUpOutside])

        return button
    }

    private func createDropletImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // 绘制更美观的水滴形状
            let path = UIBezierPath()

            // 水滴顶部尖点
            let topPoint = CGPoint(x: 16, y: 6)
            path.move(to: topPoint)

            // 左侧曲线 - 使用更流畅的贝塞尔曲线
            path.addCurve(
                to: CGPoint(x: 9, y: 18),
                controlPoint1: CGPoint(x: 11, y: 10),
                controlPoint2: CGPoint(x: 9, y: 14)
            )

            // 底部圆弧 - 左侧
            path.addCurve(
                to: CGPoint(x: 16, y: 26),
                controlPoint1: CGPoint(x: 9, y: 22),
                controlPoint2: CGPoint(x: 12, y: 26)
            )

            // 底部圆弧 - 右侧
            path.addCurve(
                to: CGPoint(x: 23, y: 18),
                controlPoint1: CGPoint(x: 20, y: 26),
                controlPoint2: CGPoint(x: 23, y: 22)
            )

            // 右侧曲线
            path.addCurve(
                to: topPoint,
                controlPoint1: CGPoint(x: 23, y: 14),
                controlPoint2: CGPoint(x: 21, y: 10)
            )

            path.close()

            // 添加渐变效果（可选）
            ctx.saveGState()
            path.addClip()

            // 创建渐变色
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [color.withAlphaComponent(1.0).cgColor, color.withAlphaComponent(0.7).cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                let startPoint = CGPoint(x: 16, y: 6)
                let endPoint = CGPoint(x: 16, y: 26)
                ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            }

            ctx.restoreGState()

            // 添加高光效果
            let highlightPath = UIBezierPath()
            highlightPath.move(to: CGPoint(x: 13, y: 12))
            highlightPath.addCurve(
                to: CGPoint(x: 15, y: 16),
                controlPoint1: CGPoint(x: 12, y: 13),
                controlPoint2: CGPoint(x: 13, y: 15)
            )
            highlightPath.addCurve(
                to: CGPoint(x: 13, y: 12),
                controlPoint1: CGPoint(x: 15.5, y: 14),
                controlPoint2: CGPoint(x: 14, y: 12.5)
            )
            highlightPath.close()

            UIColor.white.withAlphaComponent(0.4).setFill()
            highlightPath.fill()
        }
    }

    private func createLightningImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // 绘制更美观的闪电形状
            let path = UIBezierPath()

            // 闪电顶部
            path.move(to: CGPoint(x: 19, y: 5))

            // 左侧锯齿
            path.addLine(to: CGPoint(x: 11, y: 14))

            // 中间突出
            path.addLine(to: CGPoint(x: 15, y: 14))

            // 左下角锯齿
            path.addLine(to: CGPoint(x: 13, y: 27))

            // 底部尖点
            path.addLine(to: CGPoint(x: 14.5, y: 27))

            // 右下角锯齿
            path.addLine(to: CGPoint(x: 21, y: 17))

            // 中间凹陷
            path.addLine(to: CGPoint(x: 17, y: 17))

            // 右上角
            path.addLine(to: CGPoint(x: 20.5, y: 5))

            path.close()

            // 添加渐变效果
            ctx.saveGState()
            path.addClip()

            // 创建渐变色
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [color.withAlphaComponent(1.0).cgColor, color.withAlphaComponent(0.75).cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                let startPoint = CGPoint(x: 16, y: 5)
                let endPoint = CGPoint(x: 16, y: 27)
                ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            }

            ctx.restoreGState()

            // 添加高光边缘效果
            ctx.saveGState()

            // 绘制高光路径（闪电左侧）
            let highlightPath = UIBezierPath()
            highlightPath.move(to: CGPoint(x: 18.5, y: 6))
            highlightPath.addLine(to: CGPoint(x: 12, y: 14))
            highlightPath.addLine(to: CGPoint(x: 14.5, y: 14))
            highlightPath.lineWidth = 1.5

            UIColor.white.withAlphaComponent(0.5).setStroke()
            highlightPath.stroke()

            ctx.restoreGState()

            // 添加内部小闪光点
            let sparkPath = UIBezierPath()
            sparkPath.move(to: CGPoint(x: 15.5, y: 11))
            sparkPath.addLine(to: CGPoint(x: 16.5, y: 11))
            sparkPath.addLine(to: CGPoint(x: 16, y: 12))
            sparkPath.close()

            UIColor.white.withAlphaComponent(0.6).setFill()
            sparkPath.fill()
        }
    }

    private func setupWeekdayHeaders() {
        let weekdays = [
            "female_cycle_weekday_sun".localized(),
            "female_cycle_weekday_mon".localized(),
            "female_cycle_weekday_tue".localized(),
            "female_cycle_weekday_wed".localized(),
            "female_cycle_weekday_thu".localized(),
            "female_cycle_weekday_fri".localized(),
            "female_cycle_weekday_sat".localized()
        ]
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center

        for weekday in weekdays {
            let label = UILabel()
            label.text = weekday
            label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            label.textColor = UIColor(hex: 0x999999)
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }

        weekdayContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupLegend() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 8

        let predictedPeriodTitle = "female_cycle_predicted_period".localized()
        let legends = [
            ("female_cycle_period".localized(), UIColor(hex: 0xFFB3D9)),
            ("female_cycle_ovulation".localized(), UIColor(hex: 0xB8B3FF)),
            (predictedPeriodTitle, UIColor.clear),
            ("female_cycle_has_record".localized(), UIColor(hex: 0xFF69B4))
        ]

        for (title, color) in legends {
            let itemView = createLegendItem(title: title, color: color, isBordered: title == predictedPeriodTitle)
            stackView.addArrangedSubview(itemView)
        }

        legendContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
    }

    private func createLegendItem(title: String, color: UIColor, isBordered: Bool) -> UIView {
        let containerView = UIView()

        let itemStack = UIStackView()
        itemStack.axis = .horizontal
        itemStack.spacing = 4
        itemStack.alignment = .center
        itemStack.distribution = .fill

        let colorView = UIView()
        if isBordered {
            colorView.backgroundColor = .clear
            colorView.layer.borderWidth = 1.5
            colorView.layer.borderColor = UIColor(hex: 0xFFB3D9).cgColor
            colorView.layer.cornerRadius = 3
        } else {
            colorView.backgroundColor = color
            colorView.layer.cornerRadius = 3
        }

        colorView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        label.textColor = UIColor(hex: 0x666666)
        label.textAlignment = .left
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        itemStack.addArrangedSubview(colorView)
        itemStack.addArrangedSubview(label)

        containerView.addSubview(itemStack)
        itemStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(20)
        }

        return containerView
    }

    // MARK: - Data Management

    private func loadFemaleHealthData() {
        // 从数据管理器加载周期配置
        let config = dataManager.getCycleConfiguration()
        periodDays = config.periodDays
        cycleLength = config.cycleLength
        lastPeriodDate = config.lastPeriodDate

        XLogger.shared.log("加载周期配置: periodDays=\(periodDays), cycleLength=\(cycleLength), lastPeriodDate=\(lastPeriodDate)")
    }

    private func calculateCycleDates() {
        periodDates.removeAll()
        ovulationDates.removeAll()
        predictedPeriodDates.removeAll()
        periodFirstDay = nil
        periodLastDay = nil
        ovulationDay = nil
        ovulationFirstDay = nil
        ovulationLastDay = nil
        predictedFirstDay = nil

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // 计算当前经期
        for i in 0..<periodDays {
            if let date = calendar.date(byAdding: .day, value: i, to: lastPeriodDate) {
                let dateString = dateFormatter.string(from: date)
                periodDates.insert(dateString)

                // 标记经期第一天和最后一天
                if i == 0 {
                    periodFirstDay = dateString
                }
                if i == periodDays - 1 {
                    periodLastDay = dateString
                }
            }
        }

        // 计算排卵期（日历推算法）
        // 1. 排卵日 = 下次月经第一天 - 14天 = 本次月经第一天 + (周期长度 - 14)天
        // 2. 排卵期 = 排卵日前5天 到 排卵日后4天，共10天
        let ovulationDayOffset = cycleLength - 14 // 排卵日相对于本次月经第一天的偏移
        let ovulationStart = ovulationDayOffset - 5 // 排卵期开始（排卵日前5天）
        let ovulationEnd = ovulationDayOffset + 4   // 排卵期结束（排卵日后4天）

        for i in ovulationStart...ovulationEnd {
            if let date = calendar.date(byAdding: .day, value: i, to: lastPeriodDate) {
                let dateString = dateFormatter.string(from: date)

                // 标记排卵日（即使在经期内也标记，但不加入ovulationDates）
                if i == ovulationDayOffset {
                    ovulationDay = dateString
                }

                // 只有不在经期的日期才加入排卵期集合
                if !periodDates.contains(dateString) {
                    ovulationDates.insert(dateString)

                    // 标记排卵期第一天（实际进入排卵期集合的第一天）
                    if ovulationFirstDay == nil {
                        ovulationFirstDay = dateString
                    }
                    // 更新排卵期最后一天（实际进入排卵期集合的最后一天）
                    ovulationLastDay = dateString
                }
            }
        }

        // 计算预测的下一次经期
        if let nextPeriodStart = calendar.date(byAdding: .day, value: cycleLength, to: lastPeriodDate) {
            for i in 0..<periodDays {
                if let date = calendar.date(byAdding: .day, value: i, to: nextPeriodStart) {
                    let dateString = dateFormatter.string(from: date)
                    predictedPeriodDates.insert(dateString)

                    // 标记预测经期第一天
                    if i == 0 {
                        predictedFirstDay = dateString
                    }
                }
            }
        }
    }

    private func calculateCurrentPeriodDay() -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: lastPeriodDate, to: today).day ?? 0

        // 如果是负数，表示还没到经期
        if days < 0 {
            return 0
        }

        // 计算在当前周期的第几天（1-cycleLength）
        let currentCycleDay = (days % cycleLength) + 1

        return currentCycleDay
    }

    private func generateCalendarDates() {
        calendarDates.removeAll()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDisplayMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30

        // 添加前面的空白天数
        for _ in 1..<firstWeekday {
            calendarDates.append(nil)
        }

        // 添加当月的日期
        for day in 1...daysInMonth {
            var dateComponents = components
            dateComponents.day = day
            if let date = calendar.date(from: dateComponents) {
                calendarDates.append(date)
            }
        }

        calendarCollectionView.reloadData()
    }

    private func updateMonthYearLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let text = dateFormatter.string(from: currentDisplayMonth)
        if monthYearLabel.text == nil || monthYearLabel.text == text {
            monthYearLabel.text = text
        } else {
            UIView.transition(with: monthYearLabel, duration: 0.24, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.monthYearLabel.text = text
            }
        }
    }

    private func currentPhasePresentation(for date: Date?) -> (phase: CyclePhaseStyle, title: String, totalDays: Int, description: String, palette: [UIColor], tintColor: UIColor, softBackground: UIColor, badgeTextColor: UIColor, badgeBackground: UIColor) {
        let targetDate = date ?? today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let targetDateString = dateFormatter.string(from: targetDate)

        if periodDates.contains(targetDateString) {
            return (
                .period,
                "female_cycle_period".localized(),
                periodDays,
                "female_cycle_period_desc".localized(),
                [UIColor(hex: 0xFA739F), UIColor(hex: 0xF25E8D)],
                UIColor(hex: 0xD94477),
                UIColor(hex: 0xFFF1F6),
                UIColor(hex: 0xB93A68),
                UIColor(hex: 0xFFE4EE)
            )
        }

        if ovulationDates.contains(targetDateString) || targetDateString == ovulationDay {
            return (
                .ovulation,
                "female_cycle_ovulation".localized(),
                10,
                "female_cycle_ovulation_desc".localized(),
                [UIColor(hex: 0xA16AF7), UIColor(hex: 0x7C72FF)],
                UIColor(hex: 0x6C58E6),
                UIColor(hex: 0xF2EEFF),
                UIColor(hex: 0x674BDB),
                UIColor(hex: 0xECE5FF)
            )
        }

        return (
            .safe,
            "female_cycle_safe_period".localized(),
            max(cycleLength - periodDays - 10, 0),
            "female_cycle_description".localized(),
            [UIColor(hex: 0xF59773), UIColor(hex: 0xF0B15D)],
            UIColor(hex: 0xD98238),
            UIColor(hex: 0xFFF3E9),
            UIColor(hex: 0xB96722),
            UIColor(hex: 0xFFE9D8)
        )
    }

    private func updateCycleInfo(animated: Bool = false) {
        let phasePresentation = currentPhasePresentation(for: selectedDate)
        let phaseTitle = phasePresentation.title
        let phaseTotalDays = phasePresentation.totalDays
        let phaseDescription = phasePresentation.description

        // 更新左侧显示
        if let periodTitleLabel = periodDayInfoView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            if animated {
                UIView.transition(with: periodTitleLabel, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                    periodTitleLabel.text = phaseTitle
                }
            } else {
                periodTitleLabel.text = phaseTitle
            }
        }

        let periodValueAttrString = NSMutableAttributedString()
        periodValueAttrString.append(NSAttributedString(string: "female_cycle_total_prefix".localized(), attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x333333)
        ]))
        periodValueAttrString.append(NSAttributedString(string: "\(phaseTotalDays)", attributes: [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(hex: 0x333333)
        ]))
        periodValueAttrString.append(NSAttributedString(string: "female_cycle_days_suffix".localized(), attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x333333)
        ]))
        periodValueLabel.attributedText = periodValueAttrString

        let cycleValueAttrString = NSMutableAttributedString()
        cycleValueAttrString.append(NSAttributedString(string: "female_cycle_total_prefix".localized(), attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x333333)
        ]))
        cycleValueAttrString.append(NSAttributedString(string: "\(cycleLength)", attributes: [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(hex: 0x333333)
        ]))
        cycleValueAttrString.append(NSAttributedString(string: "female_cycle_days_suffix".localized(), attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor(hex: 0x333333)
        ]))
        cycleValueLabel.attributedText = cycleValueAttrString

        if animated {
            [cycleDescriptionLabel, heroTitleLabel, heroSubtitleLabel].forEach { (targetLabel: UILabel) in
                UIView.transition(with: targetLabel, duration: 0.24, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                    if targetLabel === self.cycleDescriptionLabel {
                        targetLabel.text = phaseDescription
                    } else if targetLabel === self.heroTitleLabel {
                        targetLabel.text = phaseTitle
                    } else {
                        targetLabel.text = phaseDescription
                    }
                }
            }
        } else {
            cycleDescriptionLabel.text = phaseDescription
            heroTitleLabel.text = phaseTitle
            heroSubtitleLabel.text = phaseDescription
        }

        applyPhaseStyling(phasePresentation, animated: animated)
        updateSymptomHeader(animated: animated)
        updateSelectedDateSummary()
    }

    private func updateSymptomSectionVisibility() {
        guard let selectedDate = selectedDate else {
            symptomContainerView.isHidden = true
            futureRecordTipLabel.isHidden = false
            return
        }

        let calendar = Calendar.current
        let isFutureDate = calendar.compare(selectedDate, to: today, toGranularity: .day) == .orderedDescending

        if isFutureDate {
            symptomContainerView.isHidden = true
            futureRecordTipLabel.isHidden = false
        } else {
            symptomContainerView.isHidden = false
            futureRecordTipLabel.isHidden = true
            loadSymptomData(for: selectedDate)
        }
        updateSymptomHeader(animated: false)
    }

    private func loadSymptomData(for date: Date) {
        let data = dataManager.getDailyData(for: date)

        flowLevel = data.flowLevel
        painLevel = data.painLevel
        sexualActivity = data.sexualActivity
        mood = data.mood
        bodySymptomsCount = data.bodySymptoms.count

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = dateFormatter.string(from: date)

        isPeriodStarted = (selectedDateString == periodFirstDay)

        periodStartSwitch.isOn = isPeriodStarted

        let isInPeriod = periodDates.contains(selectedDateString)
        let recommendation = recommendationPresentation(for: date, selectedDateString: selectedDateString, isInPeriod: isInPeriod)
        let effectiveBodySuggested = bodySymptomsCount == 0 && recommendation.bodySuggested
        let effectiveInsight = (flowLevel == 0 && recommendation.flowLevel > 0) || (painLevel == 0 && recommendation.painLevel > 0) || (sexualActivity == 0 && recommendation.sexualSuggested) || (mood == 0 && recommendation.moodSuggested) || effectiveBodySuggested
            ? recommendation.insightText
            : nil
        let effectiveRecommendation = SymptomSmartRecommendation(
            flowLevel: flowLevel == 0 ? recommendation.flowLevel : 0,
            painLevel: painLevel == 0 ? recommendation.painLevel : 0,
            sexualSuggested: sexualActivity == 0 && recommendation.sexualSuggested,
            moodSuggested: mood == 0 && recommendation.moodSuggested,
            bodySuggested: effectiveBodySuggested,
            sexualPriority: recommendation.sexualPriority,
            moodPriority: recommendation.moodPriority,
            bodyPriority: recommendation.bodyPriority,
            insightText: effectiveInsight,
            explanationTitle: recommendation.explanationTitle,
            explanationDetail: recommendation.explanationDetail,
            confidenceScore: recommendation.confidenceScore,
            confidenceText: recommendation.confidenceText,
            sourceChipText: recommendation.sourceChipText,
            driverChipText: recommendation.driverChipText,
            traceTitle: recommendation.traceTitle,
            traceItems: recommendation.traceItems
        )

        applySymptomRowOrdering(isInPeriod: isInPeriod, recommendation: effectiveRecommendation, animated: view.window != nil)

        refreshMetricButtons(in: flowOptionsView, selectedLevel: flowLevel, recommendedLevel: flowLevel == 0 ? recommendation.flowLevel : 0, type: .flow, animated: false)
        refreshMetricButtons(in: painOptionsView, selectedLevel: painLevel, recommendedLevel: painLevel == 0 ? recommendation.painLevel : 0, type: .pain, animated: false)
        updateRecommendationLabel(flowRecommendationLabel, level: flowLevel == 0 ? recommendation.flowLevel : 0, accentColor: UIColor(hex: 0xFF69B4), animated: false)
        updateRecommendationLabel(painRecommendationLabel, level: painLevel == 0 ? recommendation.painLevel : 0, accentColor: UIColor(hex: 0xA16AF7), animated: false)
        updateBooleanRecommendationLabel(sexualRecommendationLabel, isSuggested: sexualActivity == 0 && recommendation.sexualSuggested, text: "AI", accentColor: UIColor(hex: 0xE27B9E), animated: false)
        updateBooleanRecommendationLabel(moodRecommendationLabel, isSuggested: mood == 0 && recommendation.moodSuggested, text: "AI", accentColor: UIColor(hex: 0x8A63E8), animated: false)
        updateBooleanRecommendationLabel(bodyRecommendationLabel, isSuggested: effectiveBodySuggested, text: "GO", accentColor: UIColor(hex: 0xF08D56), animated: false)
        updateSymptomInsight(recommendation: effectiveRecommendation, animated: false)
        updateRecommendationExplanation(recommendation: effectiveRecommendation, animated: false)

        if let sexualLabel = sexualValueLabel {
            let sexualText: String
            switch sexualActivity {
            case 1:
                sexualText = "female_cycle_protected_sex".localized()
            case 2:
                sexualText = "female_cycle_unprotected_sex".localized()
            default:
                sexualText = "female_cycle_none".localized()
            }
            updateBadgeLabel(sexualLabel, text: sexualText, textColor: UIColor(hex: 0xC55780), backgroundColor: UIColor(hex: 0xFFF0F6), animated: false)
        }

        if let moodLabel = moodValueLabel {
            let moodBadge = moodPresentation(for: mood)
            updateBadgeLabel(moodLabel, text: moodBadge.text, textColor: moodBadge.textColor, backgroundColor: moodBadge.backgroundColor, animated: false)
        }

        updateSymptomHeader(animated: false)
        animateRecommendationIfNeeded(for: effectiveRecommendation, selectedDateString: selectedDateString)
        XLogger.shared.log("加载症状数据: \(selectedDateString) - \(data), 是否在经期: \(isInPeriod)")
    }

    private func applyPhaseStyling(_ phasePresentation: (phase: CyclePhaseStyle, title: String, totalDays: Int, description: String, palette: [UIColor], tintColor: UIColor, softBackground: UIColor, badgeTextColor: UIColor, badgeBackground: UIColor), animated: Bool) {
        let applyChanges = {
            self.heroGradientLayer.colors = phasePresentation.palette.map { $0.cgColor }
            self.periodDayInfoView.backgroundColor = phasePresentation.softBackground
            self.cycleLengthInfoView.backgroundColor = phasePresentation.phase == .ovulation ? UIColor(hex: 0xF0EBFF) : UIColor(hex: 0xFFF5EF)
            self.selectedDateCapsuleLabel.backgroundColor = phasePresentation.tintColor.withAlphaComponent(0.22)
            self.selectedDateCapsuleLabel.textColor = .white
        }

        if animated {
            let gradientAnimation = CABasicAnimation(keyPath: "colors")
            gradientAnimation.fromValue = heroGradientLayer.colors
            gradientAnimation.toValue = phasePresentation.palette.map { $0.cgColor }
            gradientAnimation.duration = 0.34
            gradientAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            heroGradientLayer.add(gradientAnimation, forKey: "female.phase.gradient")

            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                applyChanges()
                self.heroCardView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
                self.cycleInfoContainerView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
            } completion: { _ in
                UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
                    self.heroCardView.transform = .identity
                    self.cycleInfoContainerView.transform = .identity
                }
            }
        } else {
            applyChanges()
        }

        lastRenderedPhase = phasePresentation.phase
    }

    private func updateSymptomHeader(animated: Bool) {
        guard let selectedDate = selectedDate else {
            symptomDateCapsuleLabel.text = nil
            symptomPhaseBadgeLabel.text = nil
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let phasePresentation = currentPhasePresentation(for: selectedDate)
        let dateText = dateFormatter.string(from: selectedDate).uppercased()
        let badgeText = phasePresentation.title.uppercased()

        let updates = {
            self.symptomDateCapsuleLabel.text = dateText
            self.symptomDateCapsuleLabel.backgroundColor = phasePresentation.softBackground
            self.symptomDateCapsuleLabel.textColor = phasePresentation.tintColor
            self.symptomPhaseBadgeLabel.text = badgeText
            self.symptomPhaseBadgeLabel.textColor = phasePresentation.badgeTextColor
            self.symptomPhaseBadgeLabel.backgroundColor = phasePresentation.badgeBackground
        }

        if animated {
            UIView.transition(with: symptomDateCapsuleLabel, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction], animations: updates)
            UIView.transition(with: symptomPhaseBadgeLabel, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction], animations: nil)
        } else {
            updates()
        }
    }

    private func animateCalendarBridgeTransition(from sourceView: UIView?, date: Date) {
        guard let sourceView, !symptomContainerView.isHidden, futureRecordTipLabel.isHidden else {
            return
        }
        view.layoutIfNeeded()

        let phasePresentation = currentPhasePresentation(for: date)
        let snapshotView = makeCalendarBridgeSnapshot(for: date, tintColor: phasePresentation.tintColor, backgroundColor: phasePresentation.softBackground)
        let sourceFrame = view.convert(sourceView.bounds, from: sourceView)
        let targetFrame = view.convert(symptomDateCapsuleLabel.bounds, from: symptomDateCapsuleLabel)
        snapshotView.frame = sourceFrame
        snapshotView.layer.cornerRadius = min(sourceFrame.width, sourceFrame.height) / 2
        snapshotView.layer.cornerCurve = .continuous
        snapshotView.clipsToBounds = true

        symptomDateCapsuleLabel.alpha = 0
        symptomPhaseBadgeLabel.alpha = 0
        view.addSubview(snapshotView)

        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0.18, options: [.curveEaseOut, .allowUserInteraction]) {
            snapshotView.frame = targetFrame
            snapshotView.layer.cornerRadius = self.symptomDateCapsuleLabel.layer.cornerRadius
            snapshotView.transform = .identity
            self.symptomContainerView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
        } completion: { _ in
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.symptomDateCapsuleLabel.alpha = 1
                self.symptomPhaseBadgeLabel.alpha = 1
                self.symptomContainerView.transform = .identity
            } completion: { _ in
                snapshotView.removeFromSuperview()
            }
        }
    }

    private func makeCalendarBridgeSnapshot(for date: Date, tintColor: UIColor, backgroundColor: UIColor) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = backgroundColor
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = tintColor.withAlphaComponent(0.18).cgColor
        containerView.layer.shadowColor = tintColor.withAlphaComponent(0.28).cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 14
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)

        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = tintColor
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        label.text = formatter.string(from: date).uppercased()
        containerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return containerView
    }

    private func refreshFlowButtons() {
        refreshMetricButtons(in: flowOptionsView, selectedLevel: flowLevel, recommendedLevel: 0, type: .flow, animated: false)
    }

    private func refreshPainButtons() {
        refreshMetricButtons(in: painOptionsView, selectedLevel: painLevel, recommendedLevel: 0, type: .pain, animated: false)
    }

    private func refreshCurrentRecommendationState(animated: Bool) {
        guard let selectedDate = selectedDate else {
            updateRecommendationLabel(flowRecommendationLabel, level: 0, accentColor: UIColor(hex: 0xFF69B4), animated: animated)
            updateRecommendationLabel(painRecommendationLabel, level: 0, accentColor: UIColor(hex: 0xA16AF7), animated: animated)
            updateBooleanRecommendationLabel(sexualRecommendationLabel, isSuggested: false, text: "AI", accentColor: UIColor(hex: 0xE27B9E), animated: animated)
            updateBooleanRecommendationLabel(moodRecommendationLabel, isSuggested: false, text: "AI", accentColor: UIColor(hex: 0x8A63E8), animated: animated)
            updateBooleanRecommendationLabel(bodyRecommendationLabel, isSuggested: false, text: "GO", accentColor: UIColor(hex: 0xF08D56), animated: animated)
            let emptyRecommendation = SymptomSmartRecommendation(flowLevel: 0, painLevel: 0, sexualSuggested: false, moodSuggested: false, bodySuggested: false, sexualPriority: 0, moodPriority: 0, bodyPriority: 0, insightText: nil, explanationTitle: nil, explanationDetail: nil, confidenceScore: 0, confidenceText: nil, sourceChipText: nil, driverChipText: nil, traceTitle: nil, traceItems: [])
            applySymptomRowOrdering(isInPeriod: false, recommendation: emptyRecommendation, animated: animated)
            updateSymptomInsight(recommendation: emptyRecommendation, animated: animated)
            updateRecommendationExplanation(recommendation: emptyRecommendation, animated: animated)
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)
        let isInPeriod = periodDates.contains(dateString)
        let recommendation = recommendationPresentation(for: selectedDate, selectedDateString: dateString, isInPeriod: isInPeriod)
        let effectiveFlowLevel = flowLevel == 0 ? recommendation.flowLevel : 0
        let effectivePainLevel = painLevel == 0 ? recommendation.painLevel : 0
        let effectiveRecommendation = SymptomSmartRecommendation(
            flowLevel: effectiveFlowLevel,
            painLevel: effectivePainLevel,
            sexualSuggested: sexualActivity == 0 && recommendation.sexualSuggested,
            moodSuggested: mood == 0 && recommendation.moodSuggested,
            bodySuggested: bodySymptomsCount == 0 && recommendation.bodySuggested,
            sexualPriority: recommendation.sexualPriority,
            moodPriority: recommendation.moodPriority,
            bodyPriority: recommendation.bodyPriority,
            insightText: recommendation.insightText,
            explanationTitle: recommendation.explanationTitle,
            explanationDetail: recommendation.explanationDetail,
            confidenceScore: recommendation.confidenceScore,
            confidenceText: recommendation.confidenceText,
            sourceChipText: recommendation.sourceChipText,
            driverChipText: recommendation.driverChipText,
            traceTitle: recommendation.traceTitle,
            traceItems: recommendation.traceItems
        )
        applySymptomRowOrdering(isInPeriod: isInPeriod, recommendation: effectiveRecommendation, animated: animated)
        updateRecommendationLabel(flowRecommendationLabel, level: effectiveFlowLevel, accentColor: UIColor(hex: 0xFF69B4), animated: animated)
        updateRecommendationLabel(painRecommendationLabel, level: effectivePainLevel, accentColor: UIColor(hex: 0xA16AF7), animated: animated)
        updateBooleanRecommendationLabel(sexualRecommendationLabel, isSuggested: sexualActivity == 0 && recommendation.sexualSuggested, text: "AI", accentColor: UIColor(hex: 0xE27B9E), animated: animated)
        updateBooleanRecommendationLabel(moodRecommendationLabel, isSuggested: mood == 0 && recommendation.moodSuggested, text: "AI", accentColor: UIColor(hex: 0x8A63E8), animated: animated)
        let effectiveBodySuggested = bodySymptomsCount == 0 && recommendation.bodySuggested
        updateBooleanRecommendationLabel(bodyRecommendationLabel, isSuggested: effectiveBodySuggested, text: "GO", accentColor: UIColor(hex: 0xF08D56), animated: animated)
        let effectiveInsight = (effectiveFlowLevel > 0 || effectivePainLevel > 0 || (sexualActivity == 0 && recommendation.sexualSuggested) || (mood == 0 && recommendation.moodSuggested) || effectiveBodySuggested) ? recommendation.insightText : nil
        let syncedRecommendation = SymptomSmartRecommendation(flowLevel: effectiveFlowLevel, painLevel: effectivePainLevel, sexualSuggested: sexualActivity == 0 && recommendation.sexualSuggested, moodSuggested: mood == 0 && recommendation.moodSuggested, bodySuggested: effectiveBodySuggested, sexualPriority: recommendation.sexualPriority, moodPriority: recommendation.moodPriority, bodyPriority: recommendation.bodyPriority, insightText: effectiveInsight, explanationTitle: recommendation.explanationTitle, explanationDetail: recommendation.explanationDetail, confidenceScore: recommendation.confidenceScore, confidenceText: recommendation.confidenceText, sourceChipText: recommendation.sourceChipText, driverChipText: recommendation.driverChipText, traceTitle: recommendation.traceTitle, traceItems: recommendation.traceItems)
        let syncedRecommendationWithConfidence = SymptomSmartRecommendation(flowLevel: syncedRecommendation.flowLevel, painLevel: syncedRecommendation.painLevel, sexualSuggested: syncedRecommendation.sexualSuggested, moodSuggested: syncedRecommendation.moodSuggested, bodySuggested: syncedRecommendation.bodySuggested, sexualPriority: syncedRecommendation.sexualPriority, moodPriority: syncedRecommendation.moodPriority, bodyPriority: syncedRecommendation.bodyPriority, insightText: syncedRecommendation.insightText, explanationTitle: syncedRecommendation.explanationTitle, explanationDetail: syncedRecommendation.explanationDetail, confidenceScore: recommendation.confidenceScore, confidenceText: recommendation.confidenceText, sourceChipText: recommendation.sourceChipText, driverChipText: recommendation.driverChipText, traceTitle: recommendation.traceTitle, traceItems: recommendation.traceItems)
        updateSymptomInsight(recommendation: syncedRecommendationWithConfidence, animated: animated)
        updateRecommendationExplanation(recommendation: syncedRecommendationWithConfidence, animated: animated)
    }

    private enum SymptomMetricType {
        case flow
        case pain
    }

    private func refreshMetricButtons(in container: UIView?, selectedLevel: Int, recommendedLevel: Int, type: SymptomMetricType, animated: Bool) {
        guard let targetContainer = container else { return }
        let accentColor = type == .flow ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xA16AF7)
        let activeLevel = selectedLevel > 0 ? selectedLevel : recommendedLevel
        let isRecommendedState = selectedLevel == 0 && recommendedLevel > 0
        for subview in targetContainer.subviews {
            if let button = subview as? UIButton {
                let color = button.tag <= activeLevel
                    ? accentColor.withAlphaComponent(isRecommendedState ? 0.55 : 1.0)
                    : UIColor(hex: 0xE0E0E0)
                let image = type == .flow ? createDropletImage(color: color) : createLightningImage(color: color)
                button.setImage(image, for: .normal)
                let targetTransform: CGAffineTransform
                if selectedLevel > 0, button.tag == selectedLevel {
                    targetTransform = CGAffineTransform(scaleX: 1.18, y: 1.18)
                } else if selectedLevel > 0, button.tag < selectedLevel {
                    targetTransform = CGAffineTransform(scaleX: 1.06, y: 1.06)
                } else if isRecommendedState, button.tag == recommendedLevel {
                    targetTransform = CGAffineTransform(scaleX: 1.10, y: 1.10)
                } else if isRecommendedState, button.tag < recommendedLevel {
                    targetTransform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                } else {
                    targetTransform = .identity
                }
                let changes = {
                    button.transform = targetTransform
                }
                if animated {
                    UIView.animate(withDuration: 0.22, delay: Double(button.tag) * 0.03, usingSpringWithDamping: 0.68, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
                        changes()
                    } completion: { _ in
                        if button.tag == selectedLevel, selectedLevel > 0 {
                            UIView.animate(withDuration: 0.18, delay: 0.02, usingSpringWithDamping: 0.80, initialSpringVelocity: 0.12, options: [.allowUserInteraction, .curveEaseOut]) {
                                button.transform = CGAffineTransform(scaleX: 1.10, y: 1.10)
                            }
                        } else if isRecommendedState, button.tag == recommendedLevel {
                            UIView.animate(withDuration: 0.14, delay: 0.02, options: [.allowUserInteraction, .curveEaseInOut]) {
                                button.alpha = 0.82
                            } completion: { _ in
                                UIView.animate(withDuration: 0.18, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                                    button.alpha = 1
                                }
                            }
                        }
                    }
                } else {
                    button.alpha = 1
                    changes()
                }
            }
        }
    }

    private func updateRecommendationLabel(_ label: CalendarInsetLabel, level: Int, accentColor: UIColor, animated: Bool) {
        let updates = {
            label.text = level > 0 ? "\(level)/3" : nil
            label.textColor = accentColor
            label.backgroundColor = accentColor.withAlphaComponent(level > 0 ? 0.12 : 0)
            label.isHidden = level == 0
        }
        if animated {
            UIView.transition(with: label, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func updateBooleanRecommendationLabel(_ label: CalendarInsetLabel, isSuggested: Bool, text: String, accentColor: UIColor, animated: Bool) {
        let updates = {
            label.text = isSuggested ? text : nil
            label.textColor = accentColor
            label.backgroundColor = accentColor.withAlphaComponent(isSuggested ? 0.12 : 0)
            label.isHidden = !isSuggested
        }
        if animated {
            UIView.transition(with: label, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func updateSymptomInsight(recommendation: SymptomSmartRecommendation, animated: Bool) {
        let updates = {
            self.symptomInsightLabel.text = recommendation.insightText
            self.symptomInsightLabel.isHidden = recommendation.insightText == nil
        }
        if animated {
            UIView.transition(with: symptomInsightLabel, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func updateRecommendationExplanation(recommendation: SymptomSmartRecommendation, animated: Bool) {
        let phasePresentation = currentPhasePresentation(for: selectedDate ?? today)
        let hasExplanation = recommendation.explanationTitle != nil || recommendation.explanationDetail != nil
        let clampedConfidence = max(0.12, min(recommendation.confidenceScore, 1))
        let hasMeta = recommendation.sourceChipText != nil || recommendation.driverChipText != nil
        let hasTraceItems = !recommendation.traceItems.isEmpty
        recommendationExplanationView.snp.remakeConstraints { make in
            if hasExplanation {
                make.top.equalTo(symptomInsightLabel.snp.bottom).offset(10)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            } else {
                make.top.equalTo(symptomInsightLabel.snp.bottom)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.height.equalTo(0)
            }
        }
        if let periodStartRow {
            periodStartRow.snp.remakeConstraints { make in
                if hasExplanation {
                    make.top.equalTo(recommendationExplanationView.snp.bottom).offset(12)
                } else {
                    make.top.equalTo(symptomInsightLabel.snp.bottom).offset(14)
                }
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(56)
            }
        }
        recommendationMetaStackView.snp.remakeConstraints { make in
            if hasMeta {
                make.top.equalTo(recommendationExplanationDetailLabel.snp.bottom).offset(8)
                make.leading.equalTo(recommendationExplanationTitleLabel)
                make.trailing.lessThanOrEqualToSuperview().offset(-12)
            } else {
                make.top.equalTo(recommendationExplanationDetailLabel.snp.bottom)
                make.leading.equalTo(recommendationExplanationTitleLabel)
                make.trailing.lessThanOrEqualToSuperview().offset(-12)
                make.height.equalTo(0)
            }
        }
        recommendationConfidenceCaptionLabel.snp.remakeConstraints { make in
            if hasMeta {
                make.top.equalTo(recommendationMetaStackView.snp.bottom).offset(10)
            } else {
                make.top.equalTo(recommendationExplanationDetailLabel.snp.bottom).offset(10)
            }
            make.leading.equalTo(recommendationExplanationTitleLabel)
        }
        recommendationConfidenceTrackView.snp.remakeConstraints { make in
            make.top.equalTo(recommendationConfidenceCaptionLabel.snp.bottom).offset(8)
            make.leading.equalTo(recommendationExplanationTitleLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(6)
            if hasTraceItems {
                make.bottom.equalTo(recommendationTraceTitleLabel.snp.top).offset(-10)
            } else {
                make.bottom.equalToSuperview().offset(-12)
            }
        }
        recommendationTraceTitleLabel.snp.remakeConstraints { make in
            if hasTraceItems {
                make.top.equalTo(recommendationConfidenceTrackView.snp.bottom).offset(10)
                make.leading.equalTo(recommendationExplanationTitleLabel)
                make.trailing.equalToSuperview().offset(-12)
            } else {
                make.top.equalTo(recommendationConfidenceTrackView.snp.bottom)
                make.leading.equalTo(recommendationExplanationTitleLabel)
                make.trailing.equalToSuperview().offset(-12)
                make.height.equalTo(0)
            }
        }
        recommendationTraceStackView.snp.remakeConstraints { make in
            if hasTraceItems {
                make.top.equalTo(recommendationTraceTitleLabel.snp.bottom).offset(8)
                make.leading.equalTo(recommendationExplanationTitleLabel)
                make.trailing.equalToSuperview().offset(-12)
                make.bottom.equalToSuperview().offset(-12)
            } else {
                make.top.equalTo(recommendationTraceTitleLabel.snp.bottom)
                make.leading.equalTo(recommendationExplanationTitleLabel)
                make.trailing.equalToSuperview().offset(-12)
                make.height.equalTo(0)
                make.bottom.equalToSuperview().offset(0)
            }
        }
        let updates = {
            self.rebuildRecommendationTraceViews(items: recommendation.traceItems, tintColor: phasePresentation.tintColor)
            self.recommendationExplanationTitleLabel.text = recommendation.explanationTitle
            self.recommendationExplanationDetailLabel.text = recommendation.explanationDetail
            self.recommendationConfidenceCaptionLabel.text = recommendation.confidenceText
            self.recommendationConfidenceValueLabel.text = hasExplanation ? "\(Int((clampedConfidence * 100).rounded()))%" : nil
            self.recommendationSourceChipLabel.text = recommendation.sourceChipText
            self.recommendationDriverChipLabel.text = recommendation.driverChipText
            self.recommendationTraceTitleLabel.text = recommendation.traceTitle
            self.recommendationExplanationView.backgroundColor = phasePresentation.softBackground
            self.recommendationExplanationView.layer.borderColor = phasePresentation.tintColor.withAlphaComponent(0.14).cgColor
            self.recommendationExplanationTitleLabel.textColor = phasePresentation.tintColor
            self.recommendationExplanationDetailLabel.textColor = UIColor(hex: 0x8D5C72)
            self.recommendationExplanationBadgeLabel.textColor = phasePresentation.tintColor
            self.recommendationExplanationBadgeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.78)
            self.recommendationConfidenceCaptionLabel.textColor = phasePresentation.tintColor.withAlphaComponent(0.92)
            self.recommendationConfidenceValueLabel.textColor = phasePresentation.tintColor
            self.recommendationConfidenceTrackView.backgroundColor = phasePresentation.tintColor.withAlphaComponent(0.14)
            self.recommendationConfidenceFillView.backgroundColor = phasePresentation.tintColor
            self.recommendationSourceChipLabel.textColor = phasePresentation.tintColor
            self.recommendationSourceChipLabel.backgroundColor = UIColor.white.withAlphaComponent(0.78)
            self.recommendationDriverChipLabel.textColor = UIColor.white
            self.recommendationDriverChipLabel.backgroundColor = phasePresentation.tintColor.withAlphaComponent(0.88)
            self.recommendationMetaStackView.isHidden = !hasMeta
            self.recommendationSourceChipLabel.isHidden = recommendation.sourceChipText == nil
            self.recommendationDriverChipLabel.isHidden = recommendation.driverChipText == nil
            self.recommendationTraceTitleLabel.isHidden = !hasTraceItems
            self.recommendationTraceStackView.isHidden = !hasTraceItems
            self.recommendationExplanationView.isHidden = !hasExplanation
            self.recommendationExplanationView.alpha = hasExplanation ? 1 : 0
        }
        recommendationConfidenceFillView.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            self.recommendationConfidenceWidthConstraint = make.width.equalToSuperview().multipliedBy(hasExplanation ? clampedConfidence : 0.001).constraint
        }
        if animated {
            if hasExplanation {
                self.recommendationExplanationView.isHidden = false
            }
            UIView.animate(withDuration: 0.24, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                updates()
                self.view.layoutIfNeeded()
            }
        } else {
            updates()
        }
    }

    private func rebuildRecommendationTraceViews(items: [RecommendationTraceItem], tintColor: UIColor) {
        recommendationTraceStackView.arrangedSubviews.forEach { subview in
            recommendationTraceStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        currentTraceItems = Array(items.prefix(3))
        traceControlsByKind.removeAll()
        for (index, item) in currentTraceItems.enumerated() {
            let container = UIControl()
            container.tag = index
            container.layer.cornerRadius = 12
            container.layer.masksToBounds = true
            container.addTarget(self, action: #selector(handleRecommendationTraceTapped(_:)), for: .touchUpInside)

            let dotView = UIView()
            dotView.backgroundColor = (item.accentColor ?? tintColor).withAlphaComponent(0.78)
            dotView.layer.cornerRadius = 3
            dotView.layer.masksToBounds = true
            container.addSubview(dotView)
            dotView.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.top.equalToSuperview().offset(5)
                make.width.height.equalTo(6)
            }

            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 11, weight: .regular)
            label.textColor = UIColor(hex: 0x8D5C72)
            label.numberOfLines = 0
            label.text = item.text
            container.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.trailing.bottom.equalToSuperview()
                make.leading.equalTo(dotView.snp.trailing).offset(8)
            }

            recommendationTraceStackView.addArrangedSubview(container)
            if let targetRowKind = item.targetRowKind {
                traceControlsByKind[targetRowKind, default: []].append(container)
            }
        }
    }

    @objc private func handleRecommendationTraceTapped(_ sender: UIControl) {
        guard currentTraceItems.indices.contains(sender.tag) else {
            return
        }
        let item = currentTraceItems[sender.tag]
        UIView.animate(withDuration: 0.10, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            sender.alpha = 0.84
        } completion: { _ in
            UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                sender.transform = .identity
                sender.alpha = 1
            }
        }

        guard let targetKind = item.targetRowKind else {
            UISelectionFeedbackGenerator().selectionChanged()
            animateCapsuleRecommendation(on: recommendationExplanationBadgeLabel, accentColor: item.accentColor ?? UIColor(hex: 0xC55780))
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let accentColor = item.accentColor ?? UIColor(hex: 0xC55780)
        focusOnSymptomRow(targetKind, accentColor: accentColor)
    }

    private func focusOnSymptomRow(_ kind: SymptomRowKind, accentColor: UIColor) {
        guard let rowView = rowView(for: kind) else {
            return
        }
        view.layoutIfNeeded()
        contentScrollView.layoutIfNeeded()

        let targetRect = contentScrollView.convert(rowView.bounds, from: rowView)
        let preferredTopInset: CGFloat = 108
        let minimumOffsetY = -contentScrollView.adjustedContentInset.top
        let maximumOffsetY = max(minimumOffsetY, contentScrollView.contentSize.height - contentScrollView.bounds.height + contentScrollView.adjustedContentInset.bottom)
        let targetOffsetY = min(max(minimumOffsetY, targetRect.minY - preferredTopInset), maximumOffsetY)
        let currentOffsetY = contentScrollView.contentOffset.y
        let shouldScroll = abs(currentOffsetY - targetOffsetY) > 6

        let highlight = {
            self.animateRowHighlight(rowView, accentColor: accentColor)
        }

        guard shouldScroll else {
            highlight()
            return
        }

        UIView.animate(withDuration: 0.34, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
            self.contentScrollView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: false)
            self.view.layoutIfNeeded()
        } completion: { _ in
            highlight()
        }
    }

    private func highlightRecommendationTrace(for kind: SymptomRowKind, accentColor: UIColor) {
        let targetControls = traceControlsByKind[kind] ?? []
        guard !targetControls.isEmpty else {
            animateRecommendationCardFallback(accentColor: accentColor)
            return
        }

        for (index, control) in targetControls.enumerated() {
            let originalBackgroundColor = control.backgroundColor
            let originalTransform = control.transform
            UIView.animate(withDuration: 0.16, delay: Double(index) * 0.03, usingSpringWithDamping: 0.76, initialSpringVelocity: 0.18, options: [.allowUserInteraction, .curveEaseOut]) {
                control.backgroundColor = accentColor.withAlphaComponent(0.10)
                control.transform = CGAffineTransform(scaleX: 1.015, y: 1.015)
            } completion: { _ in
                UIView.animate(withDuration: 0.22, delay: 0.02, options: [.allowUserInteraction, .curveEaseOut]) {
                    control.backgroundColor = originalBackgroundColor
                    control.transform = originalTransform
                }
            }
        }
    }

    private func animateRecommendationCardFallback(accentColor: UIColor) {
        recommendationExplanationView.layer.removeAnimation(forKey: "female.trace.card.highlight")
        let originalBorderColor = recommendationExplanationView.layer.borderColor
        UIView.animate(withDuration: 0.16, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            self.recommendationExplanationView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
            self.recommendationExplanationView.layer.borderColor = accentColor.withAlphaComponent(0.32).cgColor
        } completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0.02, options: [.allowUserInteraction, .curveEaseOut]) {
                self.recommendationExplanationView.transform = .identity
                self.recommendationExplanationView.layer.borderColor = originalBorderColor
            }
        }
        animateCapsuleRecommendation(on: recommendationExplanationBadgeLabel, accentColor: accentColor)
    }

    private func orderedTrailingSymptomKinds(for recommendation: SymptomSmartRecommendation) -> [SymptomRowKind] {
        let baseOrder: [SymptomRowKind] = [.sexual, .mood, .body]
        let priorities: [SymptomRowKind: Int] = [
            .sexual: recommendation.sexualSuggested ? recommendation.sexualPriority : 0,
            .mood: recommendation.moodSuggested ? recommendation.moodPriority : 0,
            .body: recommendation.bodySuggested ? recommendation.bodyPriority : 0
        ]
        guard priorities.values.contains(where: { $0 > 0 }) else {
            return baseOrder
        }
        return baseOrder.sorted { lhs, rhs in
            let leftPriority = priorities[lhs] ?? 0
            let rightPriority = priorities[rhs] ?? 0
            if leftPriority != rightPriority {
                return leftPriority > rightPriority
            }
            return (baseOrder.firstIndex(of: lhs) ?? 0) < (baseOrder.firstIndex(of: rhs) ?? 0)
        }
    }

    private func rowView(for kind: SymptomRowKind) -> UIView? {
        switch kind {
        case .flow:
            return flowRow
        case .pain:
            return painRow
        case .sexual:
            return sexualRow
        case .mood:
            return moodRowView
        case .body:
            return bodySymptomsRowView
        }
    }

    private func applySymptomRowOrdering(isInPeriod: Bool, recommendation: SymptomSmartRecommendation, animated: Bool) {
        guard let periodStartRow,
              let periodStartSeparator,
              let flowSeparator,
              let painSeparator,
              let sexualSeparator,
              let moodSeparator else {
            return
        }

        view.layoutIfNeeded()

        let trailingKinds = orderedTrailingSymptomKinds(for: recommendation)
        let visibleKinds: [SymptomRowKind] = isInPeriod ? [.flow, .pain] + trailingKinds : trailingKinds
        let allKinds: [SymptomRowKind] = [.flow, .pain, .sexual, .mood, .body]

        allKinds.forEach { kind in
            rowView(for: kind)?.isHidden = !visibleKinds.contains(kind)
        }

        let movingRows = visibleKinds.compactMap { rowView(for: $0) }
        let dynamicSeparators = [flowSeparator, painSeparator, sexualSeparator, moodSeparator]

        periodStartSeparator.isHidden = movingRows.isEmpty
        periodStartSeparator.snp.remakeConstraints { make in
            make.top.equalTo(periodStartRow.snp.bottom)
            make.leading.equalToSuperview().offset(56)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        var previousAnchor = periodStartSeparator.snp.bottom
        for (index, row) in movingRows.enumerated() {
            symptomContainerView.bringSubviewToFront(row)
            row.snp.remakeConstraints { make in
                make.top.equalTo(previousAnchor)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(56)
                if index == movingRows.count - 1 {
                    make.bottom.equalToSuperview().offset(-16)
                }
            }

            if index < movingRows.count - 1 {
                let separator = dynamicSeparators[index]
                separator.isHidden = false
                symptomContainerView.bringSubviewToFront(separator)
                separator.snp.remakeConstraints { make in
                    make.top.equalTo(row.snp.bottom)
                    make.leading.equalToSuperview().offset(56)
                    make.trailing.equalToSuperview()
                    make.height.equalTo(1)
                }
                previousAnchor = separator.snp.bottom
            }
        }

        if movingRows.count <= 1 {
            dynamicSeparators.forEach { $0.isHidden = true }
        } else {
            for separator in dynamicSeparators.dropFirst(max(0, movingRows.count - 1)) {
                separator.isHidden = true
            }
        }

        let applyLayout = {
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.34, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
                applyLayout()
                movingRows.forEach { row in
                    row.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
                }
            } completion: { _ in
                UIView.animate(withDuration: 0.18, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                    movingRows.forEach { $0.transform = .identity }
                }
            }
        } else {
            applyLayout()
        }
    }

    private func recentSymptomHistoryProfile(before date: Date, lookbackDays: Int = 6) -> RecentSymptomHistoryProfile {
        let calendar = Calendar.current
        var loggedDays = 0
        var sexualRecordCount = 0
        var moodRecordCount = 0
        var bodyRecordCount = 0
        var sensitiveMoodCount = 0
        var energeticMoodCount = 0

        for offset in 1...lookbackDays {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: date),
                  dataManager.hasRecordData(for: targetDate) else {
                continue
            }

            let data = dataManager.getDailyData(for: targetDate)
            loggedDays += 1

            if data.sexualActivity > 0 {
                sexualRecordCount += 1
            }
            if data.mood > 0 {
                moodRecordCount += 1
            }
            if !data.bodySymptoms.isEmpty {
                bodyRecordCount += 1
            }
            if [5, 6, 7, 8].contains(data.mood) {
                sensitiveMoodCount += 1
            }
            if [2, 3, 4].contains(data.mood) {
                energeticMoodCount += 1
            }
        }

        return RecentSymptomHistoryProfile(
            loggedDays: loggedDays,
            sexualRecordCount: sexualRecordCount,
            moodRecordCount: moodRecordCount,
            bodyRecordCount: bodyRecordCount,
            sensitiveMoodCount: sensitiveMoodCount,
            energeticMoodCount: energeticMoodCount
        )
    }

    private func recentTraceItems(before date: Date, lookbackDays: Int = 6) -> [RecommendationTraceItem] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        var items: [RecommendationTraceItem] = []

        for offset in 1...lookbackDays {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: date),
                  dataManager.hasRecordData(for: targetDate) else {
                continue
            }

            let data = dataManager.getDailyData(for: targetDate)
            let prefix = formatter.string(from: targetDate).uppercased()

            if data.mood > 0 {
                let presentation = moodPresentation(for: data.mood)
                items.append(RecommendationTraceItem(text: "\(prefix) · \("female_cycle_mood".localized()): \(presentation.text)", targetRowKind: .mood, accentColor: presentation.textColor))
            }
            if data.sexualActivity > 0 {
                items.append(RecommendationTraceItem(text: "\(prefix) · \("female_cycle_sexual_activity".localized()): \(sexualActivityTraceText(for: data.sexualActivity))", targetRowKind: .sexual, accentColor: UIColor(hex: 0xE27B9E)))
            }
            if !data.bodySymptoms.isEmpty {
                items.append(RecommendationTraceItem(text: "\(prefix) · \("female_cycle_body_symptoms".localized()): \(bodySymptomTraceText(from: data.bodySymptoms))", targetRowKind: .body, accentColor: UIColor(hex: 0xF08D56)))
            }
            if items.count >= 4 {
                break
            }
        }

        return Array(items.prefix(3))
    }

    private func sexualActivityTraceText(for activity: Int) -> String {
        switch activity {
        case 1:
            return "female_cycle_protected_sex".localized()
        case 2:
            return "female_cycle_unprotected_sex".localized()
        default:
            return "female_cycle_none".localized()
        }
    }

    private func bodySymptomTraceText(from symptoms: [String]) -> String {
        guard let first = symptoms.first else {
            return "female_cycle_none".localized()
        }
        let normalized = first.replacingOccurrences(of: "-", with: " · ")
        if symptoms.count > 1 {
            return "\(normalized) +\(symptoms.count - 1)"
        }
        return normalized
    }

    private func recommendationPresentation(for date: Date, selectedDateString: String, isInPeriod: Bool) -> SymptomSmartRecommendation {
        if ovulationDates.contains(selectedDateString) || selectedDateString == ovulationDay {
            let phaseTitle = currentPhasePresentation(for: date).title
            let history = recentSymptomHistoryProfile(before: date)

            var sexualSuggested = history.sexualRecordCount > 0 || (history.loggedDays >= 2 && history.sensitiveMoodCount == 0)
            var moodSuggested = history.moodRecordCount > 0 || history.sensitiveMoodCount > 0 || history.loggedDays == 0
            var bodySuggested = history.bodyRecordCount > 0 || history.sensitiveMoodCount >= 2 || (history.moodRecordCount > 0 && history.energeticMoodCount == 0)

            if !sexualSuggested && !moodSuggested && !bodySuggested {
                moodSuggested = true
                bodySuggested = true
            }

            var focusItems: [String] = []
            if moodSuggested {
                focusItems.append("\("female_cycle_mood".localized()) \(history.moodRecordCount)")
            }
            if sexualSuggested {
                focusItems.append("\("female_cycle_sexual_activity".localized()) \(history.sexualRecordCount)")
            }
            if bodySuggested {
                focusItems.append("\("female_cycle_body_symptoms".localized()) \(history.bodyRecordCount)")
            }
            let summary = focusItems.isEmpty ? phaseTitle : "\(phaseTitle) • \(focusItems.joined(separator: " / "))"

            return SymptomSmartRecommendation(
                flowLevel: 0,
                painLevel: 0,
                sexualSuggested: sexualSuggested,
                moodSuggested: moodSuggested,
                bodySuggested: bodySuggested,
                sexualPriority: sexualSuggested ? max(1, history.sexualRecordCount * 2 + (history.loggedDays >= 2 ? 1 : 0)) : 0,
                moodPriority: moodSuggested ? max(1, history.moodRecordCount * 2 + history.sensitiveMoodCount * 2 + (history.loggedDays == 0 ? 1 : 0)) : 0,
                bodyPriority: bodySuggested ? max(1, history.bodyRecordCount * 2 + history.sensitiveMoodCount * 2 + (history.moodRecordCount > 0 && history.energeticMoodCount == 0 ? 1 : 0)) : 0,
                insightText: summary,
                explanationTitle: "\(phaseTitle) · AI Focus",
                explanationDetail: focusItems.isEmpty ? phaseTitle : focusItems.prefix(2).enumerated().map { index, text in
                    "TOP \(index + 1) \(text)"
                }.joined(separator: "  ·  "),
                confidenceScore: min(0.96, max(0.34, CGFloat(max(
                    sexualSuggested ? max(1, history.sexualRecordCount * 2 + (history.loggedDays >= 2 ? 1 : 0)) : 0,
                    max(
                        moodSuggested ? max(1, history.moodRecordCount * 2 + history.sensitiveMoodCount * 2 + (history.loggedDays == 0 ? 1 : 0)) : 0,
                        bodySuggested ? max(1, history.bodyRecordCount * 2 + history.sensitiveMoodCount * 2 + (history.moodRecordCount > 0 && history.energeticMoodCount == 0 ? 1 : 0)) : 0
                    )
                )) / 10.0)),
                confidenceText: focusItems.count >= 2 ? "Strong Suggestion" : "Light Suggestion",
                sourceChipText: "LAST 6D",
                driverChipText: focusItems.first?.components(separatedBy: " ").first?.uppercased(),
                traceTitle: "Recent Contributions",
                traceItems: recentTraceItems(before: date)
            )
        }

        guard isInPeriod else {
            let phaseTitle = currentPhasePresentation(for: date).title
            let history = recentSymptomHistoryProfile(before: date)
            let focusTitle: String
            if history.bodyRecordCount > 0 {
                focusTitle = "female_cycle_body_symptoms".localized()
            } else if history.moodRecordCount > 0 {
                focusTitle = "female_cycle_mood".localized()
            } else if history.sexualRecordCount > 0 {
                focusTitle = "female_cycle_sexual_activity".localized()
            } else {
                focusTitle = "female_cycle_body_symptoms".localized()
            }
            let summary = "\(phaseTitle) • \(focusTitle)"
            let focusCount = max(history.bodyRecordCount, history.moodRecordCount, history.sexualRecordCount)
            let confidence = focusCount > 0 ? min(0.72, max(0.22, CGFloat(focusCount) / 6.0)) : 0.18
            return SymptomSmartRecommendation(flowLevel: 0, painLevel: 0, sexualSuggested: false, moodSuggested: false, bodySuggested: false, sexualPriority: 0, moodPriority: 0, bodyPriority: 0, insightText: summary, explanationTitle: "\(phaseTitle) · Recent Focus", explanationDetail: focusCount > 0 ? "\(focusTitle) \(focusCount)/6" : nil, confidenceScore: confidence, confidenceText: focusCount >= 3 ? "Medium Signal" : "Light Signal", sourceChipText: "LAST 6D", driverChipText: focusCount > 0 ? focusTitle.uppercased() : "LIGHT", traceTitle: focusCount > 0 ? "Recent Contributions" : nil, traceItems: recentTraceItems(before: date))
        }

        let calendar = Calendar.current
        let dayIndex = max(1, min(periodDays, (calendar.dateComponents([.day], from: lastPeriodDate, to: date).day ?? 0) + 1))
        let phasePresentation = currentPhasePresentation(for: date)
        let phaseTitle = phasePresentation.title
        let phaseTintColor = phasePresentation.tintColor

        switch dayIndex {
        case 1...2:
            return SymptomSmartRecommendation(flowLevel: 3, painLevel: 2, sexualSuggested: false, moodSuggested: false, bodySuggested: false, sexualPriority: 0, moodPriority: 0, bodyPriority: 0, insightText: "\(phaseTitle) • \(dayIndex)/\(periodDays) • 3/3", explanationTitle: "\(phaseTitle) · Day \(dayIndex)", explanationDetail: "TOP 1 \("female_cycle_flow".localized()) 3/3  ·  TOP 2 \("female_cycle_pain".localized()) 2/3", confidenceScore: 0.92, confidenceText: "Strong Suggestion", sourceChipText: "RULE MODEL", driverChipText: "FLOW FIRST", traceTitle: "Rule Breakdown", traceItems: [RecommendationTraceItem(text: "Day \(dayIndex) / \(periodDays)", targetRowKind: nil, accentColor: phaseTintColor), RecommendationTraceItem(text: "\("female_cycle_flow".localized()) model 3/3", targetRowKind: .flow, accentColor: UIColor(hex: 0xFF69B4)), RecommendationTraceItem(text: "\("female_cycle_pain".localized()) model 2/3", targetRowKind: .pain, accentColor: UIColor(hex: 0xA16AF7))])
        case 3...4:
            return SymptomSmartRecommendation(flowLevel: 2, painLevel: 1, sexualSuggested: false, moodSuggested: false, bodySuggested: false, sexualPriority: 0, moodPriority: 0, bodyPriority: 0, insightText: "\(phaseTitle) • \(dayIndex)/\(periodDays) • 2/3", explanationTitle: "\(phaseTitle) · Day \(dayIndex)", explanationDetail: "TOP 1 \("female_cycle_flow".localized()) 2/3  ·  TOP 2 \("female_cycle_pain".localized()) 1/3", confidenceScore: 0.74, confidenceText: "Medium Signal", sourceChipText: "RULE MODEL", driverChipText: "FLOW LEAD", traceTitle: "Rule Breakdown", traceItems: [RecommendationTraceItem(text: "Day \(dayIndex) / \(periodDays)", targetRowKind: nil, accentColor: phaseTintColor), RecommendationTraceItem(text: "\("female_cycle_flow".localized()) model 2/3", targetRowKind: .flow, accentColor: UIColor(hex: 0xFF69B4)), RecommendationTraceItem(text: "\("female_cycle_pain".localized()) model 1/3", targetRowKind: .pain, accentColor: UIColor(hex: 0xA16AF7))])
        default:
            return SymptomSmartRecommendation(flowLevel: 1, painLevel: 1, sexualSuggested: false, moodSuggested: false, bodySuggested: false, sexualPriority: 0, moodPriority: 0, bodyPriority: 0, insightText: "\(phaseTitle) • \(dayIndex)/\(periodDays) • 1/3", explanationTitle: "\(phaseTitle) · Day \(dayIndex)", explanationDetail: "TOP 1 \("female_cycle_flow".localized()) 1/3  ·  TOP 2 \("female_cycle_pain".localized()) 1/3", confidenceScore: 0.52, confidenceText: "Light Suggestion", sourceChipText: "RULE MODEL", driverChipText: "LIGHT DAY", traceTitle: "Rule Breakdown", traceItems: [RecommendationTraceItem(text: "Day \(dayIndex) / \(periodDays)", targetRowKind: nil, accentColor: phaseTintColor), RecommendationTraceItem(text: "\("female_cycle_flow".localized()) model 1/3", targetRowKind: .flow, accentColor: UIColor(hex: 0xFF69B4)), RecommendationTraceItem(text: "\("female_cycle_pain".localized()) model 1/3", targetRowKind: .pain, accentColor: UIColor(hex: 0xA16AF7))])
        }
    }

    private func animateRecommendationIfNeeded(for recommendation: SymptomSmartRecommendation, selectedDateString: String) {
        let key = "\(selectedDateString)-\(recommendation.flowLevel)-\(recommendation.painLevel)-\(recommendation.sexualSuggested)-\(recommendation.moodSuggested)-\(recommendation.bodySuggested)-\(recommendation.sexualPriority)-\(recommendation.moodPriority)-\(recommendation.bodyPriority)-\(flowLevel)-\(painLevel)-\(sexualActivity)-\(mood)-\(bodySymptomsCount)"
        guard lastAnimatedRecommendationKey != key else {
            return
        }
        lastAnimatedRecommendationKey = key

        let shouldAnimateFlow = flowLevel == 0 && recommendation.flowLevel > 0
        let shouldAnimatePain = painLevel == 0 && recommendation.painLevel > 0
        let shouldAnimateSexual = sexualActivity == 0 && recommendation.sexualSuggested
        let shouldAnimateMood = mood == 0 && recommendation.moodSuggested
        let shouldAnimateBody = bodySymptomsCount == 0 && recommendation.bodySuggested

        if shouldAnimateFlow {
            animateRowHighlight(flowRow, accentColor: UIColor(hex: 0xFF69B4))
            animateRecommendationPulse(in: flowOptionsView, level: recommendation.flowLevel, accentColor: UIColor(hex: 0xFF69B4))
            updateRecommendationLabel(flowRecommendationLabel, level: recommendation.flowLevel, accentColor: UIColor(hex: 0xFF69B4), animated: true)
        }
        if shouldAnimatePain {
            animateRowHighlight(painRow, accentColor: UIColor(hex: 0xA16AF7))
            animateRecommendationPulse(in: painOptionsView, level: recommendation.painLevel, accentColor: UIColor(hex: 0xA16AF7))
            updateRecommendationLabel(painRecommendationLabel, level: recommendation.painLevel, accentColor: UIColor(hex: 0xA16AF7), animated: true)
        }
        if shouldAnimateSexual {
            animateRowHighlight(sexualRow, accentColor: UIColor(hex: 0xE27B9E))
            animateCapsuleRecommendation(on: sexualRecommendationLabel, accentColor: UIColor(hex: 0xE27B9E))
            updateBooleanRecommendationLabel(sexualRecommendationLabel, isSuggested: true, text: "AI", accentColor: UIColor(hex: 0xE27B9E), animated: true)
        }
        if shouldAnimateMood {
            animateRowHighlight(moodRowView, accentColor: UIColor(hex: 0x8A63E8))
            animateCapsuleRecommendation(on: moodRecommendationLabel, accentColor: UIColor(hex: 0x8A63E8))
            updateBooleanRecommendationLabel(moodRecommendationLabel, isSuggested: true, text: "AI", accentColor: UIColor(hex: 0x8A63E8), animated: true)
        }
        if shouldAnimateBody {
            animateRowHighlight(bodySymptomsRowView, accentColor: UIColor(hex: 0xF08D56))
            animateCapsuleRecommendation(on: bodyRecommendationLabel, accentColor: UIColor(hex: 0xF08D56))
            updateBooleanRecommendationLabel(bodyRecommendationLabel, isSuggested: true, text: "GO", accentColor: UIColor(hex: 0xF08D56), animated: true)
        }
        updateSymptomInsight(recommendation: recommendation, animated: shouldAnimateFlow || shouldAnimatePain || shouldAnimateSexual || shouldAnimateMood || shouldAnimateBody)
    }

    private func animateRecommendationPulse(in container: UIView?, level: Int, accentColor: UIColor) {
        guard level > 0,
              let container,
              let button = container.subviews.compactMap({ $0 as? UIButton }).first(where: { $0.tag == level }) else {
            return
        }
        animateMetricRipple(from: button, in: container, accentColor: accentColor)
        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.62, initialSpringVelocity: 0.18, options: [.allowUserInteraction, .curveEaseOut]) {
            button.transform = CGAffineTransform(scaleX: 1.16, y: 1.16)
        } completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.84, initialSpringVelocity: 0.14, options: [.allowUserInteraction, .curveEaseOut]) {
                button.transform = CGAffineTransform(scaleX: 1.10, y: 1.10)
            }
        }
    }

    private func animateCapsuleRecommendation(on label: CalendarInsetLabel, accentColor: UIColor) {
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.70, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
            label.alpha = 1
            label.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        } completion: { _ in
            UIView.animate(withDuration: 0.20, delay: 0.02, options: [.allowUserInteraction, .curveEaseOut]) {
                label.transform = .identity
                label.backgroundColor = accentColor.withAlphaComponent(0.12)
            }
        }
    }

    private func updateBadgeLabel(_ label: UILabel?, text: String, textColor: UIColor, backgroundColor: UIColor, animated: Bool) {
        guard let label else { return }
        let updates = {
            label.text = text
            label.textColor = textColor
            label.backgroundColor = backgroundColor
            label.layer.borderWidth = 1
            label.layer.borderColor = textColor.withAlphaComponent(0.10).cgColor
        }
        if animated {
            UIView.transition(with: label, duration: 0.24, options: [.transitionCrossDissolve, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func animateMetricRipple(from sourceView: UIView, in containerView: UIView?, accentColor: UIColor) {
        guard let containerView else { return }
        containerView.layoutIfNeeded()
        let center = containerView.convert(CGPoint(x: sourceView.bounds.midX, y: sourceView.bounds.midY), from: sourceView)

        let rippleLayer = CAShapeLayer()
        rippleLayer.fillColor = accentColor.withAlphaComponent(0.12).cgColor
        rippleLayer.strokeColor = accentColor.withAlphaComponent(0.22).cgColor
        rippleLayer.lineWidth = 1.5
        let initialPath = UIBezierPath(ovalIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)).cgPath
        let finalPath = UIBezierPath(ovalIn: CGRect(x: center.x - 48, y: center.y - 48, width: 96, height: 96)).cgPath
        rippleLayer.path = finalPath
        containerView.layer.addSublayer(rippleLayer)

        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = initialPath
        pathAnimation.toValue = finalPath
        pathAnimation.duration = 0.42
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.42
        opacityAnimation.toValue = 0
        opacityAnimation.duration = 0.42
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [pathAnimation, opacityAnimation]
        group.duration = 0.42
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            rippleLayer.removeFromSuperlayer()
        }
        rippleLayer.add(group, forKey: "female.metric.ripple")
        CATransaction.commit()
    }

    private func animateRowHighlight(_ rowView: UIView?, accentColor: UIColor) {
        guard let rowView else { return }
        let overlayView = UIView(frame: rowView.bounds)
        overlayView.isUserInteractionEnabled = false
        overlayView.backgroundColor = accentColor.withAlphaComponent(0.10)
        overlayView.layer.cornerRadius = 16
        overlayView.alpha = 0
        rowView.insertSubview(overlayView, at: 0)
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            overlayView.alpha = 1
            rowView.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
        } completion: { _ in
            UIView.animate(withDuration: 0.26, delay: 0.02, options: [.curveEaseOut, .allowUserInteraction]) {
                overlayView.alpha = 0
                rowView.transform = .identity
            } completion: { _ in
                overlayView.removeFromSuperview()
            }
        }
    }

    private func animateMoodParticles(around anchorView: UIView?, color: UIColor) {
        guard let anchorView else { return }
        anchorView.layoutIfNeeded()
        let offsets = [
            CGPoint(x: -14, y: -10),
            CGPoint(x: 16, y: -8),
            CGPoint(x: -10, y: 12),
            CGPoint(x: 20, y: 10)
        ]
        for (index, offset) in offsets.enumerated() {
            let dotView = UIView(frame: CGRect(x: anchorView.bounds.midX - 3, y: anchorView.bounds.midY - 3, width: 6, height: 6))
            dotView.backgroundColor = color.withAlphaComponent(0.95 - CGFloat(index) * 0.12)
            dotView.layer.cornerRadius = 3
            dotView.alpha = 0
            anchorView.addSubview(dotView)
            UIView.animate(withDuration: 0.16, delay: Double(index) * 0.02, options: [.curveEaseOut, .allowUserInteraction]) {
                dotView.alpha = 1
                dotView.transform = CGAffineTransform(translationX: offset.x, y: offset.y).scaledBy(x: 1.2, y: 1.2)
            } completion: { _ in
                UIView.animate(withDuration: 0.24, delay: 0.02, options: [.curveEaseOut, .allowUserInteraction]) {
                    dotView.alpha = 0
                    dotView.transform = dotView.transform.scaledBy(x: 0.6, y: 0.6)
                } completion: { _ in
                    dotView.removeFromSuperview()
                }
            }
        }
    }

    private func moodPresentation(for mood: Int) -> (text: String, textColor: UIColor, backgroundColor: UIColor) {
        switch mood {
        case 1:
            return ("female_cycle_mood_calm".localized(), UIColor(hex: 0x5B72E6), UIColor(hex: 0xEEF2FF))
        case 2:
            return ("female_cycle_mood_happy".localized(), UIColor(hex: 0xE98F25), UIColor(hex: 0xFFF2DE))
        case 3:
            return ("female_cycle_mood_relaxed".localized(), UIColor(hex: 0x3FA27B), UIColor(hex: 0xE4F6EF))
        case 4:
            return ("female_cycle_mood_energetic".localized(), UIColor(hex: 0xF15A7E), UIColor(hex: 0xFFE9F0))
        case 5:
            return ("female_cycle_mood_sensitive".localized(), UIColor(hex: 0xC45AB7), UIColor(hex: 0xFBEAF7))
        case 6:
            return ("female_cycle_mood_anxious".localized(), UIColor(hex: 0x8A63E8), UIColor(hex: 0xF0EBFF))
        case 7:
            return ("female_cycle_mood_irritable".localized(), UIColor(hex: 0xE55E4F), UIColor(hex: 0xFFEAE6))
        case 8:
            return ("female_cycle_mood_sad".localized(), UIColor(hex: 0x6677B8), UIColor(hex: 0xEDF1FF))
        default:
            return ("female_cycle_none".localized(), UIColor(hex: 0x7A5BE6), UIColor(hex: 0xF3EEFF))
        }
    }

    private func animateMetricSelection(button: UIButton, rowView: UIView?, containerView: UIView?, accentColor: UIColor) {
        UISelectionFeedbackGenerator().selectionChanged()
        animateMetricRipple(from: button, in: containerView, accentColor: accentColor)
        animateRowHighlight(rowView, accentColor: accentColor)
    }

    // MARK: - Actions

    @objc private func previousMonthTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentDisplayMonth) {
            currentDisplayMonth = newMonth
            updateMonthYearLabel()
            generateCalendarDates()
        }
    }

    @objc private func nextMonthTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentDisplayMonth) {
            currentDisplayMonth = newMonth
            updateMonthYearLabel()
            generateCalendarDates()
        }
    }

    @objc private func periodStartSwitchChanged(_ sender: UISwitch) {
        guard let selectedDate = selectedDate else { return }

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = dateFormatter.string(from: selectedDate)

        if sender.isOn {
            // 开关打开：标记为经期开始日期
            isPeriodStarted = true

            // 判断选中日期与排卵期结束日期的关系
            if let ovulationLastDayString = ovulationLastDay,
               let ovulationLastDate = dateFormatter.date(from: ovulationLastDayString) {

                let comparisonResult = calendar.compare(selectedDate, to: ovulationLastDate, toGranularity: .day)

                if comparisonResult == .orderedDescending {
                    // 选中日期在排卵期结束日期之后 → 设为下一个周期的经期开始日期
                    XLogger.shared.log("选中日期在排卵期之后，设为下一个周期的经期开始日期: \(selectedDateString)")

                    // 计算下一个周期的经期开始日期应该是：当前周期的经期开始日期 + 周期长度
                    if let nextPeriodStart = calendar.date(byAdding: .day, value: cycleLength, to: lastPeriodDate) {
                        // 调整为选中的日期
                        let difference = calendar.dateComponents([.day], from: nextPeriodStart, to: selectedDate).day ?? 0

                        // 实际上应该将lastPeriodDate调整为：selectedDate - cycleLength
                        if let newLastPeriodDate = calendar.date(byAdding: .day, value: -cycleLength, to: selectedDate) {
                            lastPeriodDate = newLastPeriodDate
                            saveFemaleHealthData()
                        }
                    }
                } else {
                    // 选中日期在排卵期结束日期之前 → 将当前周期的经期开始日期调整到该日期
                    XLogger.shared.log("选中日期在排卵期之前，调整当前周期的经期开始日期为: \(selectedDateString)")
                    lastPeriodDate = selectedDate
                    saveFemaleHealthData()
                }
            } else {
                // 如果没有排卵期数据，默认调整当前周期的经期开始日期
                XLogger.shared.log("调整当前周期的经期开始日期为: \(selectedDateString)")
                lastPeriodDate = selectedDate
                saveFemaleHealthData()
            }

        } else {
            // 开关关闭：将经期开始日期推迟1天
            isPeriodStarted = false
            XLogger.shared.log("关闭经期开始，将日期推迟1天")

            if let newPeriodStart = calendar.date(byAdding: .day, value: 1, to: lastPeriodDate) {
                lastPeriodDate = newPeriodStart
                saveFemaleHealthData()
            }
        }

        // 重新计算周期并刷新界面
        calculateCycleDates()
        updateCycleInfo(animated: true)
        generateCalendarDates()
        loadSymptomData(for: selectedDate)
    }

    private func saveFemaleHealthData() {
        // 使用数据管理器保存周期配置
        dataManager.updateCycleConfiguration(
            periodDays: periodDays,
            cycleLength: cycleLength,
            lastPeriodDate: lastPeriodDate
        )
        XLogger.shared.log("保存经期开始日期: \(lastPeriodDate)")
    }

    @objc private func flowButtonTapped(_ sender: UIButton) {
        guard let selectedDate = selectedDate else { return }

        let level = sender.tag
        flowLevel = level
        XLogger.shared.log("选择流量等级: \(level)")

        // 保存到数据管理器
        dataManager.updateFlowLevel(for: selectedDate, level: level)

        animateMetricSelection(button: sender, rowView: flowRow, containerView: sender.superview, accentColor: UIColor(hex: 0xFF69B4))
        highlightRecommendationTrace(for: .flow, accentColor: UIColor(hex: 0xFF69B4))
        refreshMetricButtons(in: sender.superview, selectedLevel: flowLevel, recommendedLevel: 0, type: .flow, animated: true)
        refreshCurrentRecommendationState(animated: true)
    }

    @objc private func painButtonTapped(_ sender: UIButton) {
        guard let selectedDate = selectedDate else { return }

        let level = sender.tag
        painLevel = level
        XLogger.shared.log("选择痛经等级: \(level)")

        // 保存到数据管理器
        dataManager.updatePainLevel(for: selectedDate, level: level)

        animateMetricSelection(button: sender, rowView: painRow, containerView: sender.superview, accentColor: UIColor(hex: 0xA16AF7))
        highlightRecommendationTrace(for: .pain, accentColor: UIColor(hex: 0xA16AF7))
        refreshMetricButtons(in: sender.superview, selectedLevel: painLevel, recommendedLevel: 0, type: .pain, animated: true)
        refreshCurrentRecommendationState(animated: true)
    }

    @objc private func sexualActivityTapped() {
        guard let selectedDate = selectedDate else { return }

        XLogger.shared.log("点击性行为")
        highlightRecommendationTrace(for: .sexual, accentColor: UIColor(hex: 0xE27B9E))

        let alert = UIAlertController(title: "female_cycle_sexual_activity".localized(), message: nil, preferredStyle: .actionSheet)

        // 无
        let noneAction = UIAlertAction(title: "female_cycle_none".localized(), style: .default) { [weak self] _ in
            guard let self = self, let selectedDate = self.selectedDate else { return }
            self.sexualActivity = 0
            self.dataManager.updateSexualActivity(for: selectedDate, activity: 0)
            self.updateBadgeLabel(self.sexualValueLabel, text: "female_cycle_none".localized(), textColor: UIColor(hex: 0xC55780), backgroundColor: UIColor(hex: 0xFFF0F6), animated: true)
            self.animateRowHighlight(self.sexualRow, accentColor: UIColor(hex: 0xF08CB1))
                self.highlightRecommendationTrace(for: .sexual, accentColor: UIColor(hex: 0xE27B9E))
            self.refreshCurrentRecommendationState(animated: true)
            XLogger.shared.log("选择性行为: 无")
        }

        // 保护性行为
        let protectedAction = UIAlertAction(title: "female_cycle_protected_sex".localized(), style: .default) { [weak self] _ in
            guard let self = self, let selectedDate = self.selectedDate else { return }
            self.sexualActivity = 1
            self.dataManager.updateSexualActivity(for: selectedDate, activity: 1)
            self.updateBadgeLabel(self.sexualValueLabel, text: "female_cycle_protected_sex".localized(), textColor: UIColor(hex: 0xC55780), backgroundColor: UIColor(hex: 0xFFF0F6), animated: true)
            self.animateRowHighlight(self.sexualRow, accentColor: UIColor(hex: 0xF08CB1))
                self.highlightRecommendationTrace(for: .sexual, accentColor: UIColor(hex: 0xE27B9E))
            self.refreshCurrentRecommendationState(animated: true)
            XLogger.shared.log("选择性行为: 保护性行为")
        }

        // 无保护性行为
        let unprotectedAction = UIAlertAction(title: "female_cycle_unprotected_sex".localized(), style: .default) { [weak self] _ in
            guard let self = self, let selectedDate = self.selectedDate else { return }
            self.sexualActivity = 2
            self.dataManager.updateSexualActivity(for: selectedDate, activity: 2)
            self.updateBadgeLabel(self.sexualValueLabel, text: "female_cycle_unprotected_sex".localized(), textColor: UIColor(hex: 0xC55780), backgroundColor: UIColor(hex: 0xFFF0F6), animated: true)
            self.animateRowHighlight(self.sexualRow, accentColor: UIColor(hex: 0xF08CB1))
                self.highlightRecommendationTrace(for: .sexual, accentColor: UIColor(hex: 0xE27B9E))
            self.refreshCurrentRecommendationState(animated: true)
            XLogger.shared.log("选择性行为: 无保护性行为")
        }

        // 取消
        let cancelAction = UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil)

        alert.addAction(noneAction)
        alert.addAction(protectedAction)
        alert.addAction(unprotectedAction)
        alert.addAction(cancelAction)

        // 为 iPad 设置 popover
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func moodTapped() {
        XLogger.shared.log("点击心情")
        highlightRecommendationTrace(for: .mood, accentColor: UIColor(hex: 0x8A63E8))

        let alert = UIAlertController(title: "female_cycle_mood".localized(), message: nil, preferredStyle: .actionSheet)

        let moods = [
            (1, "female_cycle_mood_calm".localized()),
            (2, "female_cycle_mood_happy".localized()),
            (3, "female_cycle_mood_relaxed".localized()),
            (4, "female_cycle_mood_energetic".localized()),
            (5, "female_cycle_mood_sensitive".localized()),
            (6, "female_cycle_mood_anxious".localized()),
            (7, "female_cycle_mood_irritable".localized()),
            (8, "female_cycle_mood_sad".localized())
        ]

        for (index, moodName) in moods {
            let action = UIAlertAction(title: moodName, style: .default) { [weak self] _ in
                guard let self = self, let selectedDate = self.selectedDate else { return }
                self.mood = index
                self.dataManager.updateMood(for: selectedDate, mood: index)
                let presentation = self.moodPresentation(for: index)
                self.updateBadgeLabel(self.moodValueLabel, text: presentation.text, textColor: presentation.textColor, backgroundColor: presentation.backgroundColor, animated: true)
                self.animateRowHighlight(self.moodRowView, accentColor: presentation.textColor)
                self.highlightRecommendationTrace(for: .mood, accentColor: presentation.textColor)
                self.animateMoodParticles(around: self.moodValueLabel, color: presentation.textColor)
                self.refreshCurrentRecommendationState(animated: true)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                XLogger.shared.log("选择心情: \(moodName)")
            }
            alert.addAction(action)
        }

        // 取消
        let cancelAction = UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        // 为 iPad 设置 popover
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func bodySymptomsTapped() {
        guard let selectedDate = selectedDate else { return }

        XLogger.shared.log("点击身体症状")
        animateRowHighlight(bodySymptomsRowView, accentColor: UIColor(hex: 0xF08D56))
        highlightRecommendationTrace(for: .body, accentColor: UIColor(hex: 0xF08D56))
        animateCapsuleRecommendation(on: bodyRecommendationLabel, accentColor: UIColor(hex: 0xF08D56))
        let vc = BodySymptomsViewController()
        vc.selectedDate = selectedDate // 传递选中的日期
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handleMetricButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = sender.transform.scaledBy(x: 0.92, y: 0.92)
        }
    }

    @objc private func handleMetricButtonTouchRelease(_ sender: UIButton) {
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = .identity
        }
    }

    @objc private func rightBarButtonTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 所有数据
        let allDataAction = UIAlertAction(title: "female_cycle_all_data".localized(), style: .default) { [weak self] _ in
            XLogger.shared.log("点击所有数据")
            let vc = AllDataViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        // 周期设置
        let cycleSettingsAction = UIAlertAction(title: "female_cycle_settings".localized(), style: .default) { [weak self] _ in
            XLogger.shared.log("点击周期设置")
            let vc = FemaleHealthViewController()
            vc.hideLastPeriodDateOption = true // 隐藏最后一个选项
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        // 取消
        let cancelAction = UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil)

        alert.addAction(allDataAction)
        alert.addAction(cycleSettingsAction)
        alert.addAction(cancelAction)

        // 为 iPad 设置 popover
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDelegate & UICollectionViewDataSource

extension FemaleCycleCalendarViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as! CalendarDayCell

        if let date = calendarDates[indexPath.item] {
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)

            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isPeriod = periodDates.contains(dateString)
            let isOvulation = ovulationDates.contains(dateString)
            let isPredicted = predictedPeriodDates.contains(dateString)

            // 判断是否是特殊日期
            let isPeriodFirstDay = dateString == periodFirstDay
            let isPeriodLastDay = dateString == periodLastDay
            let isOvulationDay = dateString == ovulationDay
            let isOvulationFirstDay = dateString == ovulationFirstDay
            let isOvulationLastDay = dateString == ovulationLastDay
            let isPredictedFirstDay = dateString == predictedFirstDay

            // 判断是否是选中的日期
            let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)

            // 判断左右连接状态
            var hasLeftConnection = false
            var hasRightConnection = false

            // 检查是否在行首或行尾（根据实际的星期几）
            let weekday = calendar.component(.weekday, from: date)
            let isRowStart = weekday == 1  // 周日
            let isRowEnd = weekday == 7    // 周六

            // 获取前一天和后一天的日期（使用真实日期计算，而不是数组索引）
            var previousDateString: String?
            var nextDateString: String?

            // 计算前一天的日期
            if let prevDate = calendar.date(byAdding: .day, value: -1, to: date) {
                previousDateString = dateFormatter.string(from: prevDate)
            }

            // 计算后一天的日期
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: date) {
                nextDateString = dateFormatter.string(from: nextDate)
            }

            // 先检查逻辑连接（不考虑行首行尾）
            var hasLogicalLeftConnection = false
            var hasLogicalRightConnection = false

            // 检查经期连接
            if isPeriod || isPeriodFirstDay || isPeriodLastDay {
                // 检查前一天是否也在经期
                if let prevDateStr = previousDateString,
                   periodDates.contains(prevDateStr) {
                    hasLogicalLeftConnection = true
                }
                // 检查后一天是否也在经期
                if let nextDateStr = nextDateString,
                   periodDates.contains(nextDateStr) {
                    hasLogicalRightConnection = true
                }
            }
            // 检查排卵期连接
            else if isOvulation || isOvulationDay || isOvulationFirstDay || isOvulationLastDay {
                // 检查前一天是否也在排卵期
                if let prevDateStr = previousDateString,
                   (ovulationDates.contains(prevDateStr) || prevDateStr == ovulationDay || prevDateStr == ovulationFirstDay || prevDateStr == ovulationLastDay) {
                    hasLogicalLeftConnection = true
                }
                // 检查后一天是否也在排卵期
                if let nextDateStr = nextDateString,
                   (ovulationDates.contains(nextDateStr) || nextDateStr == ovulationDay || nextDateStr == ovulationFirstDay || nextDateStr == ovulationLastDay) {
                    hasLogicalRightConnection = true
                }
            }
            // 检查预测经期连接
            else if isPredicted || isPredictedFirstDay {
                // 检查前一天是否也在预测经期
                if let prevDateStr = previousDateString,
                   predictedPeriodDates.contains(prevDateStr) {
                    hasLogicalLeftConnection = true
                }
                // 检查后一天是否也在预测经期
                if let nextDateStr = nextDateString,
                   predictedPeriodDates.contains(nextDateStr) {
                    hasLogicalRightConnection = true
                }
            }

            // 根据行首行尾调整视觉连接
            // 行首：即使逻辑上有左连接，视觉上也要断开（显示左圆角）
            // 行尾：即使逻辑上有右连接，视觉上也要断开（显示右圆角）
            hasLeftConnection = hasLogicalLeftConnection && !isRowStart
            hasRightConnection = hasLogicalRightConnection && !isRowEnd

            // 检查该日期是否有记录数据
            let hasRecord = dataManager.hasRecordData(for: date)

            cell.configure(
                day: day,
                isToday: isToday,
                isPeriod: isPeriod,
                isOvulation: isOvulation,
                isPredicted: isPredicted,
                isSelected: isSelected,
                isPeriodFirstDay: isPeriodFirstDay,
                isPeriodLastDay: isPeriodLastDay,
                isOvulationDay: isOvulationDay,
                isOvulationFirstDay: isOvulationFirstDay,
                isOvulationLastDay: isOvulationLastDay,
                isPredictedFirstDay: isPredictedFirstDay,
                hasLeftConnection: hasLeftConnection,
                hasRightConnection: hasRightConnection,
                hasLogicalLeftConnection: hasLogicalLeftConnection,
                hasLogicalRightConnection: hasLogicalRightConnection,
                hasRecord: hasRecord
            )
        } else {
            cell.configure(day: nil, isToday: false, isPeriod: false, isOvulation: false, isPredicted: false, isSelected: false)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = calendarDates[indexPath.item] else { return }
        let sourceCell = collectionView.cellForItem(at: indexPath)

        selectedDate = date
        UISelectionFeedbackGenerator().selectionChanged()

        calendarCollectionView.reloadData()

        if let cell = sourceCell {
            UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                cell.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            } completion: { _ in
                UIView.animate(withDuration: 0.24, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
                    cell.transform = .identity
                }
            }
        }

        updateSymptomSectionVisibility()
        updateCycleInfo(animated: true)
        animateCalendarBridgeTransition(from: sourceCell, date: date)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: 50)
    }
}

private final class CalendarInsetLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

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

// MARK: - CalendarDayCell

class CalendarDayCell: UICollectionViewCell {

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let backgroundCircleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        return view
    }()

    // 连贯背景层
    private let continuousBackgroundView: UIView = {
        let view = UIView()
        return view
    }()

    // 数据记录小圆点
    private let recordDotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xFF69B4)
        view.layer.cornerRadius = 2.5
        view.isHidden = true
        return view
    }()

    // 保存配置参数，用于重新绘制
    private var currentBackgroundColor: UIColor?
    private var currentHasLeftConnection: Bool = false
    private var currentHasRightConnection: Bool = false
    private var currentHasLogicalLeftConnection: Bool = false
    private var currentHasLogicalRightConnection: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 在布局更新后重新绘制背景
        if let bgColor = currentBackgroundColor {
            redrawContinuousBackground(color: bgColor, hasLeftConnection: currentHasLeftConnection, hasRightConnection: currentHasRightConnection, hasLogicalLeftConnection: currentHasLogicalLeftConnection, hasLogicalRightConnection: currentHasLogicalRightConnection)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        transform = .identity
        backgroundCircleView.layer.shadowOpacity = 0
        backgroundCircleView.layer.shadowRadius = 0
        backgroundCircleView.layer.shadowOffset = .zero
    }

    private func setupUI() {
        // 先添加连贯背景层（在最底层）
        contentView.addSubview(continuousBackgroundView)
        continuousBackgroundView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        contentView.addSubview(backgroundCircleView)
        backgroundCircleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }

        contentView.addSubview(dayLabel)
        dayLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 添加数据记录小圆点（在最上层）
        contentView.addSubview(recordDotView)
        recordDotView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(3) // 往下偏移，距离底部更近
            make.width.height.equalTo(5)
        }
    }

    func configure(day: Int?, isToday: Bool, isPeriod: Bool, isOvulation: Bool, isPredicted: Bool, isSelected: Bool, isPeriodFirstDay: Bool = false, isPeriodLastDay: Bool = false, isOvulationDay: Bool = false, isOvulationFirstDay: Bool = false, isOvulationLastDay: Bool = false, isPredictedFirstDay: Bool = false, hasLeftConnection: Bool = false, hasRightConnection: Bool = false, hasLogicalLeftConnection: Bool = false, hasLogicalRightConnection: Bool = false, hasRecord: Bool = false) {
        guard let day = day else {
            dayLabel.text = ""
            backgroundCircleView.backgroundColor = .clear
            backgroundCircleView.layer.borderWidth = 0
            continuousBackgroundView.backgroundColor = .clear
            recordDotView.isHidden = true
            currentBackgroundColor = nil
            currentHasLeftConnection = false
            currentHasRightConnection = false
            currentHasLogicalLeftConnection = false
            currentHasLogicalRightConnection = false
            // 清空背景层
            continuousBackgroundView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            return
        }

        // 如果是今天，显示"今"；否则显示日期数字
        dayLabel.text = "\(day)"

        // 重置样式
        backgroundCircleView.backgroundColor = .clear
        backgroundCircleView.layer.borderWidth = 0
        backgroundCircleView.layer.borderColor = nil
        backgroundCircleView.layer.shadowOpacity = 0
        backgroundCircleView.layer.shadowRadius = 0
        backgroundCircleView.layer.shadowOffset = .zero
        continuousBackgroundView.backgroundColor = .clear
        dayLabel.textColor = UIColor(hex: 0x333333)
        transform = .identity

        // 移除旧的虚线层
        backgroundCircleView.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }

        // 清除旧的连续背景层
        continuousBackgroundView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 绘制连贯背景
        var continuousBackgroundColor: UIColor?

        if isPeriod || isPeriodFirstDay || isPeriodLastDay {
            continuousBackgroundColor = UIColor(hex: 0xFFE6F2)
        } else if isOvulation || isOvulationDay || isOvulationFirstDay || isOvulationLastDay {
            continuousBackgroundColor = UIColor(hex: 0xE6E6FA)
        } else if isPredicted || isPredictedFirstDay {
            continuousBackgroundColor = UIColor(hex: 0xFFE6F2)
        }

        // 保存配置参数并绘制背景
        currentBackgroundColor = continuousBackgroundColor
        currentHasLeftConnection = hasLeftConnection
        currentHasRightConnection = hasRightConnection
        currentHasLogicalLeftConnection = hasLogicalLeftConnection
        currentHasLogicalRightConnection = hasLogicalRightConnection

        if let bgColor = continuousBackgroundColor {
            redrawContinuousBackground(color: bgColor, hasLeftConnection: hasLeftConnection, hasRightConnection: hasRightConnection, hasLogicalLeftConnection: hasLogicalLeftConnection, hasLogicalRightConnection: hasLogicalRightConnection)
        }

        // 设置圆点标记
        if isPeriodFirstDay || isPeriodLastDay {
            backgroundCircleView.backgroundColor = UIColor(hex: 0xFFB3D9)
            dayLabel.textColor = .white
        } else if isOvulationFirstDay || isOvulationLastDay {
            backgroundCircleView.backgroundColor = UIColor(hex: 0x7B68EE)
            dayLabel.textColor = .white
        } else if isPredictedFirstDay {
            backgroundCircleView.backgroundColor = .clear

            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = UIColor(hex: 0xFFB3D9).cgColor
            shapeLayer.lineWidth = 2
            shapeLayer.lineDashPattern = [4, 4]
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40)).cgPath

            backgroundCircleView.layer.addSublayer(shapeLayer)
        } else if isToday {
            backgroundCircleView.backgroundColor = UIColor(hex: 0xFFF0F6)
            backgroundCircleView.layer.borderWidth = 1
            backgroundCircleView.layer.borderColor = UIColor(hex: 0xF4BCD3).cgColor
            dayLabel.textColor = UIColor(hex: 0xC74674)
        }

        if isSelected {
            backgroundCircleView.layer.borderWidth = 2
            backgroundCircleView.layer.borderColor = UIColor(hex: 0xC74674).cgColor
            backgroundCircleView.layer.shadowColor = UIColor(hex: 0xE98AB0).cgColor
            backgroundCircleView.layer.shadowOpacity = 0.26
            backgroundCircleView.layer.shadowRadius = 12
            backgroundCircleView.layer.shadowOffset = CGSize(width: 0, height: 6)
            transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }

        recordDotView.isHidden = !hasRecord
    }

    private func redrawContinuousBackground(color: UIColor, hasLeftConnection: Bool, hasRightConnection: Bool, hasLogicalLeftConnection: Bool, hasLogicalRightConnection: Bool) {
        // 移除旧的背景层
        continuousBackgroundView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 使用实际的布局宽度，如果还没有布局则使用0（会在layoutSubviews中重新绘制）
        let width = contentView.bounds.width
        guard width > 0 else { return }

        let height: CGFloat = 40

        // 创建路径
        let path = UIBezierPath()

        if !hasLeftConnection && !hasRightConnection {
            // 没有视觉连接时，绘制完整圆形背景
            path.addArc(withCenter: CGPoint(x: width / 2, y: height / 2), radius: height / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        } else if !hasLeftConnection && hasRightConnection {
            // 左边圆角，右边直角（第一天或换行后新行的第一个日期）
            path.move(to: CGPoint(x: width / 2, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: width / 2, y: height))
            path.addArc(withCenter: CGPoint(x: width / 2, y: height / 2), radius: height / 2, startAngle: .pi / 2, endAngle: .pi * 3 / 2, clockwise: true)
            path.close()
        } else if hasLeftConnection && !hasRightConnection {
            // 左边直角，右边圆角（最后一天或行尾）
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width / 2, y: 0))
            path.addArc(withCenter: CGPoint(x: width / 2, y: height / 2), radius: height / 2, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: height))
            path.close()
        } else {
            // 左右都是直角（中间天）
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.close()
        }

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = color.cgColor
        continuousBackgroundView.layer.addSublayer(shapeLayer)
    }
}
