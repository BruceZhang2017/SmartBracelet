import UIKit
import SwiftUI
import MJRefresh
import Alamofire
import Kingfisher
import Toaster

var isUsrEnglish = false // 是否默认使用英文

// MARK: - 主视图控制器
class TripleTableViewController: UIViewController {
    private enum ContentState {
        case hidden
        case loading
        case empty
        case error
    }
    
    // MARK: - 属性
    private let segmentContainerView = UIView()
    private let segmentControl = UISegmentedControl()
    private let leftPanelView = UIView()
    private let middleTableView = UITableView()
    private let dividerView = UIView()
    private let rightCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let stateContainerView = UIView()
    private let stateLoadingIndicator = UIActivityIndicatorView(style: .large)
    private let stateIconView = UIImageView()
    private let stateTitleLabel = UILabel()
    private let stateMessageLabel = UILabel()
    private let stateActionButton = UIButton(type: .system)

    // 记录选中的索引路径
    private var selectedMiddleIndexPath: IndexPath? = IndexPath(row: 0, section: 0)

    private let rightViewModel = RightViewModel()
    private var mResponse: Response<OTAData>?
    var current = 0
    var otaStyle: [OTADictItem] = []

    // MARK: - 视图生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupSegmentControl()
        setupMiddleTableView()
        setupRightCollectionView()
        setupMJRefresh()
        rightCollectionView.isHidden = true
        showLoadingState()
        downloadStyle()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewLayout()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        segmentContainerView.backgroundColor = .secondarySystemBackground
        segmentContainerView.layer.cornerRadius = 14
        segmentContainerView.layer.shadowColor = UIColor.black.cgColor
        segmentContainerView.layer.shadowOpacity = 0.04
        segmentContainerView.layer.shadowRadius = 10
        segmentContainerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        segmentContainerView.layer.borderWidth = 1
        segmentContainerView.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor

        leftPanelView.backgroundColor = .secondarySystemBackground
        leftPanelView.layer.cornerRadius = 14
        leftPanelView.layer.masksToBounds = true

        dividerView.backgroundColor = UIColor.separator.withAlphaComponent(0.35)

        view.addSubview(segmentContainerView)
        segmentContainerView.addSubview(segmentControl)
        view.addSubview(leftPanelView)
        leftPanelView.addSubview(middleTableView)
        view.addSubview(dividerView)
        view.addSubview(rightCollectionView)
        view.addSubview(stateContainerView)

        stateContainerView.backgroundColor = .clear
        stateContainerView.isHidden = true
        stateContainerView.translatesAutoresizingMaskIntoConstraints = false

        stateLoadingIndicator.color = .brand
        stateLoadingIndicator.hidesWhenStopped = true
        stateLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        stateContainerView.addSubview(stateLoadingIndicator)

        stateIconView.tintColor = .secondaryLabel
        stateIconView.contentMode = .scaleAspectFit
        stateIconView.translatesAutoresizingMaskIntoConstraints = false
        stateContainerView.addSubview(stateIconView)

        stateTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        stateTitleLabel.textColor = .label
        stateTitleLabel.textAlignment = .center
        stateTitleLabel.numberOfLines = 0
        stateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stateContainerView.addSubview(stateTitleLabel)

        stateMessageLabel.font = UIFont.systemFont(ofSize: 13)
        stateMessageLabel.textColor = .secondaryLabel
        stateMessageLabel.textAlignment = .center
        stateMessageLabel.numberOfLines = 0
        stateMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        stateContainerView.addSubview(stateMessageLabel)

        stateActionButton.backgroundColor = .brand
        stateActionButton.setTitleColor(.white, for: .normal)
        stateActionButton.layer.cornerRadius = 18
        stateActionButton.layer.masksToBounds = true
        stateActionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        stateActionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        stateActionButton.translatesAutoresizingMaskIntoConstraints = false
        stateActionButton.addTarget(self, action: #selector(handleStateAction), for: .touchUpInside)
        stateContainerView.addSubview(stateActionButton)
    }
    
    private func setupConstraints() {
        segmentContainerView.translatesAutoresizingMaskIntoConstraints = false
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        leftPanelView.translatesAutoresizingMaskIntoConstraints = false
        middleTableView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        rightCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentContainerView.heightAnchor.constraint(equalToConstant: 44),

            segmentControl.topAnchor.constraint(equalTo: segmentContainerView.topAnchor, constant: 4),
            segmentControl.leadingAnchor.constraint(equalTo: segmentContainerView.leadingAnchor, constant: 4),
            segmentControl.trailingAnchor.constraint(equalTo: segmentContainerView.trailingAnchor, constant: -4),
            segmentControl.bottomAnchor.constraint(equalTo: segmentContainerView.bottomAnchor, constant: -4),
            
            leftPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            leftPanelView.topAnchor.constraint(equalTo: segmentContainerView.bottomAnchor, constant: 10),
            leftPanelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            leftPanelView.widthAnchor.constraint(equalToConstant: 154),
            
            middleTableView.topAnchor.constraint(equalTo: leftPanelView.topAnchor, constant: 8),
            middleTableView.leadingAnchor.constraint(equalTo: leftPanelView.leadingAnchor, constant: 6),
            middleTableView.trailingAnchor.constraint(equalTo: leftPanelView.trailingAnchor, constant: -6),
            middleTableView.bottomAnchor.constraint(equalTo: leftPanelView.bottomAnchor, constant: -8),

            dividerView.leadingAnchor.constraint(equalTo: leftPanelView.trailingAnchor, constant: 6),
            dividerView.topAnchor.constraint(equalTo: leftPanelView.topAnchor, constant: 12),
            dividerView.bottomAnchor.constraint(equalTo: leftPanelView.bottomAnchor, constant: -12),
            dividerView.widthAnchor.constraint(equalToConstant: 1),

            rightCollectionView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: 6),
            rightCollectionView.topAnchor.constraint(equalTo: leftPanelView.topAnchor),
            rightCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rightCollectionView.bottomAnchor.constraint(equalTo: leftPanelView.bottomAnchor),

            stateContainerView.leadingAnchor.constraint(equalTo: rightCollectionView.leadingAnchor),
            stateContainerView.topAnchor.constraint(equalTo: rightCollectionView.topAnchor),
            stateContainerView.trailingAnchor.constraint(equalTo: rightCollectionView.trailingAnchor),
            stateContainerView.bottomAnchor.constraint(equalTo: rightCollectionView.bottomAnchor),

