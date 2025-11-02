//
//  SportBViewController.swift
//  SmartBracelet
//
//  Created by anker_bruce on 2025/10/26.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - 运动类型定义
enum SportType: Int, CaseIterable {
    case outdoorRunning = 0
    case indoorRunning
    case outdoorWalking
    case indoorWalking
    case hiking
    case cycling
    
    var title: String {
        switch self {
        case .outdoorRunning: return "户外跑步"
        case .indoorRunning: return "室内跑步"
        case .outdoorWalking: return "户外步行"
        case .indoorWalking: return "室内步行"
        case .hiking: return "徒步"
        case .cycling: return "骑行"
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .outdoorRunning: return UIImage(named: "hwpb_u")
        case .indoorRunning: return UIImage(named: "slpb_u")
        case .outdoorWalking, .indoorWalking: return UIImage(systemName: "figure.walk")
        case .hiking: return UIImage(systemName: "figure.hike")
        case .cycling: return UIImage(systemName: "figure.cycle")
        }
    }

    var selectedIcon: UIImage? {
        switch self {
        case .outdoorRunning: return UIImage(named: "hwpb_s")
        case .indoorRunning: return UIImage(named: "slpb_s")
        case .outdoorWalking, .indoorWalking: return UIImage(systemName: "figure.walk.circle.fill")
        case .hiking: return UIImage(systemName: "figure.hiking.circle.fill")
        case .cycling: return UIImage(systemName: "figure.outdoor.cycle")
        }
    }
    
    var accentColor: UIColor {
        switch self {
        case .outdoorRunning: return .systemBlue
        case .indoorRunning: return .systemTeal
        case .outdoorWalking: return .systemGreen
        case .indoorWalking: return .systemRed  // 修复为系统红色保持一致性
        case .hiking: return .systemBrown
        case .cycling: return .systemOrange
        }
    }
}

// MARK: - 数据模型
struct SportStatistic {
    let distance: Double // 公里
    let duration: TimeInterval // 秒
    let calories: Int // 卡路里
}

// MARK: - 顶部选项卡Cell
class SportTabCell: UICollectionViewCell {
    static let reuseIdentifier = "SportTabCell"

    // 图标视图（左侧）
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // 标题标签（右侧）
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 向下的三角形指示器
    private let triangleIndicator: TriangleView = {
        let triangle = TriangleView()
        triangle.isHidden = true
        triangle.translatesAutoresizingMaskIntoConstraints = false
        return triangle
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupAppearance()
    }

    private func setupAppearance() {
        // 设置圆角为半圆（高度的一半）
        let cornerRadius = contentView.bounds.height / 2
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = true

        // cell 本身不裁剪，以便三角形可以显示在外面
        layer.masksToBounds = false
        clipsToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        // 更新阴影路径以提升性能（只包含 contentView 部分）
        layer.shadowPath = UIBezierPath(roundedRect: contentView.frame, cornerRadius: cornerRadius).cgPath
    }

    private func setupLayout() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        addSubview(triangleIndicator)

        NSLayoutConstraint.activate([
            // 图标约束（左侧）
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            // 标题约束（右侧）
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // 三角形指示器约束（紧贴 contentView 底部，水平居中，向下指）
            triangleIndicator.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            triangleIndicator.centerXAnchor.constraint(equalTo: centerXAnchor), // 相对于整个 cell 水平居中
            triangleIndicator.widthAnchor.constraint(equalToConstant: 12),
            triangleIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    func configure(with type: SportType, isSelected: Bool) {
        // 设置图标
        iconImageView.image = isSelected ? type.selectedIcon : type.icon
        iconImageView.tintColor = isSelected ? .white : .label

        // 设置标题
        titleLabel.text = type.title
        titleLabel.textColor = isSelected ? .white : .label

        // 设置背景色
        contentView.backgroundColor = isSelected ? .black : .white

        // 设置三角形指示器
        triangleIndicator.isHidden = !isSelected
        triangleIndicator.fillColor = .black

        // 更新阴影
        layer.shadowOpacity = isSelected ? 0.2 : 0.1
    }
}

// MARK: - 三角形指示器视图
class TriangleView: UIView {
    var fillColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 绘制向下的三角形
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY)) // 底部中心点
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY)) // 左上角
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) // 右上角
        path.close()

        context.setFillColor(fillColor.cgColor)
        path.fill()
    }
}

// MARK: - 主视图控制器
class SportBViewController: BaseViewController {
    
