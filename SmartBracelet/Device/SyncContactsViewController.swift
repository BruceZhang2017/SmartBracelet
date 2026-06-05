//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  SyncContactsViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2025/01/15.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit
import Contacts
import Toaster

// MARK: - 联系人模型
struct ContactItem {
    let contact: CNContact
    var isSelected: Bool = false

    var displayName: String {
        return "\(contact.familyName)\(contact.givenName)"
    }

    var phoneNumber: String? {
        return contact.phoneNumbers.first?.value.stringValue
    }

    var sortKey: String {
        // 使用拼音首字母作为分组键
        let name = displayName
        if name.isEmpty { return "#" }

        // 转换为拼音
        let mutableString = NSMutableString(string: name) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)

        let pinyin = mutableString as String
        let firstChar = pinyin.prefix(1).uppercased()

        // 判断是否为字母
        if firstChar.rangeOfCharacter(from: CharacterSet.letters) != nil {
            return firstChar
        }
        return "#"
    }
}

class SyncContactsViewController: BaseViewController {

    // MARK: - Properties
    private var allContacts: [ContactItem] = []
    private var filteredContacts: [ContactItem] = []
    private var groupedContacts: [String: [ContactItem]] = [:]
    private var sectionTitles: [String] = []
    private var isSearching = false

    private var isSyncing = false
    private var syncedCount = 0
    private var totalSyncCount = 0
    private let maxContactsLimit = 8
    private var selectedContacts: [CNContact] = []

    // 本地缓存key
    private let contactsCacheKey = "SyncContactsViewController.CachedContactIdentifiers"

    // 右上角计数标签
    private var countLabel: UILabel?