            stateLoadingIndicator.centerXAnchor.constraint(equalTo: stateContainerView.centerXAnchor),
            stateLoadingIndicator.centerYAnchor.constraint(equalTo: stateContainerView.centerYAnchor, constant: -44),

            stateIconView.centerXAnchor.constraint(equalTo: stateContainerView.centerXAnchor),
            stateIconView.centerYAnchor.constraint(equalTo: stateContainerView.centerYAnchor, constant: -44),
            stateIconView.widthAnchor.constraint(equalToConstant: 42),
            stateIconView.heightAnchor.constraint(equalToConstant: 42),

            stateTitleLabel.topAnchor.constraint(equalTo: stateIconView.bottomAnchor, constant: 14),
            stateTitleLabel.leadingAnchor.constraint(equalTo: stateContainerView.leadingAnchor, constant: 24),
            stateTitleLabel.trailingAnchor.constraint(equalTo: stateContainerView.trailingAnchor, constant: -24),

            stateMessageLabel.topAnchor.constraint(equalTo: stateTitleLabel.bottomAnchor, constant: 8),
            stateMessageLabel.leadingAnchor.constraint(equalTo: stateContainerView.leadingAnchor, constant: 28),
            stateMessageLabel.trailingAnchor.constraint(equalTo: stateContainerView.trailingAnchor, constant: -28),

            stateActionButton.topAnchor.constraint(equalTo: stateMessageLabel.bottomAnchor, constant: 16),
            stateActionButton.centerXAnchor.constraint(equalTo: stateContainerView.centerXAnchor),
            stateActionButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupSegmentControl() {
        segmentControl.selectedSegmentIndex = 0
        segmentControl.selectedSegmentTintColor = .brand
        segmentControl.backgroundColor = .clear
        segmentControl.apportionsSegmentWidthsByContent = false
        segmentControl.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        updateSegmentTextAttributes(with: [])
        segmentControl.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }

    private func updateSegmentTextAttributes(with titles: [String]) {
        let segmentCount = max(segmentControl.numberOfSegments, titles.count)
        let maxTitleLength = titles.map(\.count).max() ?? 0

        let fontSize: CGFloat
        switch (segmentCount, maxTitleLength) {
        case (5..., _), (_, 12...):
            fontSize = 11
        case (4, _), (_, 9...11):
            fontSize = 12
        default:
            fontSize = 13
        }

        segmentControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ], for: .normal)
        segmentControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: UIColor.white
        ], for: .selected)
    }
    
    private func setupMiddleTableView() {
        middleTableView.delegate = self
        middleTableView.dataSource = self
        middleTableView.register(MiddleCategoryCell.self, forCellReuseIdentifier: "MiddleCell")
        middleTableView.tableFooterView = UIView(frame: .zero)
        middleTableView.allowsSelection = true
        middleTableView.allowsMultipleSelection = false
        middleTableView.backgroundColor = .clear
        middleTableView.separatorStyle = .none
        middleTableView.showsVerticalScrollIndicator = false
        middleTableView.rowHeight = UITableView.automaticDimension
        middleTableView.estimatedRowHeight = 68
    }
    
    private func setupRightCollectionView() {
        // 使用流水布局并强制设置滚动方向为垂直
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        // 实时计算右侧可用宽度（基于collectionView的实际宽度）
        // 先获取右侧区域总宽度 = 屏幕宽度 - 中间表宽度 - 左右间距
        let totalRightWidth = UIScreen.main.bounds.width - 150 - 4 // 150是中间表宽度，4是两边间距(2+2)
        
        // 计算每个item宽度：2列填满容器宽度，无额外列间距
        let itemWidth = totalRightWidth / 2
        let fixedItemWidth = floor(itemWidth)
        let itemHeight = calculateItemHeight(for: nil)
        
        layout.itemSize = CGSize(width: fixedItemWidth, height: itemHeight)
        layout.minimumInteritemSpacing = 0 // 列之间无间距，让预览更紧凑
        layout.minimumLineSpacing = 12 // 行之间的间距
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        rightCollectionView.collectionViewLayout = layout
        
        rightCollectionView.delegate = self
        rightCollectionView.dataSource = self
        rightCollectionView.register(RightCollectionCell.self, forCellWithReuseIdentifier: "RightCollectionCell")
        rightCollectionView.backgroundColor = .clear
        rightCollectionView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)
        
        // 监听布局变化，确保旋转屏幕时也能正确显示2列
        NotificationCenter.default.addObserver(self, selector: #selector(updateCollectionViewLayout), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    private func currentDeviceSize() -> CGSize {
        let screenWidth = CGFloat(XGZTBlueToothManager.shared.device?.screenWidth ?? 0)
        let screenHeight = CGFloat(XGZTBlueToothManager.shared.device?.screenHeight ?? 0)
        if screenWidth > 0 && screenHeight > 0 {
            return CGSize(width: screenWidth, height: screenHeight)
        }
        return CGSize(width: 240, height: 284)
    }

    private func currentDeviceAspectRatio() -> CGFloat {
        let size = currentDeviceSize()
        return size.width > 0 ? size.height / size.width : 1.0
    }

    private func calculateItemHeight(for item: ClockItem?) -> CGFloat {
        let totalWidth = rightCollectionView.bounds.width
        let itemWidth = totalWidth / 2

        let aspectRatio: CGFloat
        if let item = item,
           let width = item.width,
           let height = item.height,
           width > 0,
           height > 0 {
            aspectRatio = CGFloat(height) / CGFloat(width)
        } else {
            aspectRatio = currentDeviceAspectRatio()
        }

        let calculatedHeight = itemWidth * aspectRatio
        return max(120, floor(calculatedHeight))
    }
    
    // 屏幕旋转时更新布局
    @objc private func updateCollectionViewLayout() {
        guard let layout = rightCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let totalRightWidth = rightCollectionView.bounds.width
        let itemWidth = totalRightWidth / 2
        let fixedItemWidth = floor(itemWidth)
        let itemHeight = calculateItemHeight(for: nil)

        layout.itemSize = CGSize(width: fixedItemWidth, height: itemHeight)
        rightCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - 数据处理
    private func downloadStyle() {
        // 打印方法开始日志
        print("🔍 开始执行downloadStyle方法，准备下载样式数据")
        
        // 定义要上传的参数
        let width = XGZTBlueToothManager.shared.device?.screenWidth ?? 240
        let height = XGZTBlueToothManager.shared.device?.screenHeight ?? 284 // 根据实际需求设置的高度值
        
        // 打印请求参数日志
        print("📤 请求参数 - width: \(width), height: \(height)")
        let urlString = "https://u-watch.com.cn/api/app/ota/otaType"
        print("📡 请求URL: \(urlString)")
        
        // 准备表单参数
        let parameters: [String: Any] = [
            "width": width,
            "height": height,
            "deviceType": XGZTBlueToothManager.shared.device?.screenType ?? 0,
        ]
        
        // 使用x-www-form-urlencoded格式发送POST请求
        AF.request(
            urlString,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default // 这是x-www-form-urlencoded的默认编码方式
        )
        .responseData { [weak self] response in
            guard let self = self else {
                print("⚠️ self已释放，无法继续处理响应")
                return
            }
            
            // 打印响应状态码
            if let statusCode = response.response?.statusCode {
                print("📥 收到响应，状态码: \(statusCode)")
            } else {
                print("📥 收到响应，但未获取到状态码")
            }
            
            switch response.result {
            case .success(let data):
                print("✅ 网络请求成功，数据大小: \(data.count) bytes")
                
                // 打印原始JSON用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 原始JSON数据: \(jsonString)")
                } else {
                    print("❌ 无法将响应数据转换为UTF-8字符串")
                }
                
                do {
                    // 禁用蛇形命名转换，使用原始键名
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    print("🔄 开始解析JSON数据...")
                    mResponse = try decoder.decode(Response<OTAData>.self, from: data)
                    print("✅ JSON数据解析成功")
                    if mResponse?.data.otaStyle.count ?? 0 == 0 {
                        isUsrEnglish = true
                        self.downloadStyle()
                        return
                    }
                    // 配置分段控制器
                    if let types = mResponse?.data.otaType, !types.isEmpty {
                        print("📊 共获取到\(types.count)种OTA类型")
                        segmentControl.removeAllSegments()
                        for (index, type) in types.enumerated() {
                            let typeName = NSLocalizedString(type.dictValue ?? "", comment: type.dictValue ?? "")
                            segmentControl.insertSegment(withTitle: typeName, at: index, animated: false)
                            print("➕ 添加分段控制器选项: \(typeName)")
                        }
                        updateSegmentTextAttributes(with: types.map { NSLocalizedString($0.dictValue ?? "", comment: $0.dictValue ?? "") })
                        segmentControl.selectedSegmentIndex = 0
                        rightViewModel.type = types[0].dictValue ?? ""
                    } else {
                        print("⚠️ 未获取到有效的type类型数据")
                    }
                    
                    print("🔄 刷新中间表格视图")
                    if mResponse?.data.otaStyle.count ?? 0 > 0 {
                        let array = mResponse?.data.otaStyle.filter {
                            (item) in
                            if let value = item.value2 {
                                return value.contains(self.rightViewModel.type)
                            } else if let value = item.type {
                                return value.contains(self.rightViewModel.type)
                            } else {
                                return false
                            }
                        } ?? []
                        self.otaStyle = array
                        self.reloadMiddleTableViewWithFade()
                        self.scrollSelectedCategoryToVisible(animated: false)
                        if self.otaStyle.count > 0 {
                            self.rightCollectionView.isHidden = false
                            if let style = otaStyle.first?.dictValue {
                                rightViewModel.style = style
                            } else if let style = otaStyle.first?.style {
                                rightViewModel.style = style
                            }
                            self.fetchInitialData()
                        }
                    } else {
                        self.rightViewModel.items = []
                        self.reloadCollectionViewWithFade()
                        self.showEmptyState()
                    }
                    print("🔄 调用fetchInitialData方法获取初始数据")
                    
                } catch {
                    print("❌ 解析错误: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("❌ 解码错误详情: \(decodingError.localizedDescription)")
                        // 更详细的解码错误信息
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("类型不匹配: 期望\(type)，上下文: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("值未找到: 期望\(type)，上下文: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("键未找到: \(key.stringValue)，上下文: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("数据损坏: \(context.debugDescription)")
                        @unknown default:
                            print("未知解码错误")
                        }
                    }
                    self.showErrorState()
                }
                
            case .failure(let error):
                print("❌ 网络请求失败：\(error.localizedDescription)")
                // 打印更详细的错误信息
                if let underlyingError = error.underlyingError {
                    print("   底层错误: \(underlyingError.localizedDescription)")
                }
                self.showErrorState()
            }
            
            print("📌 downloadStyle方法执行完毕")
        }
    }


    private func handleStyleResponse() {
        self.middleTableView.reloadData()
        self.fetchInitialData()
    }
    
    // MARK: - MJRefresh 设置
    private func setupMJRefresh() {
        let header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.refreshData()
        })
        header.lastUpdatedTimeLabel?.isHidden = true
        header.stateLabel?.textColor = .systemGray
        header.activityIndicatorViewStyle = .medium
        rightCollectionView.mj_header = header
        
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadMoreData()
        })
        footer.stateLabel?.textColor = .systemGray
        footer.isAutomaticallyHidden = true
        rightCollectionView.mj_footer = footer
    }
    
    // MARK: - 数据获取
    private func fetchInitialData() {
        if rightViewModel.items.isEmpty {
            showLoadingState()
        }
        rightCollectionView.mj_header?.beginRefreshing()
        //refreshData()
    }
    
    @objc private func refreshData() {
        if rightViewModel.style.count == 0 {
            return
        }
        rightViewModel.refreshData { [weak self] success in
            DispatchQueue.main.async {
                self?.updateCollectionViewAfterRefresh(success: success)
            }
        }
    }
    
    @objc private func loadMoreData() {
        guard !rightViewModel.isLoading, rightViewModel.hasMoreData else {
            rightCollectionView.mj_footer?.endRefreshing()
            return
        }
        
        rightViewModel.loadMoreData { [weak self] success in
            DispatchQueue.main.async {
                self?.updateCollectionViewAfterLoadMore(success: success)
            }
        }
    }
    
    // MARK: - 辅助方法
    private func updateCollectionViewAfterRefresh(success: Bool) {
        reloadCollectionViewWithFade()
        rightCollectionView.mj_header?.endRefreshing()
        
        if success {
            if rightViewModel.items.isEmpty {
                showEmptyState()
                rightCollectionView.mj_footer?.endRefreshingWithNoMoreData()
            } else {
                hideEmptyState()
                rightCollectionView.mj_footer?.resetNoMoreData()
            }
        } else {
            showErrorState()
        }
    }
    
    private func updateCollectionViewAfterLoadMore(success: Bool) {
        reloadCollectionViewWithFade()
        
        if success, rightViewModel.hasMoreData {
            rightCollectionView.mj_footer?.endRefreshing()
        } else if success {
            rightCollectionView.mj_footer?.endRefreshingWithNoMoreData()
        } else {
            rightCollectionView.mj_footer?.endRefreshing()
            showErrorState()
        }
    }
    
    private func showEmptyState() {
        applyContentState(.empty)
    }
    
    private func hideEmptyState() {
        applyContentState(.hidden)
    }

    private func showLoadingState() {
        applyContentState(.loading)
    }
    
    private func showErrorState() {
        applyContentState(.error)
    }

    private func reloadCollectionViewWithFade() {
        UIView.transition(with: rightCollectionView, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.rightCollectionView.reloadData()
        })
    }

    private func reloadMiddleTableViewWithFade() {
        UIView.transition(with: middleTableView, duration: 0.18, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.middleTableView.reloadData()
        })
    }

    private func scrollSelectedCategoryToVisible(animated: Bool) {
        guard let indexPath = selectedMiddleIndexPath,
              otaStyle.indices.contains(indexPath.row) else { return }
        DispatchQueue.main.async {
            self.middleTableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }
    }

    private func resetCollectionViewToTop(animated: Bool) {
        let topOffset = CGPoint(x: 0, y: -rightCollectionView.adjustedContentInset.top)
        guard rightCollectionView.contentOffset.y > topOffset.y else { return }
        rightCollectionView.setContentOffset(topOffset, animated: animated)
    }

    private func setStateContainerVisible(_ visible: Bool, animated: Bool = true) {
        let animations = {
            self.stateContainerView.alpha = visible ? 1 : 0
        }

        if visible {
            if stateContainerView.isHidden {
                stateContainerView.alpha = 0
                stateContainerView.isHidden = false
            }
            if animated {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: animations)
            } else {
                animations()
            }
        } else {
            let completion: (Bool) -> Void = { _ in
                self.stateContainerView.isHidden = true
            }
            if animated {
                UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: animations, completion: completion)
            } else {
                animations()
                completion(true)
            }
        }
    }

    private func applyContentState(_ state: ContentState) {
        switch state {
        case .hidden:
            setStateContainerVisible(false)
            stateLoadingIndicator.stopAnimating()
            stateIconView.isHidden = false
            stateTitleLabel.isHidden = false
            stateMessageLabel.isHidden = false
            stateActionButton.isHidden = true
        case .loading:
            setStateContainerVisible(true)
            stateLoadingIndicator.startAnimating()
            stateIconView.isHidden = true
            stateTitleLabel.isHidden = false
            stateMessageLabel.isHidden = false
            stateActionButton.isHidden = true
            stateTitleLabel.text = NSLocalizedString("加载中", comment: "")
            stateMessageLabel.text = NSLocalizedString("正在获取表盘内容，请稍候。", comment: "")
        case .empty:
            setStateContainerVisible(true)
            stateLoadingIndicator.stopAnimating()
            stateIconView.isHidden = false
            stateTitleLabel.isHidden = false
            stateMessageLabel.isHidden = false
            stateIconView.image = UIImage(systemName: "square.grid.2x2")
            stateTitleLabel.text = NSLocalizedString("暂无表盘", comment: "")
            stateMessageLabel.text = NSLocalizedString("当前分类下还没有可用内容，请切换其他分类看看。", comment: "")
            stateActionButton.isHidden = true
        case .error:
            setStateContainerVisible(true)
            stateLoadingIndicator.stopAnimating()
            stateIconView.isHidden = false
            stateTitleLabel.isHidden = false
            stateMessageLabel.isHidden = false
            stateIconView.image = UIImage(systemName: "wifi.exclamationmark")
            stateTitleLabel.text = NSLocalizedString("加载失败", comment: "")
            stateMessageLabel.text = NSLocalizedString("网络异常或服务暂不可用，请稍后重试。", comment: "")
            stateActionButton.isHidden = false
            stateActionButton.setTitle(NSLocalizedString("重试", comment: ""), for: .normal)
        }
    }

    @objc private func handleStateAction() {
        showLoadingState()
        if rightViewModel.style.isEmpty {
            downloadStyle()
        } else {
            fetchInitialData()
        }
    }
    
    // 分段控制器值变化
    @objc private func segmentValueChanged() {
        let selectedIndex = segmentControl.selectedSegmentIndex
        guard let types = mResponse?.data.otaType,
              selectedIndex < types.count else { return }

        rightViewModel.type = types[selectedIndex].dictValue ?? ""
        let array = mResponse?.data.otaStyle.filter {
            (item) in
            if let value = item.value2 {
                return value.contains(rightViewModel.type)
            } else if let value = item.type {
                return value.contains(self.rightViewModel.type)
            } else {
                return false
            }
        } ?? []
        otaStyle = array
        if otaStyle.count > 0 {
            if let style = otaStyle.first?.dictValue {
                rightViewModel.style = style
            } else if let style = otaStyle.first?.style {
                rightViewModel.style = style
            }
            resetCollectionViewToTop(animated: false)
            showLoadingState()
            fetchInitialData()
        } else {
            rightViewModel.items = []
            reloadCollectionViewWithFade()
            showEmptyState()
        }
        selectedMiddleIndexPath = IndexPath(row: 0, section: 0)
        reloadMiddleTableViewWithFade()
        scrollSelectedCategoryToVisible(animated: true)
    }
    
    // 更新选中状态
    private func updateMiddleSelection(at indexPath: IndexPath) {
        if let previousIndexPath = selectedMiddleIndexPath {
            middleTableView.deselectRow(at: previousIndexPath, animated: true)
            if let cell = middleTableView.cellForRow(at: previousIndexPath) {
                cell.backgroundColor = .clear
            }
        }
        selectedMiddleIndexPath = indexPath
        if let style = otaStyle[indexPath.row].dictValue {
            rightViewModel.style = style
        } else if let style = otaStyle[indexPath.row].style {
            rightViewModel.style = style
        }
        resetCollectionViewToTop(animated: true)
        fetchInitialData()
        reloadMiddleTableViewWithFade()
        scrollSelectedCategoryToVisible(animated: true)
    }
    
    deinit {
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TripleTableViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if rightViewModel.type.count == 0 {
            return 0
        }
        return otaStyle.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MiddleCell", for: indexPath) as! MiddleCategoryCell
        let styleItem = otaStyle[indexPath.row]
        let title: String

        if let style = styleItem.dictValue {
            title = style
        } else if let style = styleItem.style {
            title = style
        } else {
            title = ""
        }
        cell.configure(title: title, selected: selectedMiddleIndexPath == indexPath, animated: true)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateMiddleSelection(at: indexPath)
    }
}

