import UIKit
import SwiftUI
import MJRefresh
import Alamofire
import Kingfisher
import Toaster
import Translation

var isUsrEnglish = false // 是否默认使用英文

// MARK: - 主视图控制器
class TripleTableViewController: UIViewController {
    
    // MARK: - 属性
    private let segmentControl = UISegmentedControl()
    private let middleTableView = UITableView()
    private let rightCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    // 记录选中的索引路径
    private var selectedMiddleIndexPath: IndexPath? = IndexPath(row: 0, section: 0)

    private let rightViewModel = RightViewModel()
    private var mResponse: Response<OTAData>?
    var current = 0
    var otaStyle: [OTADictItem] = []

    // 翻译缓存：原文 -> 译文
    private var translationCache: [String: String] = [:]
    // 待翻译的文本队列
    private var pendingTranslations: Set<String> = []
    // 翻译任务是否正在进行
    private var isTranslating = false
    
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
        downloadStyle()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(segmentControl)
        view.addSubview(middleTableView)
        view.addSubview(rightCollectionView)
    }
    
    private func setupConstraints() {
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        middleTableView.translatesAutoresizingMaskIntoConstraints = false
        rightCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 分段控制器约束
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),
            
            // 中间表格视图约束
            middleTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            middleTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            middleTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            middleTableView.widthAnchor.constraint(equalToConstant: 150),
            
            // 右侧集合视图约束
            rightCollectionView.leadingAnchor.constraint(equalTo: middleTableView.trailingAnchor, constant: 2),
            rightCollectionView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            rightCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
            rightCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupSegmentControl() {
        segmentControl.selectedSegmentIndex = 0
        segmentControl.selectedSegmentTintColor = .systemBlue
        segmentControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14)], for: .normal)
        segmentControl.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }
    
    private func setupMiddleTableView() {
        middleTableView.delegate = self
        middleTableView.dataSource = self
        middleTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MiddleCell")
        middleTableView.tableFooterView = UIView()
        middleTableView.allowsSelection = true
        middleTableView.allowsMultipleSelection = false
        // 支持自动行高以适应两行文字
        middleTableView.rowHeight = UITableView.automaticDimension
        middleTableView.estimatedRowHeight = 60
    }
    
    private func setupRightCollectionView() {
        // 使用流水布局并强制设置滚动方向为垂直
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        // 实时计算右侧可用宽度（基于collectionView的实际宽度）
        // 先获取右侧区域总宽度 = 屏幕宽度 - 中间表宽度 - 左右间距
        let totalRightWidth = UIScreen.main.bounds.width - 150 - 4 // 150是中间表宽度，4是两边间距(2+2)
        
        // 计算每个item宽度：减去列间距(8)后平分给2个item
        let itemWidth = (totalRightWidth - 8) / 2
        
        // 确保item宽度为整数，避免布局异常
        let fixedItemWidth = floor(itemWidth)
        
        layout.itemSize = CGSize(width: fixedItemWidth, height: 140)
        layout.minimumInteritemSpacing = 8 // 列之间的间距
        layout.minimumLineSpacing = 12 // 行之间的间距
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0) // 移除额外内边距
        
        rightCollectionView.collectionViewLayout = layout
        
        rightCollectionView.delegate = self
        rightCollectionView.dataSource = self
        rightCollectionView.register(RightCollectionCell.self, forCellWithReuseIdentifier: "RightCollectionCell")
        rightCollectionView.backgroundColor = .systemBackground
        
        // 监听布局变化，确保旋转屏幕时也能正确显示2列
        NotificationCenter.default.addObserver(self, selector: #selector(updateCollectionViewLayout), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // 屏幕旋转时更新布局
    @objc private func updateCollectionViewLayout() {
        guard let layout = rightCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let totalRightWidth = rightCollectionView.bounds.width
        let itemWidth = (totalRightWidth - 8) / 2
        let fixedItemWidth = floor(itemWidth)
        
        layout.itemSize = CGSize(width: fixedItemWidth, height: 140)
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
        var parameters: [String: Any] = [
            "width": width,
            "height": height
        ]
//        let lang = LanguageManager.getInterfaceLang()
//        if lang != "English" && !isUsrEnglish {
//            parameters["lang"] = lang
//        }
        
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
                        segmentControl.selectedSegmentIndex = 0
                        rightViewModel.type = types[0].dictValue ?? ""
                    } else {
                        print("⚠️ 未获取到有效的type类型数据")
                    }
                    
                    print("🔄 刷新中间表格视图")
                    if mResponse?.data.otaStyle.count ?? 0 > 0 {
                        // 清空翻译缓存，因为数据源刷新了
                        self.translationCache.removeAll()

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
                        self.middleTableView.reloadData()
                        if self.otaStyle.count > 0 {
                            self.rightCollectionView.isHidden = false
                            if let style = otaStyle.first?.dictValue {
                                rightViewModel.style = style
                            } else if let style = otaStyle.first?.style {
                                rightViewModel.style = style
                            }
                            self.fetchInitialData()
                        }
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
                }
                
            case .failure(let error):
                print("❌ 网络请求失败：\(error.localizedDescription)")
                // 打印更详细的错误信息
                if let underlyingError = error.underlyingError {
                    print("   底层错误: \(underlyingError.localizedDescription)")
                }
                // 可以添加错误提示UI
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
        rightCollectionView.reloadData()
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
        rightCollectionView.reloadData()
        
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
        print("显示空状态视图")
    }
    
    private func hideEmptyState() {
        print("隐藏空状态视图")
    }
    
    private func showErrorState() {
        print("显示错误状态视图")
    }
    
    // 分段控制器值变化
    @objc private func segmentValueChanged() {
        let selectedIndex = segmentControl.selectedSegmentIndex
        guard let types = mResponse?.data.otaType,
              selectedIndex < types.count else { return }

        // 清空翻译缓存，因为数据源改变了
        translationCache.removeAll()

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
            fetchInitialData()
        } else {
            rightViewModel.items = []
            rightCollectionView.reloadData()
        }
        selectedMiddleIndexPath = IndexPath(row: 0, section: 0)
        middleTableView.reloadData()
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
        fetchInitialData()
        middleTableView.reloadData()
    }
    
    deinit {
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 翻译相关方法

    /// 批量翻译当前可见的文本（iOS 18+）
    private func batchTranslateVisibleTexts() {
        guard #available(iOS 18.0, *) else {
            return
        }

        // 收集所有需要翻译的文本
        var textsToTranslate: [String] = []
        for item in otaStyle {
            if let text = item.dictValue ?? item.style {
                // 跳过已缓存的
                if translationCache[text] == nil && !pendingTranslations.contains(text) {
                    textsToTranslate.append(text)
                    pendingTranslations.insert(text)
                }
            }
        }

        guard !textsToTranslate.isEmpty, !isTranslating else {
            return
        }

        isTranslating = true

        // 获取目标语言
        let targetLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        guard targetLanguage != "en" else {
            // 目标语言是英文，无需翻译
            for text in textsToTranslate {
                translationCache[text] = text
            }
            isTranslating = false
            pendingTranslations.removeAll()
            return
        }

        // 使用辅助类执行翻译
        Task { @MainActor in
            let helper = TranslationHelper()
            let results = await helper.batchTranslate(
                texts: textsToTranslate,
                from: "en",
                to: targetLanguage
            )

            // 更新缓存
            for (original, translated) in results {
                self.translationCache[original] = translated
                self.pendingTranslations.remove(original)
            }

            self.isTranslating = false

            // 刷新表格
            self.middleTableView.reloadData()
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MiddleCell", for: indexPath)
        let styleItem = otaStyle[indexPath.row]

        // 获取原始文本（英文）
        var originalText: String?
        if let style = styleItem.dictValue {
            originalText = style
        } else if let style = styleItem.style {
            originalText = style
        }

        // 设置文本（优先使用翻译结果，否则使用原文）
        if let text = originalText {
            if #available(iOS 18.0, *) {
                // iOS 18+：使用批量翻译功能
                if let translatedText = translationCache[text] {
                    // 如果有翻译缓存，使用翻译结果
                    cell.textLabel?.text = translatedText
                } else {
                    // 否则先显示原文
                    cell.textLabel?.text = text

                    // 触发批量翻译（只在第一次显示第一个 cell 时触发）
                    if indexPath.row == 0 && !isTranslating && translationCache.isEmpty {
                        batchTranslateVisibleTexts()
                    }
                }
            } else {
                // iOS 18 以下，直接显示原文
                cell.textLabel?.text = text
            }
        }

        cell.textLabel?.textAlignment = .left
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        // 设置支持两行显示
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        cell.backgroundColor = (selectedMiddleIndexPath == indexPath) ? UIColor.brand.withAlphaComponent(0.5) : .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateMiddleSelection(at: indexPath)
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension TripleTableViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 实现代理方法，确保布局正确
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let itemWidth = (totalWidth - 8) / 2 // 减去列间距
        return CGSize(width: floor(itemWidth), height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rightViewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RightCollectionCell", for: indexPath) as! RightCollectionCell
        let item = rightViewModel.items[indexPath.row]
        cell.configure(with: item)
        cell.tag = indexPath.row
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 这里保持原有逻辑不变
        collectionView.deselectItem(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ClockUseViewController") as? ClockUseViewController
        let item = rightViewModel.items[indexPath.row]
        vc?.index = indexPath.row + 1 // 代表什么含义
        vc?.current = current
        vc?.currentClock = ClockResponse(previewPic: item.previewImageUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), resourcesUrl: item.dialBinUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), resolutionRatio: "\(item.width ?? 0)*\(item.height ?? 0)", isPublish: "true")
        parent?.navigationController?.pushViewController(vc!, animated: true)
    }
}

