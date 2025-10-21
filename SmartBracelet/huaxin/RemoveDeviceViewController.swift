//
//  deleteDevice.swift
//  SmartBracelet
//
//  Created by anker on 2025/5/12.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit

class RemoveDeviceViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "delete_device_1".localized()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "delete_device_2".localized()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let step1Label: UILabel = {
        let label = UILabel()
        label.text = "delete_device_3".localized()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let step1ImageView: UIImageView = {
        var name = "delete_device1" // 简体中文使用此图片
        let currentLang = Locale.preferredLanguages.first ?? "en"
        // 检查是否为简体中文语言环境
        if !currentLang.hasPrefix("zh-Hans") {
            name = "delete_device10" // 非简体中文使用此图片
        }
        let imageView = UIImageView()
        imageView.image = UIImage(named: name) // 替换为你的图片名
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(white: 0.95, alpha: 1) // 占位色
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    private let step2Label: UILabel = {
        let label = UILabel()
        label.text = "delete_device_4".localized()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let step2ImageView: UIImageView = {
        var name = "delete_device2" // 简体中文使用此图片
        let currentLang = Locale.preferredLanguages.first ?? "en"
        // 检查是否为简体中文语言环境
        if !currentLang.hasPrefix("zh-Hans") {
            name = "delete_device20" // 非简体中文使用此图片
        }
        let imageView = UIImageView()
        imageView.image = UIImage(named: name) // 替换为你的图片名
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(white: 0.95, alpha: 1) // 占位色
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    private let step3Label: UILabel = {
        let label = UILabel()
        label.text = "delete_device_5".localized()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let checkBox: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        button.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
        return button
    }()

    private let checkBoxLabel: UILabel = {
        let label = UILabel()
        label.text = "delete_device_6".localized()
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("delete_device_7".localized(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.3)
        button.setTitleColor(.systemOrange, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.addTarget(self, action: #selector(deleteFinished), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        [titleLabel, instructionLabel, step1Label, step1ImageView, step2Label, step2ImageView, step3Label, checkBox, checkBoxLabel, confirmButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            step1Label.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
            step1Label.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            step1Label.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),

            step1ImageView.topAnchor.constraint(equalTo: step1Label.bottomAnchor, constant: 10),
            step1ImageView.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            step1ImageView.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            step1ImageView.heightAnchor.constraint(equalToConstant: 300),

            step2Label.topAnchor.constraint(equalTo: step1ImageView.bottomAnchor, constant: 20),
            step2Label.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            step2Label.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),

            step2ImageView.topAnchor.constraint(equalTo: step2Label.bottomAnchor, constant: 10),
            step2ImageView.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            step2ImageView.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            step2ImageView.heightAnchor.constraint(equalToConstant: 300),

            step3Label.topAnchor.constraint(equalTo: step2ImageView.bottomAnchor, constant: 20),
            step3Label.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            step3Label.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),

            checkBox.topAnchor.constraint(equalTo: step3Label.bottomAnchor, constant: 30),
            checkBox.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 24),
            checkBox.heightAnchor.constraint(equalToConstant: 24),

            checkBoxLabel.centerYAnchor.constraint(equalTo: checkBox.centerYAnchor),
            checkBoxLabel.leadingAnchor.constraint(equalTo: checkBox.trailingAnchor, constant: 8),

            confirmButton.topAnchor.constraint(equalTo: checkBox.bottomAnchor, constant: 30),
            confirmButton.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    @objc private func checkBoxTapped() {
        checkBox.isSelected.toggle()
        confirmButton.isEnabled = checkBox.isSelected
        confirmButton.backgroundColor = checkBox.isSelected ? UIColor.systemOrange : UIColor.systemOrange.withAlphaComponent(0.3)
        confirmButton.setTitleColor(checkBox.isSelected ? .white : .systemOrange, for: .normal)
    }
    
    @objc private func deleteFinished() {
        self.navigationController?.popViewController(animated: true)
    }
}
