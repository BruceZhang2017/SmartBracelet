//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  AlarmAdd2ViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2025/01/15.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK
import Toaster

class AlarmAdd2ViewController: BaseViewController {

    // MARK: - Properties
    var alarm: WUAlarmClock!
    var weekday = 0  // 非XGZT模式下的weekday值，与AlarmAddViewController保持一致
    var alarmData: AlarmData?
    var isNew: Bool = false
    private var selectedWeekdays: Int = 0 // 使用位运算存储选中的星期几
    private var selectedHour: Int = 0
    private var selectedMinute: Int = 0
    private var reminderInterval: Int = 0

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // 时间选择行
    private let timeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "time".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .black
        return label
    }()

    private let timeValueLabel: UILabel = {
        let label = UILabel()
        label.text = "18:00"
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()

    private let timeArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // 重复模式标题
    private let repeatLabel: UILabel = {
        let label = UILabel()
        label.text = "repeat".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .black
        return label
    }()

    // 星期按钮容器
    private let weekdayButtonsContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 5
        return stack
    }()

    private var weekdayButtons: [UIButton] = []

    // 提醒间隔行
    private let intervalContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let intervalLabel: UILabel = {
        let label = UILabel()
        label.text = "mine_alarm_late_amind".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .black
        return label
    }()

    private let intervalValueLabel: UILabel = {
        let label = UILabel()
        label.text = "10\("minute".localized())"
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()

    private let intervalArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // 保存按钮
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("mine_save".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // 蓝色
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "device_alarm_settings".localized()
        view.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1.0)

        setupUI()
        loadData()
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Add scrollView
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add contentView
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Setup time row
        setupTimeRow()

        // Setup repeat section
        setupRepeatSection()

        // Setup interval row
        setupIntervalRow()

        // Setup save button
        setupSaveButton()
    }

    private func setupTimeRow() {
        contentView.addSubview(timeContainerView)
        timeContainerView.translatesAutoresizingMaskIntoConstraints = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(timeRowTapped))
        timeContainerView.addGestureRecognizer(tapGesture)

        timeContainerView.addSubview(timeLabel)
        timeContainerView.addSubview(timeValueLabel)
        timeContainerView.addSubview(timeArrowImageView)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        timeArrowImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            timeContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            timeContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            timeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            timeContainerView.heightAnchor.constraint(equalToConstant: 50),

            timeLabel.leadingAnchor.constraint(equalTo: timeContainerView.leadingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: timeContainerView.centerYAnchor),

            timeArrowImageView.trailingAnchor.constraint(equalTo: timeContainerView.trailingAnchor),
            timeArrowImageView.centerYAnchor.constraint(equalTo: timeContainerView.centerYAnchor),
            timeArrowImageView.widthAnchor.constraint(equalToConstant: 20),
            timeArrowImageView.heightAnchor.constraint(equalToConstant: 20),

            timeValueLabel.trailingAnchor.constraint(equalTo: timeArrowImageView.leadingAnchor, constant: -8),
            timeValueLabel.centerYAnchor.constraint(equalTo: timeContainerView.centerYAnchor),
            timeValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: timeLabel.trailingAnchor, constant: 20)
        ])
    }

    private func setupRepeatSection() {
        // Repeat label
        contentView.addSubview(repeatLabel)
        repeatLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            repeatLabel.topAnchor.constraint(equalTo: timeContainerView.bottomAnchor, constant: 40),
            repeatLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            repeatLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30)
        ])

        // Weekday buttons
        contentView.addSubview(weekdayButtonsContainer)
        weekdayButtonsContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            weekdayButtonsContainer.topAnchor.constraint(equalTo: repeatLabel.bottomAnchor, constant: 20),
            weekdayButtonsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weekdayButtonsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weekdayButtonsContainer.heightAnchor.constraint(equalToConstant: 60)
        ])

        let weekdayTitles = ["mine_monday".localized(), "mine_satuday".localized(), "mine_wednesday".localized(), "mine_thursday".localized(), "mine_friday".localized(), "mine_saturday".localized(), "mine_sunday".localized()]

        for (index, title) in weekdayTitles.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.setTitleColor(UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0), for: .normal)
            button.setTitleColor(.white, for: .selected)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.backgroundColor = .white
            button.layer.cornerRadius = 20
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor
            button.clipsToBounds = true
            button.tag = index
            button.addTarget(self, action: #selector(weekdayButtonTapped(_:)), for: .touchUpInside)

            weekdayButtons.append(button)
            weekdayButtonsContainer.addArrangedSubview(button)

            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 40),
                button.widthAnchor.constraint(equalTo: button.heightAnchor)
            ])
        }
    }

    private func setupIntervalRow() {
        contentView.addSubview(intervalContainerView)
        intervalContainerView.translatesAutoresizingMaskIntoConstraints = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(intervalRowTapped))
        intervalContainerView.addGestureRecognizer(tapGesture)

        intervalContainerView.addSubview(intervalLabel)
        intervalContainerView.addSubview(intervalValueLabel)
        intervalContainerView.addSubview(intervalArrowImageView)

        intervalLabel.translatesAutoresizingMaskIntoConstraints = false
        intervalValueLabel.translatesAutoresizingMaskIntoConstraints = false
        intervalArrowImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            intervalContainerView.topAnchor.constraint(equalTo: weekdayButtonsContainer.bottomAnchor, constant: 30),
            intervalContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            intervalContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            intervalContainerView.heightAnchor.constraint(equalToConstant: 50),

            intervalLabel.leadingAnchor.constraint(equalTo: intervalContainerView.leadingAnchor),
            intervalLabel.centerYAnchor.constraint(equalTo: intervalContainerView.centerYAnchor),

            intervalArrowImageView.trailingAnchor.constraint(equalTo: intervalContainerView.trailingAnchor),
            intervalArrowImageView.centerYAnchor.constraint(equalTo: intervalContainerView.centerYAnchor),
            intervalArrowImageView.widthAnchor.constraint(equalToConstant: 20),
            intervalArrowImageView.heightAnchor.constraint(equalToConstant: 20),

            intervalValueLabel.trailingAnchor.constraint(equalTo: intervalArrowImageView.leadingAnchor, constant: -8),
            intervalValueLabel.centerYAnchor.constraint(equalTo: intervalContainerView.centerYAnchor),
            intervalValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: intervalLabel.trailingAnchor, constant: 20)
        ])
    }

    private func setupSaveButton() {
        contentView.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: intervalContainerView.bottomAnchor, constant: 50),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
    }

    // MARK: - Load Data
    private func loadData() {
        if isXGZT {
            if let data = alarmData {
                selectedHour = data.alarmHour
                selectedMinute = data.alarmMinute
                selectedWeekdays = data.alarmCycle
                reminderInterval = data.remindLater

                updateTimeDisplay()
                updateWeekdayButtons()
                updateIntervalDisplay()
            } else {
                // 新建闹钟时使用0值初始化，与AlarmAddViewController保持一致
                alarmData = AlarmData(alarmIndex: 0, mswitch: 0, alarmCycle: 0, alarmHour: 0, alarmMinute: 0, vibrationMode: 0, remindLater: 0)
                isNew = true
                updateTimeDisplay()
                updateIntervalDisplay()
            }
        } else {
            // 非XGZT模式：优先使用weekday属性，与AlarmAddViewController保持一致
            if weekday >= 0 {
                selectedWeekdays = weekday
                updateWeekdayButtons()
            }
            if alarm != nil {
                selectedHour = alarm.hour
                selectedMinute = alarm.minute
                selectedWeekdays = alarm.weekday
                reminderInterval = alarm.repeatInterval

                updateTimeDisplay()
                updateWeekdayButtons()
                updateIntervalDisplay()
            }
        }
    }

    // MARK: - Actions
    @objc private func timeRowTapped() {
        showTimePicker()
    }

    @objc private func weekdayButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let bitPosition = isXGZT ? index : (index == 6 ? 0 : index + 1)
        let bitValue = 1 << bitPosition

        if (selectedWeekdays & bitValue) > 0 {
            selectedWeekdays -= bitValue
        } else {
            selectedWeekdays += bitValue
        }

        updateWeekdayButtons()
    }

    @objc private func intervalRowTapped() {
        showIntervalPicker()
    }

    private func showIntervalPicker() {
        let alert = UIAlertController(title: "mine_alarm_late_amind".localized(), message: nil, preferredStyle: .actionSheet)

        // 添加9个间隔选项：10分钟到90分钟
        for index in 1...9 {
            let intervalValue = index * 10
            let title = "\(intervalValue)\("minute".localized())"
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.reminderInterval = intervalValue
                self?.updateIntervalDisplay()
            }

            // 如果是当前选中的值，显示勾选标记
            if intervalValue == reminderInterval {
                action.setValue(true, forKey: "checked")
            }

            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "cancel".localized(), style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        // iPad 适配
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = intervalContainerView
            popoverController.sourceRect = intervalContainerView.bounds
        }

        present(alert, animated: true, completion: nil)
    }

    @objc private func saveButtonTapped() {
        // 仅在新建XGZT闹钟时验证必须选择星期几，与AlarmAddViewController保持一致
        if isXGZT && isNew {
            if selectedWeekdays == 0 {
                Toast(text: "please_choose_day".localized()).show()
                return
            }
        }

        if isXGZT {
            alarmData?.alarmHour = selectedHour
            alarmData?.alarmMinute = selectedMinute
            alarmData?.alarmCycle = selectedWeekdays
            alarmData?.remindLater = reminderInterval
            alarmData?.mswitch = 1
            alarmData?.vibrationMode = 1

            if isNew {
                alarmData?.alarmIndex = XGZTBlueToothManager.shared.device?.alarmCanUse ?? 0
            }

            XGZTCommand.setAlarmInfo(setCmd: isNew ? 0 : 1, alarm: alarmData!)
        } else {
            alarm.hour = selectedHour
            alarm.minute = selectedMinute
            alarm.weekday = selectedWeekdays
            alarm.repeatInterval = reminderInterval
            alarm.isOn = true

            // 同步weekday属性，与AlarmAddViewController保持一致
            weekday = selectedWeekdays

            bleSelf.setAlarmForWristband(alarm)
        }

        navigationController?.popViewController(animated: true)
    }

    // MARK: - Helper Methods
    private func showTimePicker() {
        let alert = UIAlertController(title: "time".localized(), message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        datePicker.locale = Locale(identifier: "zh_CN")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        if let date = dateFormatter.date(from: String(format: "%02d:%02d", selectedHour, selectedMinute)) {
            datePicker.setDate(date, animated: false)
        }

        datePicker.frame = CGRect(x: 0, y: 0, width: alert.view.bounds.width - 16, height: 200)
        alert.view.addSubview(datePicker)

        let confirmAction = UIAlertAction(title: "mine_save".localized(), style: .default) { [weak self] _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let value = formatter.string(from: datePicker.date)
            let array = value.split(separator: ":")
            if array.count == 2 {
                self?.selectedHour = Int(array[0]) ?? 0
                self?.selectedMinute = Int(array[1]) ?? 0
                self?.updateTimeDisplay()
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func updateTimeDisplay() {
        timeValueLabel.text = String(format: "%02d:%02d", selectedHour, selectedMinute)
    }

    private func updateWeekdayButtons() {
        for (index, button) in weekdayButtons.enumerated() {
            let bitPosition = isXGZT ? index : (index == 6 ? 0 : index + 1)
            let isSelected = (selectedWeekdays & (1 << bitPosition)) > 0

            button.isSelected = isSelected
            if isSelected {
                button.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
            } else {
                button.backgroundColor = .white
            }
        }
    }

    private func updateIntervalDisplay() {
        intervalValueLabel.text = "\(reminderInterval)\("minute".localized())"
    }
}