// MARK: - 集合视图单元格
class RightCollectionCell: UICollectionViewCell {
    private let itemImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        // 图片视图
        itemImageView.contentMode = .scaleAspectFit
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(itemImageView)
        
        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            itemImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            itemImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with item: ClockItem) {
        itemImageView.kf.cancelDownloadTask() // 取消之前的任务
        // 设置默认占位图
        itemImageView.image = UIImage(systemName: "photo")
        
        guard let urlString = item.previewImageUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let imageUrl = URL(string: urlString) else {
            XLogger.shared.log("图片URL无效或为空: \(item.previewImageUrl ?? "nil")")
            return
        }
        // 使用Kingfisher加载图片并处理结果
        itemImageView.kf.setImage(with: imageUrl, options: [.forceRefresh]) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // 图片加载成功，无需额外操作
                break
            case .failure(let error):
                // 打印详细的错误信息
                XLogger.shared.log("图片加载失败 - URL: \(urlString), 原因: \(error.localizedDescription)")
                // 确保失败时显示占位图
                self.itemImageView.image = UIImage(systemName: "photo")
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
        var parameters: [String: Any] = [
            "pageSize": 20,
            "pageNum": 0,
            "width": screenWidth,
            "height": screenHeight,
            "shape": XGZTBlueToothManager.shared.device?.screenType == 1 ? "round" : "square",
            "type": type,
            "style": style
        ]
//        let lang = LanguageManager.getInterfaceLang()
//        if lang != "English" && !isUsrEnglish {
//            parameters["lang"] = lang
//        }
        
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
        var parameters: [String: Any] = [
            "pageSize": 20,
            "pageNum": nextPage,
            "width": screenWidth,
            "height": screenHeight,
            "shape": XGZTBlueToothManager.shared.device?.screenType == 1 ? "round" : "square",
            "type": type,
            "style": style
        ]
//        let lang = LanguageManager.getInterfaceLang()
//        if lang != "English" && !isUsrEnglish {
//            parameters["lang"] = lang
//        }
        
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

// MARK: - Translation Helper (iOS 18+)
@available(iOS 18.0, *)
class TranslationHelper {
    /// 批量翻译文本
    /// - Parameters:
    ///   - texts: 要翻译的文本数组
    ///   - sourceLanguage: 源语言代码（如 "en"）
    ///   - targetLanguage: 目标语言代码（如 "zh-Hans"）
    /// - Returns: 字典，key 为原文，value 为译文
    func batchTranslate(texts: [String], from sourceLanguage: String, to targetLanguage: String) async -> [String: String] {
        return await withCheckedContinuation { continuation in
            // 创建一个 SwiftUI 环境来执行翻译
            let view = TranslationView(
                texts: texts,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            ) { results in
                continuation.resume(returning: results)
            }

            // 使用 UIHostingController 临时托管这个 View
            // 注意：这个 controller 不需要显示，只是用来触发 SwiftUI 的生命周期
            let hostingController = UIHostingController(rootView: view)

            // 将 controller 添加到 window（但不显示）
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                hostingController.view.frame = .zero
                hostingController.view.isHidden = true
                window.addSubview(hostingController.view)

                // 延迟移除（给翻译任务足够的时间执行）
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    hostingController.view.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - SwiftUI Translation View (iOS 18+)
@available(iOS 18.0, *)
private struct TranslationView: View {
    let texts: [String]
    let sourceLanguage: String
    let targetLanguage: String
    let completion: ([String: String]) -> Void

    @State private var configuration: TranslationSession.Configuration?
    @State private var hasCompleted = false

    var body: some View {
        Color.clear
            .onAppear {
                // 触发翻译
                configuration = TranslationSession.Configuration(
                    source: Locale.Language(identifier: sourceLanguage),
                    target: Locale.Language(identifier: targetLanguage)
                )
            }
            .translationTask(configuration) { session in
                guard !hasCompleted else { return }

                do {
                    // 构造批量请求
                    let requests = texts.map { TranslationSession.Request(sourceText: $0) }

                    // 执行批量翻译
                    let responses = try await session.translations(from: requests)

                    // 构建结果字典
                    var results: [String: String] = [:]
                    for (index, request) in requests.enumerated() {
                        if index < responses.count {
                            results[request.sourceText] = responses[index].targetText
                        }
                    }

                    hasCompleted = true
                    completion(results)
                } catch {
                    print("批量翻译失败: \(error.localizedDescription)")
                    // 失败时返回原文
                    var results: [String: String] = [:]
                    for text in texts {
                        results[text] = text
                    }
                    hasCompleted = true
                    completion(results)
                }
            }
    }
}