    // MARK: - UI Components
    private let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "search_placeholder".localized()
        search.searchBarStyle = .minimal
        search.backgroundImage = UIImage()
        search.translatesAutoresizingMaskIntoConstraints = false
        return search
    }()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        table.separatorStyle = .singleLine
        table.sectionIndexColor = UIColor.darkGray
        table.sectionIndexBackgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let emptyStateView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "empty_contacts")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray.withAlphaComponent(0.5)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let syncButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("sync_contacts".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.brand
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // 同步进度容器
    private let progressContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 进度条背景
    private let progressBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 进度条
    private let progressView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.brand
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 进度百分比标签
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 进度提示文字
    private let progressTipLabel: UILabel = {
        let label = UILabel()
        label.text = "max_contacts_limit".localized()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var progressViewWidthConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "sync_contacts".localized()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)

        setupNavigationBar()
        setupUI()
        loadCachedContacts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("SyncContactsViewController"), object: nil)
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        // 确保在主线程更新UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let obj = notification.object as? String, obj.count > 0 {
                if obj == "0" {
                    if self.syncedCount == -1 {
                        self.startBarBatchSyncFromA()
                    } else {
                        // 更新进度
                        self.syncedCount += 1
                        self.updateProgress()

                        self.syncNextContact(index: self.syncedCount)
                    }
                } else {
                    Toast(text: "add_contact_fail1".localized()).show()
                }
            }
        }
    }

    // MARK: - Setup UI
    private func setupNavigationBar() {
        // 右上角显示选中数量
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.black
        label.text = "0/\(maxContactsLimit)"
        label.sizeToFit()
        let labelWidth = max(label.frame.width, 44)
        let labelHeight = max(label.frame.height, 30)
        label.frame = CGRect(x: 0, y: 0, width: labelWidth, height: labelHeight)
        countLabel = label

        let countBarButton = UIBarButtonItem(customView: label)
        navigationItem.rightBarButtonItem = countBarButton
    }

    private func setupUI() {
        // 添加搜索栏
        view.addSubview(searchBar)
        searchBar.delegate = self

        // 添加tableView
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ContactSelectionCell.self, forCellReuseIdentifier: "ContactCell")

        // 添加空状态视图
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)

        // 添加同步按钮
        view.addSubview(syncButton)
        syncButton.addTarget(self, action: #selector(syncButtonTapped), for: .touchUpInside)

        // 添加进度容器
        view.addSubview(progressContainerView)
        progressContainerView.addSubview(progressBackgroundView)
        progressBackgroundView.addSubview(progressView)
        progressBackgroundView.addSubview(progressLabel)
        progressContainerView.addSubview(progressTipLabel)

        // 进度条宽度约束（初始为0）
        progressViewWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // 搜索栏约束
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            searchBar.heightAnchor.constraint(equalToConstant: 56),

            // TableView约束
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: syncButton.topAnchor, constant: -20),

            // 空状态视图约束
            emptyStateView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: syncButton.topAnchor, constant: -20),

            // 空状态图标约束
            emptyImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 200),
            emptyImageView.heightAnchor.constraint(equalToConstant: 200),

            // 同步按钮约束
            syncButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            syncButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            syncButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            syncButton.heightAnchor.constraint(equalToConstant: 50),

            // 进度容器约束
            progressContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            progressContainerView.heightAnchor.constraint(equalToConstant: 120),

            // 进度条背景约束
            progressBackgroundView.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: 30),
            progressBackgroundView.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: -30),
            progressBackgroundView.topAnchor.constraint(equalTo: progressContainerView.topAnchor, constant: 20),
            progressBackgroundView.heightAnchor.constraint(equalToConstant: 50),

            // 进度条约束
            progressView.leadingAnchor.constraint(equalTo: progressBackgroundView.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: progressBackgroundView.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor),
            progressViewWidthConstraint!,

            // 进度百分比标签约束
            progressLabel.centerXAnchor.constraint(equalTo: progressBackgroundView.centerXAnchor),
            progressLabel.centerYAnchor.constraint(equalTo: progressBackgroundView.centerYAnchor),

            // 进度提示文字约束
            progressTipLabel.topAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor, constant: 10),
            progressTipLabel.centerXAnchor.constraint(equalTo: progressContainerView.centerXAnchor)
        ])

        updateEmptyState()
    }


    // MARK: - Actions
    @objc private func syncButtonTapped() {
        let selectedContacts = allContacts.filter { $0.isSelected }.map { $0.contact }

        if selectedContacts.isEmpty {
            Toast(text: "please_select_contacts".localized()).show()
            return
        }

        startBatchSync(contacts: selectedContacts)
    }

    private func toggleContactSelection(at indexPath: IndexPath) {
        let section = sectionTitles[indexPath.section]
        guard var sectionContacts = groupedContacts[section] else { return }

        let contact = sectionContacts[indexPath.row]

        // 如果要选中，先检查是否已达上限
        if !contact.isSelected {
            let currentSelectedCount = allContacts.filter { $0.isSelected }.count
            if currentSelectedCount >= maxContactsLimit {
                Toast(text: String(format: "exceed_contact_limit".localized(), maxContactsLimit)).show()
                return
            }
        }

        // 切换选中状态
        sectionContacts[indexPath.row].isSelected.toggle()
        groupedContacts[section] = sectionContacts

        // 同步到allContacts
        if let index = allContacts.firstIndex(where: { $0.contact.identifier == contact.contact.identifier }) {
            allContacts[index].isSelected = sectionContacts[indexPath.row].isSelected
        }

        // 更新计数显示
        updateSelectionCount()

        // 保存选中状态到缓存
        saveCachedContacts()

        // 刷新单元格
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func updateSelectionCount() {
        let selectedCount = allContacts.filter { $0.isSelected }.count
        countLabel?.text = "\(selectedCount)/\(maxContactsLimit)"
        countLabel?.sizeToFit()
    }

    private func groupContactsByLetter() {
        let contacts = isSearching ? filteredContacts : allContacts

        // 清空之前的分组
        groupedContacts.removeAll()
        sectionTitles.removeAll()

        // 按首字母分组
        for contact in contacts {
            let key = contact.sortKey
            if groupedContacts[key] == nil {
                groupedContacts[key] = []
            }
            groupedContacts[key]?.append(contact)
        }

        // 排序section标题
        sectionTitles = groupedContacts.keys.sorted()

        // 将#放到最后
        if let index = sectionTitles.firstIndex(of: "#") {
            sectionTitles.remove(at: index)
            sectionTitles.append("#")
        }

        // 对每个分组内的联系人按名字排序
        for key in sectionTitles {
            groupedContacts[key]?.sort { $0.displayName < $1.displayName }
        }
    }

    private func updateEmptyState() {
        let isEmpty = allContacts.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    // MARK: - Local Cache
    private func saveCachedContacts() {
        let selectedIdentifiers = allContacts.filter { $0.isSelected }.map { $0.contact.identifier }
        UserDefaults.standard.set(selectedIdentifiers, forKey: contactsCacheKey)
        UserDefaults.standard.synchronize()
    }

    private func loadCachedContacts() {
        guard let selectedIdentifiers = UserDefaults.standard.array(forKey: contactsCacheKey) as? [String],
              !selectedIdentifiers.isEmpty else {
            fetchAllContacts()
            return
        }

        let store = CNContactStore()
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]

        var fetchedContacts: [CNContact] = []

        for identifier in selectedIdentifiers {
            do {
                let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
                fetchedContacts.append(contact)
            } catch {
                print("Failed to fetch contact with identifier: \(identifier)")
            }
        }

        // 获取所有联系人
        fetchAllContacts(preSelectedContacts: fetchedContacts)
    }

    private func fetchAllContacts(preSelectedContacts: [CNContact] = []) {
        let store = CNContactStore()
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        do {
            var fetchedContacts: [ContactItem] = []
            try store.enumerateContacts(with: request) { contact, _ in
                if !contact.phoneNumbers.isEmpty {
                    // 检查是否在预选列表中
                    let isSelected = preSelectedContacts.contains(where: { $0.identifier == contact.identifier })
                    fetchedContacts.append(ContactItem(contact: contact, isSelected: isSelected))
                }
            }

            DispatchQueue.main.async { [weak self] in
                self?.allContacts = fetchedContacts
                self?.groupContactsByLetter()
                self?.updateSelectionCount()
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
        } catch {
            DispatchQueue.main.async {
                Toast(text: "failed_to_load_contacts".localized()).show()
            }
        }
    }

    // MARK: - Batch Sync
    private func startBatchSync(contacts: [CNContact]) {
        // 验证联系人数量限制
        if contacts.count > maxContactsLimit {
            let message = String(format: "exceed_contact_limit".localized(), maxContactsLimit)
            Toast(text: message).show()
            return
        }
        if syncedCount == -1 {
            Toast(text: "add_contact_fail2".localized()).show()
            return
        }
        selectedContacts = contacts
        
        if isXGZT {
            syncedCount = -1
            XGZTCommand.getContactInfo()
        }

        
    }
    
    private func startBarBatchSyncFromA() {
        // 显示进度UI
        isSyncing = true
        totalSyncCount = selectedContacts.count
        syncedCount = 0

        progressContainerView.isHidden = false
        syncButton.isHidden = true

        // 初始化进度条
        progressViewWidthConstraint?.constant = 0
        progressLabel.text = "0%"

        // 开始同步
        syncNextContact(index: 0)
    }

    private func syncNextContact(index: Int) {
        guard index < selectedContacts.count else {
            completeBatchSync()
            return
        }
        let contact = selectedContacts[index]
        syncContactToDevice(index: index, contact: contact)
    }

    private func updateProgress() {
        guard totalSyncCount > 0 else { return }

        let percentage = Float(syncedCount) / Float(totalSyncCount)
        let progressWidth = progressBackgroundView.bounds.width * CGFloat(percentage)

        UIView.animate(withDuration: 0.3) {
            self.progressViewWidthConstraint?.constant = progressWidth
            self.progressLabel.text = "\(Int(percentage * 100))%"
            self.view.layoutIfNeeded()
        }
    }

    private func completeBatchSync() {
        isSyncing = false

        // 显示完成提示
        Toast(text: "contacts_synced_successfully".localized()).show()

        // 延迟隐藏进度条，让用户看到100%
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.progressContainerView.isHidden = true
            self.syncButton.isHidden = false

            // 刷新列表
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }

    private func syncContactToDevice(index: Int, contact: CNContact) {
        guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else {
            return
        }
        let fullName = "\(contact.familyName)\(contact.givenName)"
        if isXGZT {
            XGZTCommand.setContactInfo(index: index, name: fullName, phoneNumber: phoneNumber)
        }
    }
}

// MARK: - UITableViewDataSource
extension SyncContactsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sectionTitles[section]
        return groupedContacts[key]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactSelectionCell

        let section = sectionTitles[indexPath.section]
        if let contact = groupedContacts[section]?[indexPath.row] {
            cell.configure(with: contact)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTitles
    }
}

