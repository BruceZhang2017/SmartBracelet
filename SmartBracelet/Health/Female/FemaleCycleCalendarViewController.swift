//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  FemaleCycleCalendarViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2025/12/09.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit
import WatchProtocolSDK

class FemaleCycleCalendarViewController: BaseViewController {

    // MARK: - Properties

    // 数据管理器
    private let dataManager = FemaleCycleDataManager.shared

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

    private let periodStartSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor(hex: 0xFF69B4)
        return switchControl
    }()

    private var calendarDates: [Date?] = []

    // 当前选中的日期
    private var selectedDate: Date?

    // 症状记录数据
    private var isPeriodStarted: Bool = false
    private var flowLevel: Int = 0 // 0=未选择, 1=少, 2=中, 3=多
    private var painLevel: Int = 0 // 0=未选择, 1=轻微, 2=中等, 3=严重
    private var sexualActivity: Int = 0 // 0=无, 1=保护性行为, 2=无保护性行为
    private var mood: Int = 0 // 0=未选择, 1=平静, 2=开心, 3=放松, 4=活力满满, 5=敏感, 6=焦躁, 7=易怒, 8=悲伤

    // 流量和痛经视图引用（用于显示/隐藏）
    private var flowRow: UIView?
    private var flowSeparator: UIView?
    private var painRow: UIView?
    private var painSeparator: UIView?
    private var periodStartSeparator: UIView? // 经期开始开关的分隔线
    private var sexualRow: UIView? // 性行为行

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

        // 注册数据变更通知
        setupNotificationObservers()
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
        updateCycleInfo()
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
        navigationItem.rightBarButtonItem = rightButton
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xF5F5F5)

        // 创建滚动视图
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = UIColor(hex: 0xF5F5F5)
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // Month/Year selector
        contentView.addSubview(monthYearContainerView)
        monthYearContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
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
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        setupWeekdayHeaders()

        // Calendar collection view
        contentView.addSubview(calendarCollectionView)
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }

        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
        calendarCollectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "CalendarDayCell")

        // Legend
        contentView.addSubview(legendContainerView)
        legendContainerView.snp.makeConstraints { make in
            make.top.equalTo(calendarCollectionView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
        }

        setupLegend()

        // Cycle info
        contentView.addSubview(cycleInfoContainerView)
        cycleInfoContainerView.snp.makeConstraints { make in
            make.top.equalTo(legendContainerView.snp.bottom).offset(16)
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
        symptomTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }

        // 经期开始了吗
        let periodStartRow = createSymptomRow(
            icon: "💧",
            title: "female_cycle_period_started".localized(),
            hasSwitch: true
        )
        symptomContainerView.addSubview(periodStartRow)
        periodStartRow.snp.makeConstraints { make in
            make.top.equalTo(symptomTitleLabel.snp.bottom).offset(16)
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
        sexualLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        sexualLabel.textColor = UIColor(hex: 0x999999)
        sexualLabel.text = "female_cycle_none".localized()
        sexualLabel.textAlignment = .right
        self.sexualValueLabel = sexualLabel
        sexualRowView.addSubview(sexualLabel)
        sexualLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
        }

        let sexualTap = UITapGestureRecognizer(target: self, action: #selector(sexualActivityTapped))
        sexualRowView.addGestureRecognizer(sexualTap)

        // 分隔线
        let separator4 = createSeparator()
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
        symptomContainerView.addSubview(moodRow)
        moodRow.snp.makeConstraints { make in
            make.top.equalTo(separator4.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        // 添加心情值显示标签
        let moodLabel = UILabel()
        moodLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        moodLabel.textColor = UIColor(hex: 0x999999)
        moodLabel.text = "female_cycle_none".localized()
        moodLabel.textAlignment = .right
        self.moodValueLabel = moodLabel
        moodRow.addSubview(moodLabel)
        moodLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
        }

        let moodTap = UITapGestureRecognizer(target: self, action: #selector(moodTapped))
        moodRow.addGestureRecognizer(moodTap)

        // 分隔线
        let separator5 = createSeparator()
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
        symptomContainerView.addSubview(bodyRow)
        bodyRow.snp.makeConstraints { make in
            make.top.equalTo(separator5.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-16)
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

        // 创建水滴形状的图片 - 累计选中（当前等级<=flowLevel时高亮）
        let image = createDropletImage(
            color: level <= flowLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
        )
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(flowButtonTapped(_:)), for: .touchUpInside)

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

        // 创建闪电形状的图片 - 累计选中（当前等级<=painLevel时高亮）
        let image = createLightningImage(
            color: level <= painLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
        )
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(painButtonTapped(_:)), for: .touchUpInside)

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
        monthYearLabel.text = dateFormatter.string(from: currentDisplayMonth)
    }

    private func updateCycleInfo() {
        // 计算当前周期天数和阶段
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: lastPeriodDate, to: today).day ?? 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)

        // 判断今天处于什么阶段
        var phaseTitle = ""
        var phaseTotalDays = 0
        var phaseDescription = ""

        if periodDates.contains(todayString) {
            // 经期
            phaseTitle = "female_cycle_period".localized()
            phaseTotalDays = periodDays
            phaseDescription = "female_cycle_period_desc".localized()
        } else if ovulationDates.contains(todayString) || todayString == ovulationDay {
            // 排卵期
            phaseTitle = "female_cycle_ovulation".localized()
            phaseTotalDays = 10 // 排卵期固定10天（排卵日前5天到后4天）
            phaseDescription = "female_cycle_ovulation_desc".localized()
        } else {
            // 安全期
            phaseTitle = "female_cycle_safe_period".localized()
            phaseTotalDays = cycleLength - periodDays - 10 // 周期总天数 - 经期天数 - 排卵期天数
            phaseDescription = "female_cycle_description".localized()
        }

        // 更新左侧显示
        // 更新标题
        if let periodTitleLabel = periodDayInfoView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            periodTitleLabel.text = phaseTitle
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

        // 更新周期长度显示
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

        // 更新描述文字
        cycleDescriptionLabel.text = phaseDescription
    }

    private func updateSymptomSectionVisibility() {
        guard let selectedDate = selectedDate else {
            // 如果没有选中日期，隐藏症状记录区域
            symptomContainerView.isHidden = true
            futureRecordTipLabel.isHidden = false
            return
        }

        let calendar = Calendar.current
        let isFutureDate = calendar.compare(selectedDate, to: today, toGranularity: .day) == .orderedDescending

        if isFutureDate {
            // 未来日期：隐藏症状记录区域，显示提示
            symptomContainerView.isHidden = true
            futureRecordTipLabel.isHidden = false
        } else {
            // 今天或过去的日期：显示症状记录区域，隐藏提示
            symptomContainerView.isHidden = false
            futureRecordTipLabel.isHidden = true

            // TODO: 加载选中日期的症状记录数据
            loadSymptomData(for: selectedDate)
        }
    }

    private func loadSymptomData(for date: Date) {
        // 从数据管理器加载指定日期的症状记录
        let data = dataManager.getDailyData(for: date)

        flowLevel = data.flowLevel
        painLevel = data.painLevel
        sexualActivity = data.sexualActivity
        mood = data.mood

        // 判断选中日期是否为经期开始日期
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = dateFormatter.string(from: date)

        // 检查是否为当前周期的经期开始日期
        isPeriodStarted = (selectedDateString == periodFirstDay)

        // 更新UI
        periodStartSwitch.isOn = isPeriodStarted

        // 检查选中日期是否在经期内
        let isInPeriod = periodDates.contains(selectedDateString)

        // 显示/隐藏流量和痛经
        flowRow?.isHidden = !isInPeriod
        flowSeparator?.isHidden = !isInPeriod
        painRow?.isHidden = !isInPeriod
        painSeparator?.isHidden = !isInPeriod

        // 根据流量和痛经的显示状态调整性行为的约束
        if let sexualRowView = sexualRow {
            sexualRowView.snp.remakeConstraints { make in
                if isInPeriod {
                    // 在经期：性行为在痛经分隔线下方
                    make.top.equalTo(painSeparator!.snp.bottom)
                } else {
                    // 非经期：性行为在经期开始分隔线下方
                    make.top.equalTo(periodStartSeparator!.snp.bottom)
                }
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(56)
            }
        }

        // 刷新流量和痛经按钮的显示
        refreshFlowButtons()
        refreshPainButtons()

        // 刷新性行为标签显示
        if let sexualLabel = sexualValueLabel {
            switch sexualActivity {
            case 1:
                sexualLabel.text = "female_cycle_protected_sex".localized()
            case 2:
                sexualLabel.text = "female_cycle_unprotected_sex".localized()
            default:
                sexualLabel.text = "female_cycle_none".localized()
            }
        }

        // 刷新心情标签显示
        if let moodLabel = moodValueLabel {
            switch mood {
            case 1:
                moodLabel.text = "female_cycle_mood_calm".localized()
            case 2:
                moodLabel.text = "female_cycle_mood_happy".localized()
            case 3:
                moodLabel.text = "female_cycle_mood_relaxed".localized()
            case 4:
                moodLabel.text = "female_cycle_mood_energetic".localized()
            case 5:
                moodLabel.text = "female_cycle_mood_sensitive".localized()
            case 6:
                moodLabel.text = "female_cycle_mood_anxious".localized()
            case 7:
                moodLabel.text = "female_cycle_mood_irritable".localized()
            case 8:
                moodLabel.text = "female_cycle_mood_sad".localized()
            default:
                moodLabel.text = "female_cycle_none".localized()
            }
        }

        XLogger.shared.log("加载症状数据: \(selectedDateString) - \(data), 是否在经期: \(isInPeriod)")
    }

    private func refreshFlowButtons() {
        // 刷新流量按钮状态，根据当前flowLevel更新所有按钮的图标
        guard let flowContainer = flowOptionsView else { return }

        for subview in flowContainer.subviews {
            if let button = subview as? UIButton {
                // 如果按钮的tag小于等于当前等级，则高亮
                let color = button.tag <= flowLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
                let image = createDropletImage(color: color)
                button.setImage(image, for: .normal)
            }
        }
    }

    private func refreshPainButtons() {
        // 刷新痛经按钮状态，根据当前painLevel更新所有按钮的图标
        guard let painContainer = painOptionsView else { return }

        for subview in painContainer.subviews {
            if let button = subview as? UIButton {
                // 如果按钮的tag小于等于当前等级，则高亮
                let color = button.tag <= painLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
                let image = createLightningImage(color: color)
                button.setImage(image, for: .normal)
            }
        }
    }

    // MARK: - Actions

    @objc private func previousMonthTapped() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentDisplayMonth) {
            currentDisplayMonth = newMonth
            updateMonthYearLabel()
            generateCalendarDates()
        }
    }

    @objc private func nextMonthTapped() {
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
        updateCycleInfo()
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

        // 刷新所有流量按钮的状态 - 累计选中（选中等级N时，1到N都高亮）
        if let flowContainer = sender.superview {
            for subview in flowContainer.subviews {
                if let button = subview as? UIButton {
                    // 如果按钮的tag小于等于当前等级，则高亮
                    let color = button.tag <= flowLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
                    let image = createDropletImage(color: color)
                    button.setImage(image, for: .normal)
                }
            }
        }
    }

    @objc private func painButtonTapped(_ sender: UIButton) {
        guard let selectedDate = selectedDate else { return }

        let level = sender.tag
        painLevel = level
        XLogger.shared.log("选择痛经等级: \(level)")

        // 保存到数据管理器
        dataManager.updatePainLevel(for: selectedDate, level: level)

        // 刷新所有痛经按钮的状态 - 累计选中（选中等级N时，1到N都高亮）
        if let painContainer = sender.superview {
            for subview in painContainer.subviews {
                if let button = subview as? UIButton {
                    // 如果按钮的tag小于等于当前等级，则高亮
                    let color = button.tag <= painLevel ? UIColor(hex: 0xFF69B4) : UIColor(hex: 0xE0E0E0)
                    let image = createLightningImage(color: color)
                    button.setImage(image, for: .normal)
                }
            }
        }
    }

    @objc private func sexualActivityTapped() {
        guard let selectedDate = selectedDate else { return }

        XLogger.shared.log("点击性行为")

        let alert = UIAlertController(title: "female_cycle_sexual_activity".localized(), message: nil, preferredStyle: .actionSheet)

        // 无
        let noneAction = UIAlertAction(title: "female_cycle_none".localized(), style: .default) { [weak self] _ in
            guard let self = self, let selectedDate = self.selectedDate else { return }
            self.sexualActivity = 0
            self.dataManager.updateSexualActivity(for: selectedDate, activity: 0)
            self.sexualValueLabel?.text = "female_cycle_none".localized()
            XLogger.shared.log("选择性行为: 无")
        }

        // 保护性行为
        let protectedAction = UIAlertAction(title: "female_cycle_protected_sex".localized(), style: .default) { [weak self] _ in
            guard let self = self, let selectedDate = self.selectedDate else { return }
            self.sexualActivity = 1
            self.dataManager.updateSexualActivity(for: selectedDate, activity: 1)
            self.sexualValueLabel?.text = "female_cycle_protected_sex".localized()
            XLogger.shared.log("选择性行为: 保护性行为")
        }

        // 无保护性行为
        let unprotectedAction = UIAlertAction(title: "female_cycle_unprotected_sex".localized(), style: .default) { [weak self] _ in
            guard let self = self, let selectedDate = self.selectedDate else { return }
            self.sexualActivity = 2
            self.dataManager.updateSexualActivity(for: selectedDate, activity: 2)
            self.sexualValueLabel?.text = "female_cycle_unprotected_sex".localized()
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
                self.moodValueLabel?.text = moodName
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
        let vc = BodySymptomsViewController()
        vc.selectedDate = selectedDate // 传递选中的日期
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
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

        // 更新选中的日期
        selectedDate = date

        // 刷新日历显示
        calendarCollectionView.reloadData()

        // 更新症状记录区域的显示/隐藏
        updateSymptomSectionVisibility()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: 50)
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
        view.backgroundColor = UIColor(hex: 0xFF69B4) // 与"有记录"文字颜色一致
        view.layer.cornerRadius = 2.5
        view.isHidden = true // 默认隐藏
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
        continuousBackgroundView.backgroundColor = .clear
        dayLabel.textColor = UIColor(hex: 0x333333)

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
            // 经期第一天或最后一天：粉色实心圆点
            backgroundCircleView.backgroundColor = UIColor(hex: 0xFFB3D9)
            dayLabel.textColor = .white
        } else if isOvulationFirstDay || isOvulationLastDay {
            // 排卵日、排卵期第一天或最后一天：紫色实心圆点
            backgroundCircleView.backgroundColor = UIColor(hex: 0x7B68EE)
            dayLabel.textColor = .white
        } else if isPredictedFirstDay {
            // 预测经期第一天：粉色虚线圆
            backgroundCircleView.backgroundColor = .clear

            // 设置虚线样式
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = UIColor(hex: 0xFFB3D9).cgColor
            shapeLayer.lineWidth = 2
            shapeLayer.lineDashPattern = [4, 4]
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40)).cgPath

            backgroundCircleView.layer.addSublayer(shapeLayer)
        }

        // 今天的标记：如果不是特殊日期，则保持默认样式（黑色字体，无边框）
        // 特殊日期包括：经期开始/结束日期、排卵期开始/结束日期、排卵日、预测经期开始日期
        // 因此这里不需要额外处理

        // 选中状态：添加外圈边框
        if isSelected {
            backgroundCircleView.layer.borderWidth = 2
            backgroundCircleView.layer.borderColor = UIColor(hex: 0x333333).cgColor
        }

        // 显示/隐藏数据记录小圆点
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
