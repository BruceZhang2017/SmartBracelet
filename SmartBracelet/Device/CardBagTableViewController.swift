import UIKit

class CardBagTableViewController: BaseViewController {
    
    // 卡片数据模型
    struct CardItem {
        let title: String
        let imageName: String
        let identifier: Int
    }
    
    // 卡片数据列表
    private let cardItems: [CardItem] = [
        CardItem(title: "device_push_settings_wechat".localized(), imageName: "wechat_icon", identifier: 1),
        CardItem(title: "alipay".localized(), imageName: "alipay_icon", identifier: 0)
    ]
    
    // 表格视图
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    // 设置基础UI
    private func setupUI() {
        title = "cardbag".localized()
    }
    
    // 配置表格视图
    private func setupTableView() {
        // 设置表格属性
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.register(CardTableViewCell.self, forCellReuseIdentifier: "CardTableViewCell")
        
        // 设置数据源和代理
        tableView.dataSource = self
        tableView.delegate = self
        
        // 添加到视图并设置约束
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension CardBagTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cardItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "CardTableViewCell",
            for: indexPath
        ) as? CardTableViewCell else {
            return UITableViewCell()
        }
        
        let item = cardItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CardBagTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // 每行高度
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = cardItems[indexPath.row]
        handleCardSelection(item: item)
    }
    
    // 处理卡片选择事件
    private func handleCardSelection(item: CardItem) {
        print("选中了: \(item.title)")
        // 这里可以添加跳转逻辑
        // 例如: navigationController?.pushViewController(DetailViewController(), animated: true)
        let vc = QRBindViewController()
        vc.title = item.title
        vc.type = item.identifier
        navigationController?.pushViewController(vc, animated: true)
    }
}

// 自定义表格单元格
class CardTableViewCell: UITableViewCell {
    // 图标
    private let iconImageView = UIImageView()
    // 标题
    private let titleLabel = UILabel()
    // 箭头图标
    private let arrowImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 配置子视图
    private func setupSubviews() {
        // 图标设置
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 标题设置
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 箭头图标设置
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .gray
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到内容视图
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowImageView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // 配置单元格数据
    func configure(with item: CardBagTableViewController.CardItem) {
        titleLabel.text = item.title
        // 尝试加载本地图片，如果没有则使用系统图标
        if let image = UIImage(named: item.imageName) {
            iconImageView.image = image
        } else {
            iconImageView.image = UIImage(systemName: "creditcard")
            iconImageView.tintColor = .systemBlue
        }
    }
}