    // MARK: - 私有属性
    private let sportTypes = SportType.allCases
    private var selectedIndex = 0
    private var currentStats: SportStatistic = .init(distance: 0, duration: 0, calories: 0)
    
    // 顶部选项卡
    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        // 初始设置较小的inset，稍后根据屏幕宽度动态调整
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(SportTabCell.self, forCellWithReuseIdentifier: SportTabCell.reuseIdentifier)
        cv.backgroundColor = .clear // 移除背景色
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast // 快速减速，使滚动更精确
        cv.clipsToBounds = false // 不裁剪，确保三角形等内容可以显示在外面
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // 运动数据展示区
    private let statsContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // 数据标签
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let distanceUnitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.text = "累计距离(公里)"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 控制按钮
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 30
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 辅助功能区
    private let featuresStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupHierarchy()
        setupConstraints()
        updateUI(for: sportTypes[selectedIndex])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 在布局完成后调整 collectionView 的 contentInset
        updateCollectionViewInsets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - 初始化设置
    private func setupView() {
        view.backgroundColor = .systemBackground
        setupFeatureButtons()
    }
    
    private func setupHierarchy() {
        view.addSubview(tabCollectionView)
        view.addSubview(statsContainer)
        statsContainer.addSubview(backgroundImageView)
        statsContainer.addSubview(distanceLabel)
        statsContainer.addSubview(distanceUnitLabel)
        statsContainer.addSubview(startButton)
        view.addSubview(featuresStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 顶部选项卡（增加高度以容纳三角形）
            tabCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabCollectionView.heightAnchor.constraint(equalToConstant: 60), // 增加高度以容纳 cell(44) + 三角形(6) + 间距(10)
            
            // 数据展示区
            statsContainer.topAnchor.constraint(equalTo: tabCollectionView.bottomAnchor, constant: 16),
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsContainer.heightAnchor.constraint(equalToConstant: 300),
            
            // 背景图
            backgroundImageView.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            
            // 数据标签
            distanceLabel.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor),
            distanceLabel.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor, constant: -30),
            
            distanceUnitLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 8),
            distanceUnitLabel.centerXAnchor.constraint(equalTo: distanceLabel.centerXAnchor),
            
            // 开始按钮
            startButton.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: -30),
            startButton.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 120),
            startButton.heightAnchor.constraint(equalToConstant: 60),
            
            // 功能区
            featuresStackView.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            featuresStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            featuresStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            featuresStackView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // MARK: - 功能按钮设置
    private func setupFeatureButtons() {
        let features = [
            ("历史记录", "clock.fill"),
            ("运动计划", "calendar"),
            ("数据统计", "chart.bar.fill"),
            ("设置", "gear")
        ]
        
        features.forEach { (title, iconName) in
            let button = FeatureButton(title: title, iconName: iconName)
            button.addTarget(self, action: #selector(featureButtonTapped(_:)), for: .touchUpInside)
            featuresStackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - UI更新
    private func updateUI(for type: SportType) {
        // 更新背景图（使用系统图片作为默认兜底）
        if type == .outdoorRunning {
            backgroundImageView.image = UIImage(named: "map")
        } else {
            backgroundImageView.image = UIImage(named: type.title)
                ?? UIImage(systemName: "figure.run")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        }

        startButton.backgroundColor = type.accentColor

        // 更新数据显示
        distanceLabel.text = String(format: "%.1f", currentStats.distance)

        // 滚动到选中项（居中显示）
        scrollToItem(at: selectedIndex, animated: true)
    }

    /// 更新 collectionView 的 contentInset，确保第一个和最后一个 cell 可以居中
    private func updateCollectionViewInsets() {
        guard tabCollectionView.bounds.width > 0 else { return }

        let halfScreenWidth = tabCollectionView.bounds.width / 2

        if let layout = tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // 计算第一个和最后一个 cell 的宽度
            let firstItemSize = collectionView(tabCollectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0))
            let lastItemIndex = sportTypes.count - 1
            let lastItemSize = collectionView(tabCollectionView, layout: layout, sizeForItemAt: IndexPath(item: lastItemIndex, section: 0))

            // 设置 contentInset，使首尾 cell 能居中
            let leftInset = halfScreenWidth - firstItemSize.width / 2
            let rightInset = halfScreenWidth - lastItemSize.width / 2

            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: max(leftInset, 20),
                bottom: 0,
                right: max(rightInset, 20)
            )

            // 滚动到当前选中项
            scrollToItem(at: selectedIndex, animated: false)
        }
    }

    /// 将指定索引的 cell 滚动到屏幕中央
    private func scrollToItem(at index: Int, animated: Bool) {
        guard index >= 0, index < sportTypes.count else { return }

        let indexPath = IndexPath(item: index, section: 0)

        // 确保 cell 已经布局
        tabCollectionView.layoutIfNeeded()

        // 获取 cell 的位置信息
        guard let attributes = tabCollectionView.layoutAttributesForItem(at: indexPath) else {
            // 如果无法获取属性，使用默认滚动方式
            tabCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
            return
        }

        // 计算将 cell 居中所需的偏移量
        let cellCenterX = attributes.frame.midX
        let collectionViewCenterX = tabCollectionView.bounds.width / 2
        var targetOffsetX = cellCenterX - collectionViewCenterX

        // 限制偏移范围，不超出 contentSize
        let maxOffsetX = tabCollectionView.contentSize.width - tabCollectionView.bounds.width + tabCollectionView.contentInset.right
        let minOffsetX = -tabCollectionView.contentInset.left
        targetOffsetX = max(minOffsetX, min(targetOffsetX, maxOffsetX))

        tabCollectionView.setContentOffset(CGPoint(x: targetOffsetX, y: 0), animated: animated)
    }
    
    // MARK: - 事件处理
    @objc private func startButtonTapped() {
        let type = sportTypes[selectedIndex]
        let alert = UIAlertController(
            title: "开始\(type.title)",
            message: "确定要开始新的\(type.title)记录吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .default) { [weak self] _ in
            self?.startSportSession()
        })
        present(alert, animated: true)
    }
    
    @objc private func featureButtonTapped(_ sender: FeatureButton) {
        print("点击了功能按钮: \(sender.titleLabel?.text ?? "")")
        // 这里可以添加对应功能的跳转逻辑
    }
    
    private func startSportSession() {
        // 模拟开始运动
        let type = sportTypes[selectedIndex]
        let vc = SportSessionViewController(sportType: type)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 集合视图代理
extension SportBViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sportTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SportTabCell.reuseIdentifier,
            for: indexPath
        ) as? SportTabCell else {
            return UICollectionViewCell()
        }
        
        let type = sportTypes[indexPath.item]
        cell.configure(with: type, isSelected: indexPath.item == selectedIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let type = sportTypes[indexPath.item]
        let textWidth = type.title.size(withAttributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]).width
        // 总宽度 = 左边距(12) + 图标(20) + 间距(8) + 文字宽度 + 右边距(12) + 额外安全边距(4)
        let width = ceil(12 + 20 + 8 + textWidth + 12 + 4)
        return CGSize(width: width, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectedIndex != indexPath.item else { return }
        selectedIndex = indexPath.item
        collectionView.reloadData()
        updateUI(for: sportTypes[selectedIndex])
    }
}

// MARK: - 辅助组件
class FeatureButton: UIButton {
    init(title: String, iconName: String) {
        super.init(frame: .zero)
        setupButton(title: title, iconName: iconName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(title: String, iconName: String) {
        let icon = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
        
        setImage(icon, for: .normal)
        setTitle(title, for: .normal)
        setTitleColor(.label, for: .normal)
        imageView?.tintColor = .secondaryLabel
        
        titleLabel?.font = .systemFont(ofSize: 12)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        titleEdgeInsets = UIEdgeInsets(top: 36, left: -imageView!.bounds.width, bottom: 0, right: 0)
        
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 4
        layer.shadowOffset = .zero
    }
}

// MARK: - 运动会话控制器（示例）
class SportSessionViewController: UIViewController {
    private let sportType: SportType
    
    init(sportType: SportType) {
        self.sportType = sportType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "\(sportType.title)中"
        
        // 添加返回按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UIView扩展
extension UIView {
    // 水平方向锚点（leading + trailing）
    var horizontalAnchors: [NSLayoutXAxisAnchor] {
        return [leadingAnchor, trailingAnchor]
    }
    
    // 垂直方向锚点（top + bottom）
    var verticalAnchors: [NSLayoutYAxisAnchor] {
        return [topAnchor, bottomAnchor]
    }

    func constraint(equalTo view: UIView, constant: CGFloat = 0) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -constant),
            topAnchor.constraint(equalTo: view.topAnchor, constant: constant),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant)
        ])
    }
}