class MiddleCategoryCell: UITableViewCell {
    private let selectedBackgroundCard = UIView()
    private let indicatorView = UIView()
    private let titleLabel = UILabel()
    private let shadowContainerView = UIView()
    private var cardTopConstraint: NSLayoutConstraint?
    private var cardBottomConstraint: NSLayoutConstraint?
    private var titleTopConstraint: NSLayoutConstraint?
    private var titleBottomConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        shadowContainerView.backgroundColor = .clear
        shadowContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowContainerView)

        selectedBackgroundCard.layer.cornerRadius = 12
        selectedBackgroundCard.layer.masksToBounds = true
        selectedBackgroundCard.translatesAutoresizingMaskIntoConstraints = false
        shadowContainerView.addSubview(selectedBackgroundCard)

        indicatorView.layer.cornerRadius = 2
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        selectedBackgroundCard.addSubview(indicatorView)

        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.allowsDefaultTighteningForTruncation = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedBackgroundCard.addSubview(titleLabel)

        cardTopConstraint = selectedBackgroundCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4)
        cardBottomConstraint = selectedBackgroundCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: selectedBackgroundCard.topAnchor, constant: 10)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: selectedBackgroundCard.bottomAnchor, constant: -10)

        NSLayoutConstraint.activate([
            shadowContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            shadowContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            shadowContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            shadowContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),

            cardTopConstraint!,
            selectedBackgroundCard.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            selectedBackgroundCard.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            cardBottomConstraint!,

            indicatorView.leadingAnchor.constraint(equalTo: selectedBackgroundCard.leadingAnchor, constant: 8),
            indicatorView.centerYAnchor.constraint(equalTo: selectedBackgroundCard.centerYAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 4),
            indicatorView.heightAnchor.constraint(equalToConstant: 26),

            titleTopConstraint!,
            titleLabel.leadingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: selectedBackgroundCard.trailingAnchor, constant: -8),
            titleBottomConstraint!
        ])
    }

    func configure(title: String, selected: Bool, animated: Bool = false) {
        let isLongTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).count > 18
        titleLabel.text = title
        let fontSize = preferredFontSize(for: title)
        titleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: selected ? .semibold : .medium)
        cardTopConstraint?.constant = isLongTitle ? 3 : 4
        cardBottomConstraint?.constant = isLongTitle ? -3 : -4
        titleTopConstraint?.constant = isLongTitle ? 8 : 10
        titleBottomConstraint?.constant = isLongTitle ? -8 : -10

        let applyStyleChanges = {
            self.titleLabel.textColor = selected ? .brand : .secondaryLabel
            self.selectedBackgroundCard.backgroundColor = selected ? UIColor.brand.withAlphaComponent(0.12) : UIColor.tertiarySystemBackground.withAlphaComponent(0.55)
            self.selectedBackgroundCard.layer.borderWidth = selected ? 0 : 1
            self.selectedBackgroundCard.layer.borderColor = selected ? UIColor.clear.cgColor : UIColor.separator.withAlphaComponent(0.2).cgColor
            self.indicatorView.backgroundColor = selected ? .brand : UIColor.clear
            self.indicatorView.transform = selected ? .identity : CGAffineTransform(scaleX: 0.35, y: 0.7)
            self.indicatorView.alpha = selected ? 1 : 0
            self.shadowContainerView.layer.shadowColor = UIColor.black.cgColor
            self.shadowContainerView.layer.shadowOpacity = selected ? 0.08 : 0
            self.shadowContainerView.layer.shadowRadius = selected ? 8 : 0
            self.shadowContainerView.layer.shadowOffset = CGSize(width: 0, height: selected ? 4 : 0)
            self.shadowContainerView.layer.cornerRadius = 12
            self.contentView.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: applyStyleChanges)
        } else {
            applyStyleChanges()
        }
    }

    private func preferredFontSize(for title: String) -> CGFloat {
        let characterCount = title.trimmingCharacters(in: .whitespacesAndNewlines).count
        switch characterCount {
        case 0...10:
            return 14
        case 11...18:
            return 13
        default:
            return 12
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension TripleTableViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 实现代理方法，确保布局正确
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let itemWidth = totalWidth / 2
        guard indexPath.row < rightViewModel.items.count else {
            return CGSize(width: floor(itemWidth), height: 0)
        }
        let item = rightViewModel.items[indexPath.row]
        let itemHeight = calculateItemHeight(for: item)
        return CGSize(width: floor(itemWidth), height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rightViewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RightCollectionCell", for: indexPath) as! RightCollectionCell
        guard indexPath.row < rightViewModel.items.count else {
            return cell
        }
        let item = rightViewModel.items[indexPath.row]
        cell.configure(with: item)
        cell.tag = indexPath.row
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < rightViewModel.items.count else {
            return
        }
        let item = rightViewModel.items[indexPath.row]
        let pushDetail: () -> Void = {
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ClockUseViewController") as? ClockUseViewController
            vc?.index = indexPath.row + 1 // 代表什么含义
            vc?.current = self.current
            vc?.currentClock = ClockResponse(previewPic: item.previewImageUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), resourcesUrl: item.dialBinUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), resolutionRatio: "\(item.width ?? 0)*\(item.height ?? 0)", isPublish: "true")
            self.parent?.navigationController?.pushViewController(vc!, animated: true)
        }

        if let cell = collectionView.cellForItem(at: indexPath) as? RightCollectionCell {
            cell.playSelectionAnimation(completion: pushDetail)
        } else {
            pushDetail()
        }
    }
}

