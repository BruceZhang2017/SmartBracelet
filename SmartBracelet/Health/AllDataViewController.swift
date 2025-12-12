//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  AllDataViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2025/12/09.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

// 数据记录模型
struct DailyRecord {
    let date: Date
    let cycleDay: Int // 周期第几天（0表示非经期）
    let isPeriod: Bool // 是否是经期
    let hasFlow: Bool // 是否有流量记录
    let hasPain: Bool // 是否有痛经记录
    let hasTemp: Bool // 是否有体温记录
    let hasSexual: Bool // 是否有性行为记录
    let hasMood: Bool // 是否有心情记录
    let hasBodySymptoms: Bool // 是否有身体症状记录
    let recordTime: Date // 记录时间
}

// 月份分组
struct MonthSection {
    let title: String // 如："2025年12月"
    var records: [DailyRecord]
    var isExpanded: Bool = true
}

class AllDataViewController: BaseViewController {

    // MARK: - Properties

    // 数据管理器
    private let dataManager = FemaleCycleDataManager.shared

    private var sections: [MonthSection] = []

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(hex: 0xF5F5F5)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()

        title = "female_cycle_all_data".localized()

        setupUI()
        loadData()
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
        tableView.register(MonthHeaderView.self, forHeaderFooterViewReuseIdentifier: "MonthHeaderView")
        tableView.register(DailyRecordCell.self, forCellReuseIdentifier: "DailyRecordCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次进入页面时刷新数据
        loadData()
    }

    // MARK: - Data Management

    private func loadData() {
        sections.removeAll()

        // 从数据管理器获取按月份分组的记录
        let recordsByMonth = dataManager.getRecordsByMonth()

        // 日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "female_cycle_month_year_format".localized()

        for (monthString, dateStrings) in recordsByMonth {
            var records: [DailyRecord] = []

            for dateString in dateStrings {
                guard let date = dateFormatter.date(from: dateString) else { continue }

                // 从数据管理器获取该日期的症状数据
                let symptomData = dataManager.getDailyData(for: dateString)

                // 计算周期天数
                let cycleDay = dataManager.calculateCycleDay(for: date)
                let isPeriod = cycleDay > 0

                // 检查是否有各种记录
                let hasFlow = symptomData.flowLevel > 0
                let hasPain = symptomData.painLevel > 0
                let hasTemp = false // 暂时没有体温记录功能
                let hasSexual = symptomData.sexualActivity > 0
                let hasMood = symptomData.mood > 0
                let hasBodySymptoms = !symptomData.bodySymptoms.isEmpty

                // 创建记录
                let record = DailyRecord(
                    date: date,
                    cycleDay: cycleDay,
                    isPeriod: isPeriod,
                    hasFlow: hasFlow,
                    hasPain: hasPain,
                    hasTemp: hasTemp,
                    hasSexual: hasSexual,
                    hasMood: hasMood,
                    hasBodySymptoms: hasBodySymptoms,
                    recordTime: date
                )

                records.append(record)
            }

            // 格式化月份标题
            if let firstDate = dateFormatter.date(from: monthString + "-01") {
                let title = monthFormatter.string(from: firstDate)
                sections.append(MonthSection(title: title, records: records, isExpanded: true))
            }
        }

        // 如果没有任何记录，显示提示
        if sections.isEmpty {
            XLogger.shared.log("没有找到任何记录数据")
        } else {
            XLogger.shared.log("加载了 \(sections.count) 个月份的数据，共 \(sections.reduce(0) { $0 + $1.records.count }) 条记录")
        }

        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension AllDataViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].isExpanded ? sections[section].records.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailyRecordCell", for: indexPath) as! DailyRecordCell
        let record = sections[indexPath.section].records[indexPath.row]
        cell.configure(with: record)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MonthHeaderView") as! MonthHeaderView
        header.configure(
            title: sections[section].title,
            isExpanded: sections[section].isExpanded,
            onTap: { [weak self] in
                self?.sections[section].isExpanded.toggle()
                tableView.reloadSections(IndexSet(integer: section), with: .automatic)
            }
        )
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = sections[indexPath.section].records[indexPath.row]

        let vc = DataDetailViewController()
        vc.record = record
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - MonthHeaderView

class MonthHeaderView: UITableViewHeaderFooterView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(hex: 0x999999)
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.down")
        imageView.tintColor = UIColor(hex: 0x999999)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var onTapCallback: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor(hex: 0xF5F5F5)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }

    func configure(title: String, isExpanded: Bool, onTap: @escaping () -> Void) {
        titleLabel.text = title
        onTapCallback = onTap

        UIView.animate(withDuration: 0.3) {
            self.arrowImageView.transform = isExpanded ? .identity : CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        }
    }

    @objc private func handleTap() {
        onTapCallback?()
    }
}

// MARK: - DailyRecordCell

