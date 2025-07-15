import UIKit
import MJRefresh // 导入 MJRefresh 库

// MARK: - 主视图控制器
class TripleTableViewController: UIViewController {
    
    // MARK: - 属性
    private let leftTableView = UITableView()
    private let middleTableView = UITableView()
    private let rightTableView = UITableView()
    
    private let leftViewModel = LeftViewModel()
    private let middleViewModel = MiddleViewModel()
    private let rightViewModel = RightViewModel()
    
    // MARK: - 视图生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableViews()
        setupMJRefresh()
        fetchInitialData()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 添加三个表格视图
        view.addSubview(leftTableView)
        view.addSubview(middleTableView)
        view.addSubview(rightTableView)
    }
    
    private func setupConstraints() {
        leftTableView.translatesAutoresizingMaskIntoConstraints = false
        middleTableView.translatesAutoresizingMaskIntoConstraints = false
        rightTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 左边表格视图约束 (宽度80)
            leftTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            leftTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            leftTableView.widthAnchor.constraint(equalToConstant: 80),
            
            // 中间表格视图约束 (宽度100)
            middleTableView.leadingAnchor.constraint(equalTo: leftTableView.trailingAnchor),
            middleTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            middleTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            middleTableView.widthAnchor.constraint(equalToConstant: 100),
            
            // 右边表格视图约束 (填充剩余空间)
            rightTableView.leadingAnchor.constraint(equalTo: middleTableView.trailingAnchor),
            rightTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rightTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupTableViews() {
        // 左边表格视图设置
        leftTableView.delegate = self
        leftTableView.dataSource = self
        leftTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LeftCell")
        leftTableView.tableFooterView = UIView() // 隐藏多余的分隔线
        
        // 中间表格视图设置
        middleTableView.delegate = self
        middleTableView.dataSource = self
        middleTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MiddleCell")
        middleTableView.tableFooterView = UIView() // 隐藏多余的分隔线
        
        // 右边表格视图设置
        rightTableView.delegate = self
        rightTableView.dataSource = self
        rightTableView.register(RightTableViewCell.self, forCellReuseIdentifier: "RightCell")
        rightTableView.tableFooterView = UIView() // 隐藏多余的分隔线
        rightTableView.separatorStyle = .singleLine
        rightTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    // MARK: - MJRefresh 设置
    private func setupMJRefresh() {
        // 设置下拉刷新
        let header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.refreshData()
        })
        header.lastUpdatedTimeLabel?.isHidden = true
        header.stateLabel?.textColor = .systemGray
        header.activityIndicatorViewStyle = .medium
        header.setTitle("下拉刷新", for: .idle)
        header.setTitle("释放更新", for: .pulling)
        header.setTitle("加载中...", for: .refreshing)
        rightTableView.mj_header = header
        
        // 设置上拉加载更多
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadMoreData()
        })
        footer.stateLabel?.textColor = .systemGray
        footer.setTitle("上拉加载更多", for: .idle)
        footer.setTitle("加载中...", for: .refreshing)
        footer.setTitle("没有更多数据", for: .noMoreData)
        footer.isAutomaticallyHidden = true // 当数据不足一页时自动隐藏footer
        rightTableView.mj_footer = footer
    }
    
    // MARK: - 数据获取
    private func fetchInitialData() {
        rightTableView.mj_header?.beginRefreshing()
        refreshData()
    }
    
    @objc private func refreshData() {
        rightViewModel.refreshData { [weak self] success in
            DispatchQueue.main.async {
                self?.updateRightTableViewAfterRefresh(success: success)
            }
        }
    }
    
    @objc private func loadMoreData() {
        guard !rightViewModel.isLoading, rightViewModel.hasMoreData else {
            rightTableView.mj_footer?.endRefreshing()
            return
        }
        
        rightViewModel.loadMoreData { [weak self] success in
            DispatchQueue.main.async {
                self?.updateRightTableViewAfterLoadMore(success: success)
            }
        }
    }
    
    // MARK: - 辅助方法
    private func updateRightTableViewAfterRefresh(success: Bool) {
        rightTableView.reloadData()
        rightTableView.mj_header?.endRefreshing()
        
        if success {
            if rightViewModel.items.isEmpty {
                showEmptyState()
                rightTableView.mj_footer?.endRefreshingWithNoMoreData()
            } else {
                hideEmptyState()
                rightTableView.mj_footer?.resetNoMoreData()
            }
        } else {
            showErrorState()
        }
    }
    
    private func updateRightTableViewAfterLoadMore(success: Bool) {
        rightTableView.reloadData()
        
        // 修复：直接使用 hasMoreData 属性，不需要解包
        if success, rightViewModel.hasMoreData {
            rightTableView.mj_footer?.endRefreshing()
        } else if success {
            rightTableView.mj_footer?.endRefreshingWithNoMoreData()
        } else {
            rightTableView.mj_footer?.endRefreshing()
            showErrorState()
        }
    }
    
    private func showEmptyState() {
        // 这里可以添加空状态视图
        print("显示空状态视图")
    }
    
    private func hideEmptyState() {
        // 隐藏空状态视图
        print("隐藏空状态视图")
    }
    
    private func showErrorState() {
        // 这里可以添加错误状态视图
        print("显示错误状态视图")
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TripleTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == leftTableView {
            return leftViewModel.items.count
        } else if tableView == middleTableView {
            return middleViewModel.items.count
        } else {
            return rightViewModel.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == leftTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeftCell", for: indexPath)
            cell.textLabel?.text = leftViewModel.items[indexPath.row]
            cell.textLabel?.textAlignment = .center
            return cell
        } else if tableView == middleTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MiddleCell", for: indexPath)
            cell.textLabel?.text = middleViewModel.items[indexPath.row]
            cell.textLabel?.textAlignment = .center
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightCell", for: indexPath) as! RightTableViewCell
            let item = rightViewModel.items[indexPath.row]
            cell.configure(with: item)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == rightTableView {
            return 72
        }
        return UITableView.automaticDimension
    }
}