// MARK: - 集合视图单元格
class RightCollectionCell: UICollectionViewCell {
    private let shadowView = UIView()
    private let cardView = UIView()
    private let placeholderView = UIView()
    private let itemImageView = UIImageView()
    private let placeholderIconView = UIImageView()
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18) {
                self.shadowView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.shadowView.layer.shadowOpacity = self.isHighlighted ? 0.04 : 0.10
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layer.cornerRadius = 14
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.10
        shadowView.layer.shadowRadius = 10
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(shadowView)

        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.addSubview(cardView)

        placeholderView.backgroundColor = UIColor.tertiarySystemFill
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(placeholderView)

        placeholderIconView.image = UIImage(systemName: "applewatch.watchface")
        placeholderIconView.tintColor = .secondaryLabel
        placeholderIconView.contentMode = .scaleAspectFit
        placeholderIconView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.addSubview(placeholderIconView)

        itemImageView.contentMode = .scaleAspectFill
        itemImageView.clipsToBounds = true
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(itemImageView)
        
        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            shadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            cardView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),

            placeholderView.topAnchor.constraint(equalTo: cardView.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            placeholderIconView.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            placeholderIconView.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor),
            placeholderIconView.widthAnchor.constraint(equalToConstant: 32),
            placeholderIconView.heightAnchor.constraint(equalToConstant: 32),

            itemImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 2),
            itemImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 2),
            itemImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -2),
            itemImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -2)
        ])
    }
    
    func configure(with item: ClockItem) {
        itemImageView.kf.cancelDownloadTask() // 取消之前的任务
        itemImageView.alpha = 0
        itemImageView.image = nil
        placeholderView.isHidden = false
        
        guard let urlString = item.previewImageUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let imageUrl = URL(string: urlString) else {
            XLogger.shared.log("图片URL无效或为空: \(item.previewImageUrl ?? "nil")")
            return
        }
        // 使用Kingfisher加载图片并处理结果
        itemImageView.kf.setImage(with: imageUrl, options: [.forceRefresh]) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.placeholderView.isHidden = true
                UIView.animate(withDuration: 0.2) {
                    self.itemImageView.alpha = 1
                }
            case .failure(let error):
                // 打印详细的错误信息
                XLogger.shared.log("图片加载失败 - URL: \(urlString), 原因: \(error.localizedDescription)")
                self.itemImageView.alpha = 0
                self.placeholderView.isHidden = false
            }
        }
    }

    func playSelectionAnimation(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.shadowView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.shadowView.layer.shadowOpacity = 0.04
        }) { _ in
            UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.shadowView.transform = .identity
                self.shadowView.layer.shadowOpacity = 0.10
            }) { _ in
                completion()
            }
        }
    }
}

