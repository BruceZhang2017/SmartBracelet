//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  FemaleHealthViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2025/12/04.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

class FemaleHealthViewController: BaseViewController {

    // MARK: - Properties

    /// 是否隐藏最后一次月经日期选项（从周期设置进入时隐藏）
    var hideLastPeriodDateOption: Bool = false {
        didSet {
            if hideLastPeriodDateOption {
                startPredictionButton.setTitle("female_cycle_save".localized(), for: .normal)
            } else {
                startPredictionButton.setTitle("female_cycle_start_prediction".localized(), for: .normal)
            }
        }
    }

    // MARK: - UI Components

    private let questionLabel1: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_period_days".localized()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()

    private let periodDaysContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()

    private let periodDaysTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_period_days".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black
        return label
    }()

    private let periodDaysValueLabel: UILabel = {
        let label = UILabel()
        label.text = "7" + "female_cycle_days_unit".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: 0x9097A0, alpha: 1)
        label.textAlignment = .right
        return label
    }()

    private let periodDaysArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0x9097A0, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let questionLabel2: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_cycle_length".localized()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()

    private let cycleLengthContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()

    private let cycleLengthTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_cycle_length".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black
        return label
    }()

    private let cycleLengthValueLabel: UILabel = {
        let label = UILabel()
        label.text = "28" + "female_cycle_days_unit".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: 0x9097A0, alpha: 1)
        label.textAlignment = .right
        return label
    }()

    private let cycleLengthArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0x9097A0, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let questionLabel3: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_question_last_period".localized()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()

    private let lastPeriodContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()

    private let lastPeriodTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_last_period_start_date".localized()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black
        return label
    }()

    private let lastPeriodValueLabel: UILabel = {
        let label = UILabel()
        label.text = "2025-12-04"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: 0x9097A0, alpha: 1)
        label.textAlignment = .right
        return label
    }()

    private let lastPeriodArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0x9097A0, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let startPredictionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("female_cycle_start_prediction".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.brand
        button.layer.cornerRadius = 22
        return button
    }()

    // MARK: - Properties

    private var periodDays: Int = 7 {
        didSet {
            periodDaysValueLabel.text = "\(periodDays)" + "female_cycle_days_unit".localized()
            saveFemaleHealthData()
        }
    }

    private var cycleLength: Int = 28 {
        didSet {
            cycleLengthValueLabel.text = "\(cycleLength)" + "female_cycle_days_unit".localized()
            saveFemaleHealthData()
        }
    }

    private var lastPeriodDate: Date = Date() {
        didSet {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            lastPeriodValueLabel.text = formatter.string(from: lastPeriodDate)
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

        // 根据进入方式设置按钮文本
        if hideLastPeriodDateOption {
            startPredictionButton.setTitle("female_cycle_save".localized(), for: .normal)
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xF5F5F5, alpha: 1)

        // Add question label 1
        view.addSubview(questionLabel1)
        questionLabel1.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Add period days container
        view.addSubview(periodDaysContainerView)
        periodDaysContainerView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel1.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
        }

        periodDaysContainerView.addSubview(periodDaysTitleLabel)
        periodDaysTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        periodDaysContainerView.addSubview(periodDaysArrowImageView)
        periodDaysArrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        periodDaysContainerView.addSubview(periodDaysValueLabel)
        periodDaysValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(periodDaysArrowImageView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        let periodDaysTap = UITapGestureRecognizer(target: self, action: #selector(periodDaysTapped))
        periodDaysContainerView.addGestureRecognizer(periodDaysTap)

        // Add question label 2
        view.addSubview(questionLabel2)
        questionLabel2.snp.makeConstraints { make in
            make.top.equalTo(periodDaysContainerView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Add cycle length container
        view.addSubview(cycleLengthContainerView)
        cycleLengthContainerView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel2.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
        }

        cycleLengthContainerView.addSubview(cycleLengthTitleLabel)
        cycleLengthTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        cycleLengthContainerView.addSubview(cycleLengthArrowImageView)
        cycleLengthArrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        cycleLengthContainerView.addSubview(cycleLengthValueLabel)
        cycleLengthValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(cycleLengthArrowImageView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        let cycleLengthTap = UITapGestureRecognizer(target: self, action: #selector(cycleLengthTapped))
        cycleLengthContainerView.addGestureRecognizer(cycleLengthTap)

        // Add question label 3 and last period container (conditionally)
        if !hideLastPeriodDateOption {
            // Add question label 3
            view.addSubview(questionLabel3)
            questionLabel3.snp.makeConstraints { make in
                make.top.equalTo(cycleLengthContainerView.snp.bottom).offset(32)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            }

            // Add last period container
            view.addSubview(lastPeriodContainerView)
            lastPeriodContainerView.snp.makeConstraints { make in
                make.top.equalTo(questionLabel3.snp.bottom).offset(12)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.height.equalTo(56)
            }

            lastPeriodContainerView.addSubview(lastPeriodTitleLabel)
            lastPeriodTitleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }

            lastPeriodContainerView.addSubview(lastPeriodArrowImageView)
            lastPeriodArrowImageView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(16)
            }

            lastPeriodContainerView.addSubview(lastPeriodValueLabel)
            lastPeriodValueLabel.snp.makeConstraints { make in
                make.trailing.equalTo(lastPeriodArrowImageView.snp.leading).offset(-8)
                make.centerY.equalToSuperview()
            }

            let lastPeriodTap = UITapGestureRecognizer(target: self, action: #selector(lastPeriodTapped))
            lastPeriodContainerView.addGestureRecognizer(lastPeriodTap)
        }

        // Add start prediction button
        view.addSubview(startPredictionButton)
        startPredictionButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.height.equalTo(44)
        }

        startPredictionButton.addTarget(self, action: #selector(startPredictionTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func periodDaysTapped() {
        let alert = UIAlertController(title: "female_cycle_select_period_days".localized(), message: nil, preferredStyle: .actionSheet)

        for days in 3...10 {
            let action = UIAlertAction(title: "\(days)" + "female_cycle_days_unit".localized(), style: .default) { [weak self] _ in
                self?.periodDays = days
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = periodDaysContainerView
            popoverController.sourceRect = periodDaysContainerView.bounds
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func cycleLengthTapped() {
        let alert = UIAlertController(title: "female_cycle_select_cycle_length".localized(), message: nil, preferredStyle: .actionSheet)

        for days in 21...35 {
            let action = UIAlertAction(title: "\(days)" + "female_cycle_days_unit".localized(), style: .default) { [weak self] _ in
                self?.cycleLength = days
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "female_cycle_cancel".localized(), style: .cancel, handler: nil))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cycleLengthContainerView
            popoverController.sourceRect = cycleLengthContainerView.bounds
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func lastPeriodTapped() {
        let pickerView = TTADataPickerView(title: "female_cycle_select_date".localized(), type: .date, delegate: self)
        pickerView.show {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = UIColor(white: 1.0, alpha: 0.01)
            })
        }
    }

    @objc private func startPredictionTapped() {
        if hideLastPeriodDateOption {
            // 从周期设置进入，点击保存后返回
            saveFemaleHealthData()
            navigationController?.popViewController(animated: true)
        } else {
            // 正常流程，跳转到日历页面，并从导航栈中移除当前设置页面
            let vc = FemaleCycleCalendarViewController()
            vc.hidesBottomBarWhenPushed = true

            if var viewControllers = navigationController?.viewControllers {
                // 移除当前的 FemaleHealthViewController
                viewControllers.removeLast()
                // 添加新的 FemaleCycleCalendarViewController
                viewControllers.append(vc)
                navigationController?.setViewControllers(viewControllers, animated: true)
            }
        }
    }

    // MARK: - Data Management

    private func saveFemaleHealthData() {
        // 使用数据管理器保存配置
        FemaleCycleDataManager.shared.updateCycleConfiguration(
            periodDays: periodDays,
            cycleLength: cycleLength,
            lastPeriodDate: lastPeriodDate
        )
        XLogger.shared.log("保存女性健康配置: periodDays=\(periodDays), cycleLength=\(cycleLength), lastPeriodDate=\(lastPeriodDate)")
    }

    private func loadFemaleHealthData() {
        // 从数据管理器加载配置
        let config = FemaleCycleDataManager.shared.getCycleConfiguration()

        if config.periodDays > 0 {
            periodDays = config.periodDays
        }

        if config.cycleLength > 0 {
            cycleLength = config.cycleLength
        }

        // 总是加载最后一次经期日期
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