// MARK: - UITableViewDelegate
extension SyncContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        toggleContactSelection(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .gray
            header.textLabel?.font = UIFont.systemFont(ofSize: 14)
            header.backgroundView?.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        }
    }
}

// MARK: - UISearchBarDelegate
extension SyncContactsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredContacts = []
        } else {
            isSearching = true
            filteredContacts = allContacts.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                ($0.phoneNumber?.contains(searchText) ?? false)
            }
        }

        groupContactsByLetter()
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredContacts = []
        groupContactsByLetter()
        tableView.reloadData()
    }
}

// MARK: - ContactSelectionCell
class ContactSelectionCell: UITableViewCell {

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .lightGray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = UIColor.brand
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubview(nameLabel)
        contentView.addSubview(phoneLabel)
        contentView.addSubview(checkmarkImageView)

        NSLayoutConstraint.activate([
            // 姓名标签在左侧
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120),

            // Checkmark在右侧
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),

            // 电话标签在checkmark左边
            phoneLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            phoneLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            phoneLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8)
        ])
    }

    func configure(with contact: ContactItem) {
        nameLabel.text = contact.displayName
        phoneLabel.text = contact.phoneNumber
        checkmarkImageView.isHidden = !contact.isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        phoneLabel.text = nil
        checkmarkImageView.isHidden = true
    }
}