// MARK: - 视图模型
class RightViewModel {
    var items: [ClockItem] = []
    var currentPage = 0
    var isLoading = false
    var hasMoreData = true
    var type = ""
    var style = ""
    
    func refreshData(completion: @escaping (Bool) -> Void) {
        let screenWidth = XGZTBlueToothManager.shared.device?.screenWidth ?? 240
        let screenHeight = XGZTBlueToothManager.shared.device?.screenHeight ?? 284
        
        let urlString = "https://u-watch.com.cn/api/app/ota/v3/list"
        
        // 构建请求参数字典
        let parameters: [String: Any] = [
            "pageSize": 20,
            "pageNum": 0,
            "width": screenWidth,
            "height": screenHeight,
            "deviceType": XGZTBlueToothManager.shared.device?.screenType ?? 0,
            "type": type,
            "style": style
        ]
        
        // 打印请求参数
        print("请求参数:")
        parameters.forEach { print("\($0.key): \($0.value)") }
        
        // 使用AF.request发送POST请求，采用x-www-form-urlencoded编码
        AF.request(
            urlString,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default // 明确使用x-www-form-urlencoded编码
        )
        .responseData { [weak self] response in
            guard let self = self else { return }
            
            switch response.result {
            case .success(let data):
                // 打印原始响应数据
                if let responseString = String(data: data, encoding: .utf8) {
                    print("网络请求返回内容：\n\(responseString)")
                } else {
                    print("网络请求返回数据无法转换为字符串")
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let model = try decoder.decode(ClocksResponse.self, from: data)
                    self.items = model.rows
                    self.currentPage = 0
                    self.hasMoreData = model.rows.count >= 20
                    completion(true)
                } catch {
                    print("刷新数据解析错误: \(error)")
                    completion(false)
                }
                
            case .failure(let error):
                print("刷新网络请求失败：\(error)")
                completion(false)
            }
        }
    }
    
    func loadMoreData(completion: @escaping (Bool) -> Void) {
        guard !isLoading, hasMoreData else {
            print("无需加载更多数据：isLoading=\(isLoading), hasMoreData=\(hasMoreData)")
            completion(false)
            return
        }
        
        isLoading = true
        let nextPage = currentPage + 1
        let screenWidth = XGZTBlueToothManager.shared.device?.screenWidth ?? 240
        let screenHeight = XGZTBlueToothManager.shared.device?.screenHeight ?? 284
        
        let urlString = "https://u-watch.com.cn/api/app/ota/v3/list"
        
        // 构建请求参数字典
        let parameters: [String: Any] = [
            "pageSize": 20,
            "pageNum": nextPage,
            "width": screenWidth,
            "height": screenHeight,
            "deviceType": XGZTBlueToothManager.shared.device?.screenType ?? 0,
            "type": type,
            "style": style
        ]
        // 打印请求参数
        print("开始加载第\(nextPage)页数据，请求参数：")
        parameters.forEach { print("\($0.key): \($0.value)") }
        
        // 使用AF.request发送POST请求，采用x-www-form-urlencoded编码
        AF.request(
            urlString,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default // x-www-form-urlencoded编码
        )
        .responseData { [weak self] response in
            guard let self = self else { return }
            self.isLoading = false
            
            // 打印响应状态
            print("请求完成，状态码：\(response.response?.statusCode ?? -1)")
            
            switch response.result {
            case .success(let data):
                // 打印原始响应数据
                if let responseString = String(data: data, encoding: .utf8) {
                    print("网络请求返回内容：\n\(responseString)")
                } else {
                    print("网络请求返回数据无法转换为字符串")
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let model = try decoder.decode(ClocksResponse.self, from: data)
                    self.items.append(contentsOf: model.rows)
                    self.currentPage = nextPage
                    self.hasMoreData = model.rows.count >= 20
                    print("加载成功，新增\(model.rows.count)条数据，当前总数据量：\(self.items.count)")
                    completion(true)
                } catch {
                    print("加载更多解析错误: \(error)")
                    // 打印错误时的原始数据，便于调试
                    if let errorDataString = String(data: data, encoding: .utf8) {
                        print("解析错误时的原始数据：\(errorDataString)")
                    }
                    completion(false)
                }
                
            case .failure(let error):
                print("加载更多网络请求失败：\(error)")
                // 打印Alamofire错误详情
                if let underlyingError = error.underlyingError {
                    print("底层错误：\(underlyingError)")
                }
                completion(false)
            }
        }
    }
}

