//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  DataDetailViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2025/12/09.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

class DataDetailViewController: BaseViewController {

    // MARK: - Properties

    var record: DailyRecord?

    // 数据管理器
    private let dataManager = FemaleCycleDataManager.shared

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor(hex: 0xF5F5F5)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        return tableView
    }()

    private var detailItems: [(title: String, value: String)] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()

        title = "数据详情"

        setupUI()
        loadDetailData()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xF5F5F5)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DetailItemCell.self, forCellReuseIdentifier: "DetailItemCell")
    }

    // MARK: - Data Management

    private func loadDetailData() {
        guard let record = record else { return }

        detailItems.removeAll()

        // 周期天数
        if record.isPeriod {
            detailItems.append(("第\(record.cycleDay)天", "经期"))
        } else {
            detailItems.append(("日常记录", "周期"))
        }

        // 从数据管理器获取该日期的症状数据
        let symptomData = dataManager.getDailyData(for: record.date)

        // 流量
        let flowText: String
        switch symptomData.flowLevel {
        case 1:
            flowText = "少"
        case 2:
            flowText = "中"
        case 3:
            flowText = "多"
        default:
            flowText = "无"
        }
        detailItems.append((flowText, "流量"))

        // 痛经
        let painText: String
        switch symptomData.painLevel {
        case 1:
            painText = "轻微"
        case 2:
            painText = "中等"
        case 3:
            painText = "严重"
        default:
            painText = "无"
        }
        detailItems.append((painText, "痛经"))

        // 性行为
        let sexualText: String
        switch symptomData.sexualActivity {
        case 1:
            sexualText = "保护性行为"
        case 2:
            sexualText = "无保护性行为"
        default:
            sexualText = "无"
        }
        detailItems.append((sexualText, "性行为"))

        // 心情
        let moodText: String
        switch symptomData.mood {
        case 1:
            moodText = "平静"
        case 2:
            moodText = "开心"
        case 3:
            moodText = "放松"
        case 4:
            moodText = "活力满满"
        case 5:
            moodText = "敏感"
        case 6:
            moodText = "焦躁"
        case 7:
            moodText = "易怒"
        case 8:
            moodText = "悲伤"
        default:
            moodText = "无"
        }
        detailItems.append((moodText, "心情"))

        // 身体症状
        let bodySymptoms = symptomData.bodySymptoms
        if !bodySymptoms.isEmpty {
            // 将症状数组转换为易读的字符串（去掉分类前缀）
            let symptomsText = bodySymptoms.map { symptom in
                // 格式："分类-症状" -> "症状"
                if let index = symptom.firstIndex(of: "-") {
                    return String(symptom[symptom.index(after: index)...])
                } else {
                    return symptom
                }
            }.joined(separator: "、")
            detailItems.append((symptomsText, "身体症状"))
        } else {
            detailItems.append(("无", "身体症状"))
        }

        // 记录时间
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let timeString = dateFormatter.string(from: record.recordTime)
        detailItems.append((timeString, "记录到'U-Watch'的时间"))

        XLogger.shared.log("加载数据详情: 日期=\(record.date), 流量=\(flowText), 痛经=\(painText), 性行为=\(sexualText), 心情=\(moodText), 身体症状数=\(bodySymptoms.count)")

        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension DataDetailViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailItemCell", for: indexPath) as! DetailItemCell
        let item = detailItems[indexPath.row]
        cell.configure(title: item.title, subtitle: item.value)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}

// MARK: - DetailItemCell

class DetailItemCell: UITableViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(hex: 0x333333)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hex: 0x999999)
        return label
    }()

    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xF0F0F0)
        return view
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
            make.edges.equalToSuperview()
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(16)
        }

        containerView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        containerView.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
