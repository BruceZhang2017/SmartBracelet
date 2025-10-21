//
//  SelectAddActionViewController.swift
//  SmartBracelet
//
//  Created by anker on 2025/5/24.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit

class SelectAddActionViewController: UIViewController {

    // MARK: - UI组件
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .left
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "device_add".localized()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        return label
    }()

    private let radarView = RadarScanView()

    private let scanningLabel: UILabel = {
        let label = UILabel()
        label.text = "\("select_device_scan".localized())..."
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()

    private let subLabel: UILabel = {
        let label = UILabel()
        label.text = "select_device_scan_desc".localized()
        label.textColor = UIColor(white: 1, alpha: 0.6)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    private let manualButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("select_device_add_manual".localized(), for: .normal)
        button.setTitleColor(UIColor.brand, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor(white: 1, alpha: 0.08)
        button.layer.cornerRadius = 24
        return button
    }()

    private let scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("select_device_add_automatic".localized(), for: .normal)
        button.setTitleColor(.brand, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor(white: 1, alpha: 0.08)
        button.layer.cornerRadius = 24
        return button
    }()

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radarView.startAnimation()
    }

    private func setupUI() {
        // 顶部导航
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8)
        ])
        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)

        // 雷达动画
        view.addSubview(radarView)
        radarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            radarView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 150),
            radarView.widthAnchor.constraint(equalToConstant: 280),
            radarView.heightAnchor.constraint(equalTo: radarView.widthAnchor)
        ])

        // 扫描文字
        view.addSubview(scanningLabel)
        view.addSubview(subLabel)
        scanningLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanningLabel.topAnchor.constraint(equalTo: radarView.bottomAnchor, constant: 32),
            scanningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: scanningLabel.bottomAnchor, constant: 8),
            subLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // 底部按钮
        view.addSubview(manualButton)
        view.addSubview(scanButton)
        manualButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            manualButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            manualButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            manualButton.heightAnchor.constraint(equalToConstant: 48),
            manualButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -12),

            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scanButton.bottomAnchor.constraint(equalTo: manualButton.bottomAnchor),
            scanButton.heightAnchor.constraint(equalTo: manualButton.heightAnchor),
            scanButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 12)
        ])
        manualButton.addTarget(self, action: #selector(manualAction), for: .touchUpInside)
        scanButton.addTarget(self, action: #selector(qrScanAction), for: .touchUpInside)
    }

    @objc private func backAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func manualAction() {
        self.dismiss(animated: false, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "4000")
    }
    
    @objc private func qrScanAction() {
        self.dismiss(animated: false, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "5000")
    }
}

// MARK: - 雷达动画视图
class RadarScanView: UIView {
    private let radarLayer = CAShapeLayer()
    private let scanLayer = CAShapeLayer()
    private let crossLayer = CAShapeLayer() // 新增：用于画十字线

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        // 雷达圆圈
        radarLayer.frame = bounds
        radarLayer.fillColor = UIColor.clear.cgColor
        radarLayer.strokeColor = UIColor(white: 1, alpha: 0.08).cgColor
        radarLayer.lineWidth = 2
        layer.addSublayer(radarLayer)

        // 扫描扇形
        scanLayer.frame = bounds
        scanLayer.fillColor = UIColor(red: 1, green: 0.9, blue: 0.8, alpha: 0.3).cgColor
        scanLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(scanLayer)
        
        // 十字线
        crossLayer.frame = bounds
        crossLayer.strokeColor = UIColor(white: 1, alpha: 0.1).cgColor
        crossLayer.lineWidth = 1
        layer.addSublayer(crossLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        radarLayer.frame = bounds
        scanLayer.frame = bounds
        drawRadar()
        drawScanSector()
        drawCrossLines() // 新增
    }

    private func drawRadar() {
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radii: [CGFloat] = [bounds.width/2 * 0.35, bounds.width/2 * 0.55, bounds.width/2 * 0.75, bounds.width/2 * 0.95]
        for r in radii {
            path.addArc(withCenter: center, radius: r, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        }
        radarLayer.path = path.cgPath
    }

    private func drawScanSector() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.width/2 * 0.95
        let startAngle = CGFloat(-Double.pi/6)
        let endAngle = CGFloat(Double.pi/6)
        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.close()
        scanLayer.path = path.cgPath
    }
    
    private func drawCrossLines() {
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        // 横线
        path.move(to: CGPoint(x: 0, y: center.y))
        path.addLine(to: CGPoint(x: bounds.width, y: center.y))
        // 竖线
        path.move(to: CGPoint(x: center.x, y: 0))
        path.addLine(to: CGPoint(x: center.x, y: bounds.height))
        crossLayer.path = path.cgPath
    }

    func startAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 2.5
        rotation.repeatCount = .infinity
        scanLayer.add(rotation, forKey: "rotation")
    }
}