// MARK: - 数据模型

struct ClocksResponse: Codable {
    let total: Int
    let rows: [ClockItem]
    let code: Int
    let msg: String?
}

struct ClockItem: Codable {
    let searchValue: String?
    let createBy: String?
    let createTime: String?
    let updateBy: String?
    let updateTime: String?
    let remark: String?
    let id: Int
    let uuId: String?
    let otaName: String?
    let dialBin: String?
    let dialBinUrl: String?
    let previewImage: String?
    let previewImageUrl: String?
    let width: Int?
    let height: Int?
    let shape: String?
    let type: String?
    let style: String?
    let tags: String?
    let timePosition: String?
    let downNum: Int?
    let gmtCreate: String?
    let gmtUpdate: String?
}

struct Response<T: Codable>: Codable {
    let msg: String
    let code: Int
    var data: T
}

// 关键修复：调整OTAData的编码键映射
struct OTAData: Codable {
    let otaType: [OTADictItem]
    let otaStyle: [OTADictItem]
    
    // 明确指定JSON键名，与服务器返回保持一致
    enum CodingKeys: String, CodingKey {
        case otaType = "ota_type"
        case otaStyle = "ota_style"
    }
}

struct OTADictItem: Codable {
    let searchValue: String?
    let createBy: String?
    let createTime: String?
    let updateBy: String?
    let updateTime: String?
    let remark: String?
    let params: [String: AnyCodable]?
    let id: Int?
    let uuId: String?
    let otaName: String?
    let dialBin: String?
    let dialBinUrl: String?
    let previewImage: String?
    let previewImageUrl: String?
    let width: Int?
    let height: Int?
    let shape: String?
    let type: String?
    let style: String?
    let tags: String?
    let timePosition: String?
    let downNum: Int?
    let isTop: Int?
    let lang: String?
    let gmtCreate: String?
    let gmtUpdate: String?

    // 原有字段
    let dictCode: Int?
    let dictSort: Int?
    let dictLabel: String?
    let dictValue: String?
    let dictType: String?
    let cssClass: String?
    let listClass: String?
    let isDefault: String?
    let status: String?
    let defaultFlag: Bool?
    let value2: String?

    // 多语言 style 字段
    let styleChineseSim: String?
    let styleItalian: String?
    let styleSpanish: String?
    let stylePortuguese: String?
    let styleRussian: String?
    let styleJapanese: String?
    let styleGerman: String?
    let styleThai: String?
    let styleArabic: String?
    let styleTurkish: String?
    let styleFrench: String?
    let styleVietnamese: String?
    let stylePolish: String?
    let styleDutch: String?
    let styleHebrew: String?
    let stylePersian: String?
    let styleGreek: String?
    let styleMalay: String?
    let styleDanish: String?
    let styleSwedish: String?
    let styleIndonesian: String?
    let styleCzech: String?
    let styleHungarian: String?
    let styleRomanian: String?
    let styleBulgarian: String?
    let styleCroatian: String?
    let styleSlovak: String?
    let styleSlovenian: String?
    let styleLatvian: String?
    let styleLithuanian: String?
    let styleFinnish: String?
    let styleNorwegian: String?
    let styleEstonian: String?
    let styleIcelandic: String?

    enum CodingKeys: String, CodingKey {
        case searchValue, createBy, createTime, updateBy, updateTime, remark
        case params
        case id, uuId, otaName, dialBin, dialBinUrl
        case previewImage, previewImageUrl
        case width, height, shape, type, style, tags, timePosition
        case downNum, isTop, lang, gmtCreate, gmtUpdate
        case dictCode, dictSort, dictLabel, dictValue, dictType, cssClass, listClass
        case isDefault, status
        case defaultFlag = "default"
        case value2
        case styleChineseSim, styleItalian, styleSpanish, stylePortuguese
        case styleRussian, styleJapanese, styleGerman, styleThai
        case styleArabic, styleTurkish, styleFrench, styleVietnamese
        case stylePolish, styleDutch, styleHebrew, stylePersian
        case styleGreek, styleMalay, styleDanish, styleSwedish
        case styleIndonesian, styleCzech, styleHungarian, styleRomanian
        case styleBulgarian, styleCroatian, styleSlovak, styleSlovenian
        case styleLatvian, styleLithuanian, styleFinnish, styleNorwegian
        case styleEstonian, styleIcelandic
    }
}

// 简化AnyCodable实现，提高兼容性
struct AnyCodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法解码为AnyCodable")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let bool as Bool:
            try container.encode(bool)
        case let double as Double:
            try container.encode(double)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "不支持的类型"))
        }
    }
}

/// 语种工具类：统一管理接口lang字段的赋值逻辑
class LanguageManager {
    /// 获取接口需要的lang字段值（自动适配系统语言，兼容iOS 13+）
    static func getInterfaceLang() -> String {
        // 获取设备首选语言（iOS系统返回格式如"zh-Hans-CN"、"en-US"、"ja-JP"等）
        let preferredLang = Locale.preferredLanguages.first ?? "en"
        let locale = Locale(identifier: preferredLang)
        
        // 1. 兼容获取语言码（iOS 13+通用）
        let langCode: String
        if #available(iOS 16, *) {
            langCode = locale.language.languageCode?.identifier ?? "en"
        } else {
            // iOS 13-15：使用旧版API获取语言码
            langCode = locale.languageCode ?? "en"
        }
        
        // 2. 映射iOS语言码到接口要求的lang字段值
        switch langCode {
        case "zh":
            // 区分简体/繁体中文（兼容iOS 13+）
            let scriptCode: String?
            if #available(iOS 16, *) {
                scriptCode = locale.language.script?.identifier
            } else {
                // iOS 13-15：从语言标识字符串中解析脚本类型（zh-Hans -> Hans，zh-Hant -> Hant）
                scriptCode = parseScriptCode(from: preferredLang)
            }
            return scriptCode == "Hant" ? "Chinese_tra" : "Chinese_sim"

