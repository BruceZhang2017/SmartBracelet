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

    // MARK: - UI Components

    private let questionLabel1: UILabel = {
        let label = UILabel()
        label.text = "您的月经一般持续几天?"
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
        label.text = "经期天数"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black
        return label
    }()

    private let periodDaysValueLabel: UILabel = {
        let label = UILabel()
        label.text = "7天"
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
        label.text = "您的两次月经一般间隔多久?"
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
        label.text = "周期长度"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black
        return label
    }()

    private let cycleLengthValueLabel: UILabel = {
        let label = UILabel()
        label.text = "28天"
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
        label.text = "您的最近一次月经是哪天开始的呢?"
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
        label.text = "最近一次月经开始日"
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
        button.setTitle("开始预测", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.brand
        button.layer.cornerRadius = 22
        return button
    }()

    // MARK: - Properties

    private var periodDays: Int = 7 {
        didSet {
            periodDaysValueLabel.text = "\(periodDays)天"
            saveFemaleHealthData()
        }
    }

    private var cycleLength: Int = 28 {
        didSet {
            cycleLengthValueLabel.text = "\(cycleLength)天"
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

        title = "生理周期"

        setupUI()
        loadFemaleHealthData()
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
        let alert = UIAlertController(title: "选择经期天数", message: nil, preferredStyle: .actionSheet)

        for days in 3...10 {
            let action = UIAlertAction(title: "\(days)天", style: .default) { [weak self] _ in
                self?.periodDays = days
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = periodDaysContainerView
            popoverController.sourceRect = periodDaysContainerView.bounds
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func cycleLengthTapped() {
        let alert = UIAlertController(title: "选择周期长度", message: nil, preferredStyle: .actionSheet)

        for days in 21...35 {
            let action = UIAlertAction(title: "\(days)天", style: .default) { [weak self] _ in
                self?.cycleLength = days
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cycleLengthContainerView
            popoverController.sourceRect = cycleLengthContainerView.bounds
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func lastPeriodTapped() {
        let pickerView = TTADataPickerView(title: "选择日期", type: .date, delegate: self)
        pickerView.show {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = UIColor(white: 1.0, alpha: 0.01)
            })
        }
    }

    @objc private func startPredictionTapped() {
        // TODO: 实现开始预测逻辑
        let alert = UIAlertController(title: "开始预测", message: "预测功能正在开发中", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Data Management

    private func saveFemaleHealthData() {
        UserDefaults.standard.set(periodDays, forKey: "FemaleHealth_PeriodDays")
        UserDefaults.standard.set(cycleLength, forKey: "FemaleHealth_CycleLength")
        UserDefaults.standard.set(lastPeriodDate.timeIntervalSince1970, forKey: "FemaleHealth_LastPeriodDate")
        UserDefaults.standard.synchronize()
    }

    private func loadFemaleHealthData() {
        let savedPeriodDays = UserDefaults.standard.integer(forKey: "FemaleHealth_PeriodDays")
        if savedPeriodDays > 0 {
            periodDays = savedPeriodDays
        }

        let savedCycleLength = UserDefaults.standard.integer(forKey: "FemaleHealth_CycleLength")
        if savedCycleLength > 0 {
            cycleLength = savedCycleLength
        }

        let savedLastPeriodDate = UserDefaults.standard.double(forKey: "FemaleHealth_LastPeriodDate")
        if savedLastPeriodDate > 0 {
            lastPeriodDate = Date(timeIntervalSince1970: savedLastPeriodDate)
        }
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