// MARK: - 右边表格视图单元格
class RightTableViewCell: UITableViewCell {
    
    private let itemImageView = UIImageView()
    private let nameLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 图片视图设置
        itemImageView.contentMode = .scaleAspectFill
        itemImageView.clipsToBounds = true
        itemImageView.backgroundColor = .systemGray4
        itemImageView.layer.cornerRadius = 25
        contentView.addSubview(itemImageView)
        
        // 名称标签设置
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)
        
        // 值标签设置
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .systemGray
        valueLabel.numberOfLines = 1
        contentView.addSubview(valueLabel)
        
        // 设置约束
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 图片视图约束
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: 50),
            itemImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // 名称标签约束
            nameLabel.leadingAnchor.constraint(equalTo: itemImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 值标签约束
            valueLabel.leadingAnchor.constraint(equalTo: itemImageView.trailingAnchor, constant: 12),
            valueLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with item: RightItem) {
        nameLabel.text = item.name
        valueLabel.text = item.value
        
        // 模拟图片加载
        DispatchQueue.global().async {
            // 模拟延迟
            Thread.sleep(forTimeInterval: 0.3)
            
            DispatchQueue.main.async { [weak self] in
                // 检查单元格是否仍在使用相同的数据
                if let currentItem = self?.nameLabel.text, currentItem == item.name {
                    // 使用系统图标作为占位图
                    self?.itemImageView.image = UIImage(systemName: "photo")
                }
            }
        }
    }
}

// MARK: - 数据模型
struct RightItem {
    let name: String
    let value: String
    let imageUrl: String // 实际项目中使用
}

// MARK: - 视图模型
class LeftViewModel {
    let items = ["数字", "经典"]
}

class MiddleViewModel {
    let items: [String] = {
        return (1...50).map { "Row \($0)" }
    }()
}

class RightViewModel {
    var items: [RightItem] = []
    var currentPage = 1
    var isLoading = false
    var hasMoreData = true
    
    func fetchInitialData(completion: @escaping (Bool) -> Void) {
        loadData(for: 1) { [weak self] success, items in
            if success, let items = items {
                self?.items = items
                self?.currentPage = 1
                self?.hasMoreData = items.count >= 10 // 假设每页10条数据
            }
            completion(success)
        }
    }
    
    func refreshData(completion: @escaping (Bool) -> Void) {
        loadData(for: 1) { [weak self] success, items in
            if success, let items = items {
                self?.items = items
                self?.currentPage = 1
                self?.hasMoreData = items.count >= 10
            }
            completion(success)
        }
    }
    
    func loadMoreData(completion: @escaping (Bool) -> Void) {
        guard !isLoading, hasMoreData else {
            completion(false)
            return
        }
        
        isLoading = true
        let nextPage = currentPage + 1
        
        loadData(for: nextPage) { [weak self] success, items in
            defer { self?.isLoading = false }
            
            if success, let items = items {
                self?.items.append(contentsOf: items)
                self?.currentPage = nextPage
                self?.hasMoreData = items.count >= 10
            }
            completion(success)
        }
    }
    
    private func loadData(for page: Int, completion: @escaping (Bool, [RightItem]?) -> Void) {
        // 模拟网络请求延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // 生成模拟数据
            let items = (1...10).map { index in
                let offset = (page - 1) * 10
                return RightItem(
                    name: "Item \(offset + index)",
                    value: "Value for item \(offset + index)",
                    imageUrl: "https://picsum.photos/200/200?random=\(offset + index)"
                )
            }
            
            completion(true, items)
        }
    }
}    