class DailyRecordCell: UITableViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(hex: 0x333333)
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor(hex: 0xCCCCCC)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hex: 0x999999)
        return label
    }()

    private let iconsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
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
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-4)
        }

        containerView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
        }

        containerView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        containerView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
        }

        containerView.addSubview(iconsStackView)
        iconsStackView.snp.makeConstraints { make in
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with record: DailyRecord) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        dateLabel.text = dateFormatter.string(from: record.date)

        if record.isPeriod {
            statusLabel.text = "female_cycle_day_n".localized(with: record.cycleDay) + "\n" + "female_cycle_period".localized()
        } else {
            statusLabel.text = "female_cycle_daily_record".localized()
        }

        // 清空图标
        iconsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 添加图标（按照：流量、痛经、性行为、心情、身体症状的顺序）
        if record.hasFlow {
            let flowIcon = createIconView(color: UIColor(hex: 0xFF69B4), iconType: .droplet)
            iconsStackView.addArrangedSubview(flowIcon)
        }

        if record.hasPain {
            let painIcon = createIconView(color: UIColor(hex: 0xFF69B4), iconType: .lightning)
            iconsStackView.addArrangedSubview(painIcon)
        }

        if record.hasTemp {
            let tempIcon = createIconView(color: UIColor(hex: 0xFF69B4), iconType: .thermometer)
            iconsStackView.addArrangedSubview(tempIcon)
        }

        if record.hasSexual {
            let sexualIcon = createIconView(color: UIColor(hex: 0xFF69B4), iconType: .heart)
            iconsStackView.addArrangedSubview(sexualIcon)
        }

        if record.hasMood {
            let moodIcon = createIconView(color: UIColor(hex: 0xFF69B4), iconType: .smile)
            iconsStackView.addArrangedSubview(moodIcon)
        }

        if record.hasBodySymptoms {
            let symptomsIcon = createIconView(color: UIColor(hex: 0xFF69B4), iconType: .pill)
            iconsStackView.addArrangedSubview(symptomsIcon)
        }
    }

    // 图标类型枚举
    private enum IconType {
        case droplet    // 💧 流量
        case lightning  // ⚡️ 痛经
        case thermometer // 🌡 体温
        case heart      // 💗 性行为
        case smile      // 😊 心情
        case pill       // 💊 身体症状
    }

    private func createIconView(color: UIColor, iconType: IconType) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(hex: 0xFFE6F2)
        containerView.layer.cornerRadius = 10
        containerView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        let imageView = UIImageView()
        switch iconType {
        case .droplet:
            imageView.image = createDropletImage(color: color)
        case .lightning:
            imageView.image = createLightningImage(color: color)
        case .thermometer:
            imageView.image = createThermometerImage(color: color)
        case .heart:
            imageView.image = createHeartImage(color: color)
        case .smile:
            imageView.image = createSmileImage(color: color)
        case .pill:
            imageView.image = createPillImage(color: color)
        }

        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }

        return containerView
    }

    private func createDropletImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 6, y: 2))
            path.addCurve(
                to: CGPoint(x: 6, y: 10),
                controlPoint1: CGPoint(x: 2, y: 4),
                controlPoint2: CGPoint(x: 2, y: 8)
            )
            path.addCurve(
                to: CGPoint(x: 6, y: 2),
                controlPoint1: CGPoint(x: 10, y: 8),
                controlPoint2: CGPoint(x: 10, y: 4)
            )
            path.close()

            color.setFill()
            path.fill()
        }
    }

    private func createLightningImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 7, y: 1))
            path.addLine(to: CGPoint(x: 4, y: 6))
            path.addLine(to: CGPoint(x: 6, y: 6))
            path.addLine(to: CGPoint(x: 5, y: 11))
            path.addLine(to: CGPoint(x: 8, y: 6))
            path.addLine(to: CGPoint(x: 6, y: 6))
            path.close()

            color.setFill()
            path.fill()
        }
    }

    private func createThermometerImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 画温度计的圆形底部
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 3, y: 7, width: 6, height: 6))
            color.setFill()
            circlePath.fill()

            // 画温度计的管子
            let rectPath = UIBezierPath(rect: CGRect(x: 5, y: 1, width: 2, height: 7))
            rectPath.fill()
        }
    }

    private func createHeartImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let path = UIBezierPath()

            // 心形路径
            path.move(to: CGPoint(x: 6, y: 10))

            // 左半边心形
            path.addCurve(
                to: CGPoint(x: 2, y: 4),
                controlPoint1: CGPoint(x: 4, y: 8),
                controlPoint2: CGPoint(x: 2, y: 6)
            )
            path.addCurve(
                to: CGPoint(x: 6, y: 3),
                controlPoint1: CGPoint(x: 2, y: 2),
                controlPoint2: CGPoint(x: 4, y: 2)
            )

            // 右半边心形
            path.addCurve(
                to: CGPoint(x: 10, y: 4),
                controlPoint1: CGPoint(x: 8, y: 2),
                controlPoint2: CGPoint(x: 10, y: 2)
            )
            path.addCurve(
                to: CGPoint(x: 6, y: 10),
                controlPoint1: CGPoint(x: 10, y: 6),
                controlPoint2: CGPoint(x: 8, y: 8)
            )

            path.close()
            color.setFill()
            path.fill()
        }
    }

    private func createSmileImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 画圆形脸
            let facePath = UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: 10, height: 10))
            color.setStroke()
            facePath.lineWidth = 1.2
            facePath.stroke()

            // 画左眼
            let leftEyePath = UIBezierPath(ovalIn: CGRect(x: 3.5, y: 4, width: 1.5, height: 1.5))
            color.setFill()
            leftEyePath.fill()

            // 画右眼
            let rightEyePath = UIBezierPath(ovalIn: CGRect(x: 7, y: 4, width: 1.5, height: 1.5))
            rightEyePath.fill()

            // 画笑脸嘴巴
            let smilePath = UIBezierPath()
            smilePath.move(to: CGPoint(x: 4, y: 7))
            smilePath.addQuadCurve(
                to: CGPoint(x: 8, y: 7),
                controlPoint: CGPoint(x: 6, y: 9)
            )
            smilePath.lineWidth = 1.2
            smilePath.stroke()
        }
    }

    private func createPillImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // 绘制胶囊形状（圆角矩形）
            let pillRect = CGRect(x: 2, y: 4, width: 8, height: 4)
            let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 2)

            color.setFill()
            pillPath.fill()

            // 绘制中间的分隔线
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(1.0)
            ctx.move(to: CGPoint(x: 6, y: 4))
            ctx.addLine(to: CGPoint(x: 6, y: 8))
            ctx.strokePath()
        }
    }
}