        case "ja":
            return "Japanese"

        case "en":
            // 区分美式/英式英语（兼容iOS 13+）
            let regionCode = locale.regionCode
            return regionCode == "GB" ? "English" : "English"

        case "pt":
            // 区分巴西葡语/欧洲葡语（兼容iOS 13+）
            let regionCode = locale.regionCode
            return regionCode == "BR" ? "Portuguese" : "Portuguese"

        case "ko":
            return "Korean"
        case "fr":
            return "French"
        case "de":
            return "German"
        case "es":
            // 区分西班牙语（西班牙/墨西哥）
            let regionCode = locale.regionCode
            return regionCode == "MX" ? "Spanish_mx" : "Spanish"
        case "ru":
            return "Russian"
        case "ar":
            return "Arabic"
        case "it":
            return "Italian"
        case "nl":
            return "Dutch"
        case "th":
            return "Thai"
        case "vi":
            return "Vietnamese"
        case "id":
            return "Indonesian"
        case "ms":
            return "Malay"
        case "tr":
            return "Turkish"
        case "pl":
            return "Polish"
        case "he":
            return "Hebrew"
        case "fa":
            return "Persian"
        case "el":
            return "Greek"
        case "da":
            return "Danish"
        case "sv":
            return "Swedish"
        case "cs":
            return "Czech"
        case "hu":
            return "Hungarian"
        case "ro":
            return "Romanian"
        case "bg":
            return "Bulgarian"
        case "hr":
            return "Croatian"
        case "sk":
            return "Slovak"
        case "sl":
            return "Slovenian"
        case "lv":
            return "Latvian"
        case "lt":
            return "Lithuanian"
        case "fi":
            return "Finnish"
        case "nb", "nn", "no":
            return "Norwegian"
        case "et":
            return "Estonian"
        case "is":
            return "Icelandic"
        case "uk":
            return "Ukrainian"

        default:
            // 未匹配的语言默认返回英语
            return "English"
        }
    }
    
    /// 手动指定语种获取lang字段值（适用于用户手动切换语言的场景）
    /// - Parameter language: 自定义语种枚举
    /// - Returns: 接口需要的lang字段值
    static func getInterfaceLang(by language: CustomLanguage) -> String {
        switch language {
        case .simplifiedChinese: return "Chinese_sim"
        case .traditionalChinese: return "Chinese_tra"
        case .english: return "English"
        case .englishUS: return "English"
        case .englishUK: return "English"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .german: return "German"
        case .french: return "French"
        case .spanish: return "Spanish"
        case .spanishMX: return "Spanish_mx"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .portugueseBR: return "Portuguese"
        case .portuguesePT: return "Portuguese"
        case .russian: return "Russian"
        case .arabic: return "Arabic"
        case .turkish: return "Turkish"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .indonesian: return "Indonesian"
        case .malay: return "Malay"
        case .dutch: return "Dutch"
        case .polish: return "Polish"
        case .hebrew: return "Hebrew"
        case .persian: return "Persian"
        case .greek: return "Greek"
        case .danish: return "Danish"
        case .swedish: return "Swedish"
        case .czech: return "Czech"
        case .hungarian: return "Hungarian"
        case .romanian: return "Romanian"
        case .bulgarian: return "Bulgarian"
        case .croatian: return "Croatian"
        case .slovak: return "Slovak"
        case .slovenian: return "Slovenian"
        case .latvian: return "Latvian"
        case .lithuanian: return "Lithuanian"
        case .finnish: return "Finnish"
        case .norwegian: return "Norwegian"
        case .estonian: return "Estonian"
        case .icelandic: return "Icelandic"
        case .ukrainian: return "Ukrainian"
        }
    }
    
    // MARK: - 私有工具方法
    /// 解析语言标识中的脚本类型（兼容iOS 13-15）
    /// - Parameter langIdentifier: 系统语言标识（如zh-Hans-CN、zh-Hant-TW）
    /// - Returns: 脚本码（Hans/Hant）
    private static func parseScriptCode(from langIdentifier: String) -> String? {
        let components = langIdentifier.components(separatedBy: "-")
        // 语言标识格式：语言码-脚本码-地区码（如zh-Hans-CN） 或 语言码-地区码（如en-US）
        if components.count >= 2 {
            let secondComponent = components[1]
            if secondComponent == "Hans" || secondComponent == "Hant" {
                return secondComponent
            }
        }
        // 默认返回简体（适配无脚本码的中文标识，如zh-CN）
        return "Hans"
    }
    
    /// 自定义语种枚举（适配用户手动切换语言的场景）
    enum CustomLanguage {
        case simplifiedChinese      // 简体中文
        case traditionalChinese     // 繁体中文
        case english                // 英语
        case englishUS              // 美式英语
        case englishUK              // 英式英语
        case japanese               // 日语
        case korean                 // 韩语
        case german                 // 德语
        case french                 // 法语
        case spanish                // 西班牙语
        case spanishMX              // 墨西哥西班牙语
        case italian                // 意大利语
        case portuguese             // 葡萄牙语
        case portugueseBR           // 巴西葡萄牙语
        case portuguesePT           // 欧洲葡萄牙语
        case russian                // 俄语
        case arabic                 // 阿拉伯语
        case turkish                // 土耳其语
        case thai                   // 泰语
        case vietnamese             // 越南语
        case indonesian             // 印度尼西亚语
        case malay                  // 马来语
        case dutch                  // 荷兰语
        case polish                 // 波兰语
        case hebrew                 // 希伯来语
        case persian                // 波斯语
        case greek                  // 希腊语
        case danish                 // 丹麦语
        case swedish                // 瑞典语
        case czech                  // 捷克语
        case hungarian              // 匈牙利语
        case romanian               // 罗马尼亚语
        case bulgarian              // 保加利亚语
        case croatian               // 克罗地亚语
        case slovak                 // 斯洛伐克语
        case slovenian              // 斯洛文尼亚语
        case latvian                // 拉脱维亚语
        case lithuanian             // 立陶宛语
        case finnish                // 芬兰语
        case norwegian              // 挪威语
        case estonian               // 爱沙尼亚语
        case icelandic              // 冰岛语
        case ukrainian              // 乌克兰语
    }
}
