//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  BodySymptomsViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2025/12/09.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

// 身体症状数据模型
struct BodySymptomCategory {
    let title: String
    let symptoms: [String]
}

class BodySymptomsViewController: BaseViewController {

    // MARK: - Properties

    // 数据管理器
    private let dataManager = FemaleCycleDataManager.shared

    // 当前选中的日期（从上一个页面传入）
    var selectedDate: Date?

    // 使用 "分类-症状" 格式作为唯一标识，避免不同分类下同名症状的冲突
    private var selectedSymptoms: Set<String> = []

    private let categories: [BodySymptomCategory] = [
        BodySymptomCategory(title: "全身", symptoms: ["正常", "抽筋", "疲劳", "浮肿"]),
        BodySymptomCategory(title: "头部", symptoms: ["头痛", "眩晕", "呕吐", "失眠"]),
        BodySymptomCategory(title: "腹部", symptoms: ["腹泻", "小腹坠痛", "腹部肿痛", "腹部较痛"]),
        BodySymptomCategory(title: "腿部", symptoms: ["大腿酸胀", "大腿痉挛", "小腿酸胀", "小腿痉挛"]),
        BodySymptomCategory(title: "其他", symptoms: ["乳房胀痛", "腰酸背痛", "潮热", "虚寒"]),
        BodySymptomCategory(title: "分泌物", symptoms: ["干燥", "黏稠", "蛋清状", "水状", "乳液状"]),
        BodySymptomCategory(title: "皮肤", symptoms: ["正常", "出油", "干燥", "粉刺", "冒痘"])
    ]

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor(hex: 0xF5F5F5)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        return tableView
    }()

    private let confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("确定", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.brand
        button.layer.cornerRadius = 22
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()

        title = "身体症状"

        setupUI()
        loadSelectedSymptoms()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xF5F5F5)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-60)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SymptomCategoryCell.self, forCellReuseIdentifier: "SymptomCategoryCell")

        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(44)
        }

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    // MARK: - Data Management

    private func loadSelectedSymptoms() {
        // 如果没有传入选中日期，使用今天
        let date = selectedDate ?? Date()

        // 从数据管理器加载指定日期的身体症状
        let data = dataManager.getDailyData(for: date)
        selectedSymptoms = Set(data.bodySymptoms)

        XLogger.shared.log("加载身体症状: \(data.bodySymptoms)")
    }

    private func saveSelectedSymptoms() {
        // 如果没有传入选中日期，使用今天
        let date = selectedDate ?? Date()

        // 保存到数据管理器
        let symptomsArray = Array(selectedSymptoms)
        dataManager.updateBodySymptoms(for: date, symptoms: symptomsArray)

        XLogger.shared.log("保存身体症状: \(symptomsArray)")
    }

    // MARK: - Actions

    @objc private func confirmTapped() {
        saveSelectedSymptoms()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension BodySymptomsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SymptomCategoryCell", for: indexPath) as! SymptomCategoryCell

        let category = categories[indexPath.section]
        cell.configure(
            category: category,
            selectedSymptoms: selectedSymptoms,
            onSymptomSelected: { [weak self] categoryTitle, symptom in
                self?.toggleSymptom(categoryTitle: categoryTitle, symptom: symptom)
            }
        )

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.text = categories[section].title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(hex: 0x333333)

        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-8)
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    private func toggleSymptom(categoryTitle: String, symptom: String) {
        // 使用 "分类-症状" 格式作为唯一标识
        let symptomKey = "\(categoryTitle)-\(symptom)"

        if selectedSymptoms.contains(symptomKey) {
            selectedSymptoms.remove(symptomKey)
            XLogger.shared.log("取消选择症状: \(symptomKey)")
        } else {
            selectedSymptoms.insert(symptomKey)
            XLogger.shared.log("选择症状: \(symptomKey)")
        }
        tableView.reloadData()
    }
}

// MARK: - SymptomCategoryCell

class SymptomCategoryCell: UITableViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()

    private let symptomsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
        }

        containerView.addSubview(symptomsStackView)
        symptomsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    private var currentCategoryTitle: String = ""
    private var onSymptomSelected: ((String, String) -> Void)?

    func configure(category: BodySymptomCategory, selectedSymptoms: Set<String>, onSymptomSelected: @escaping (String, String) -> Void) {
        self.currentCategoryTitle = category.title
        self.onSymptomSelected = onSymptomSelected

        // 清空之前的视图
        symptomsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 创建症状按钮
        var currentRow: UIStackView?
        var buttonCountInRow = 0

        for (index, symptom) in category.symptoms.enumerated() {
            if buttonCountInRow == 0 {
                // 创建新行
                let rowStack = UIStackView()
                rowStack.axis = .horizontal
                rowStack.spacing = 12
                rowStack.distribution = .fillEqually
                symptomsStackView.addArrangedSubview(rowStack)
                currentRow = rowStack

                if index > 0 {
                    // 添加行间距
                    symptomsStackView.setCustomSpacing(12, after: symptomsStackView.arrangedSubviews[symptomsStackView.arrangedSubviews.count - 2])
                }
            }

            // 检查是否选中：使用 "分类-症状" 格式
            let symptomKey = "\(category.title)-\(symptom)"
            let isSelected = selectedSymptoms.contains(symptomKey)

            let button = createSymptomButton(
                title: symptom,
                isSelected: isSelected
            )

            currentRow?.addArrangedSubview(button)
            buttonCountInRow += 1

            // 每行最多2个按钮
            if buttonCountInRow == 2 {
                buttonCountInRow = 0
            }
        }

        // 如果最后一行只有一个按钮，添加一个占位视图
        if buttonCountInRow == 1, let lastRow = currentRow {
            let spacer = UIView()
            lastRow.addArrangedSubview(spacer)
        }
    }

    private func createSymptomButton(title: String, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)

        if isSelected {
            button.backgroundColor = UIColor(hex: 0xFFE6F2)
            button.setTitleColor(UIColor(hex: 0xFF69B4), for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(hex: 0xFF69B4).cgColor
        } else {
            button.backgroundColor = UIColor(hex: 0xF8F8F8)
            button.setTitleColor(UIColor(hex: 0x666666), for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(hex: 0xE0E0E0).cgColor
        }

        button.layer.cornerRadius = 6
        button.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        button.addTarget(self, action: #selector(symptomButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    @objc private func symptomButtonTapped(_ sender: UIButton) {
        if let title = sender.title(for: .normal) {
            onSymptomSelected?(currentCategoryTitle, title)
        }
    }
}
