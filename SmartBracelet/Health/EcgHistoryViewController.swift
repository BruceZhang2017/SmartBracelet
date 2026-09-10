//
//  EcgHistoryViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2026/09/06.
//  Copyright © 2026 tjd. All rights reserved.
//

import UIKit
import SnapKit

/// Android 对齐：ECG 历史记录列表页（对应 EcgHistoryActivity + activity_ecg_history.xml / item_ecg_history.xml）
/// 纯橙 header + #F5F7FA 背景；item 白底圆角 16 描边 #E8EEF2，日期 + 时长两行，44dp 图标 + 箭头。
final class EcgHistoryViewController: BaseViewController {

    private var records: [EcgHistorySummary] = []

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(hex: 0xF5F7FA)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "ecg_loading".localized()
        label.textColor = UIColor(hex: 0x64748B)
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        bStyle = 0
        super.viewDidLoad()
        title = "ecg_history".localized()
        view.backgroundColor = UIColor.brand

        setupNavigationBar()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EcgHistoryCell.self, forCellReuseIdentifier: "EcgHistoryCell")

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .medium)
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.navigationBar.tintColor = UIColor.text_primary
            navigationController?.navigationBar.titleTextAttributes = nil
        }
    }

    private func loadData() {
        DatabaseManager.shared.getAllEcgHistoryObjs { [weak self] results in
            guard let self = self else { return }
            self.records = results
            self.emptyLabel.text = "ecg_history_empty".localized()
            self.emptyLabel.isHidden = !results.isEmpty
            self.tableView.reloadData()
            self.tableView.isHidden = results.isEmpty
        }
    }
}

extension EcgHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96 + 12
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EcgHistoryCell", for: indexPath) as! EcgHistoryCell
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < records.count else { return }
        let record = records[indexPath.row]
        let vc = EcgHistoryDetailViewController()
        vc.recordId = record.id
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

final class EcgHistoryCell: UITableViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: 0xE8EEF2).cgColor
        return view
    }()

    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "health_ecg")
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(hex: 0x1E293B)
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(hex: 0x64748B)
        return label
    }()

    private let arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        view.tintColor = UIColor(hex: 0x94A3B8)
        view.contentMode = .scaleAspectFit
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
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        containerView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        containerView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(14)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-8)
            make.centerY.equalToSuperview().offset(-12)
        }

        containerView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateLabel.snp.leading)
            make.trailing.equalTo(dateLabel.snp.trailing)
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
        }
    }

    func configure(with record: EcgHistorySummary) {
        let date = Date(timeIntervalSince1970: record.startedAt / 1000)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        let seconds = (record.durationMillis + 999) / 1000
        durationLabel.text = "ecg_history_duration".localized(with: timeFormatter.string(from: date), "\(seconds)")
    }
}