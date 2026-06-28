//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  HealthViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/7/26.
//  Copyright © 2020 tjd. All rights reserved.
//
    

import UIKit
import Toaster
import TJDWristbandSDK
import YYImage
import MJRefresh
import StoreKit
import AliIotConnectKit
import JL_BLEKit
import DropDown

class HealthViewController: BaseViewController {
    private enum HealthDashboardState {
        case noDevice
        case disconnected
        case noMetrics
        case content
    }
    
    private struct DashboardInsightPresentation {
        let chipText: String
        let titleText: String
        let detailText: String
        let metaText: String
        let accentColor: UIColor
    }
    
    private final class NumericLabelAnimationState {
        weak var label: UILabel?
        var startValue: Double
        var targetValue: Double
        var currentValue: Double
        let startTime: CFTimeInterval
        let duration: CFTimeInterval
        let decimals: Int
        let unit: String
        let size1: CGFloat
        let size2: CGFloat
        
        init(label: UILabel, startValue: Double, targetValue: Double, startTime: CFTimeInterval, duration: CFTimeInterval, decimals: Int, unit: String, size1: CGFloat, size2: CGFloat) {
            self.label = label
            self.startValue = startValue
            self.targetValue = targetValue
            self.currentValue = startValue
            self.startTime = startTime
            self.duration = duration
            self.decimals = decimals
            self.unit = unit
            self.size1 = size1
            self.size2 = size2
        }
    }
    
    @IBOutlet weak var footView: UIView!
    @IBOutlet weak var footMLabel: UILabel!
    @IBOutlet weak var footValueLabel: UILabel!
    @IBOutlet weak var footKLabel: UILabel!
    var collectionView: UICollectionView!
    let cellIdentifier = "CustomCell"
    private var currentModel: BLEModel!
    private let topSummaryCardView = UIView()
    private let topCardTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "today_step".localized()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.90)
        return label
    }()
    private let topCardDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.76)
        return label
    }()
    private let topCardStatusLabel: EdgeInsetLabel = {
        let label = EdgeInsetLabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        label.layer.cornerRadius = 13
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        return label
    }()
    private let topCardPrimaryDecorationView = UIView()
    private let topCardSecondaryDecorationView = UIView()
    private let summaryStatsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    private let distanceStatContainerView = UIView()
    private let calorieStatContainerView = UIView()
    private let distanceStatTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "health_distance".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.74)
        return label
    }()
    private let calorieStatTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "health_heat".localized()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.74)
        return label
    }()
    private let topCardValueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.58
        label.textAlignment = .left
        return label
    }()
    private let distanceStatValueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        label.textAlignment = .left
        return label
    }()
    private let calorieStatValueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        label.textAlignment = .left
        return label
    }()
    private let metricsSectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "health_head".localized()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = UIColor.text_primary
        return label
    }()
    private let metricsSectionSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor.brand.withAlphaComponent(0.86)
        label.numberOfLines = 1
        return label
    }()
    private let dashboardInsightCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 22
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.brand.withAlphaComponent(0.08).cgColor
        view.layer.shadowColor = UIColor.brand.withAlphaComponent(0.08).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 22
        return view
    }()
    private let dashboardInsightChipLabel: EdgeInsetLabel = {
        let label = EdgeInsetLabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor.brand
        label.backgroundColor = UIColor.brand.withAlphaComponent(0.10)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.contentInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        return label
    }()
    private let dashboardInsightTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor.text_primary
        label.numberOfLines = 2
        return label
    }()
    private let dashboardInsightDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.text_secondary
        label.numberOfLines = 0
        return label
    }()
    private let dashboardInsightMetaLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.brand
        label.numberOfLines = 1
        return label
    }()
    private let dashboardInsightDividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xEAF1FB)
        return view
    }()
    private let emptyStateView = HealthEmptyStateView()
    private let topSummaryGradientLayer = CAGradientLayer()
    private var footViewHeightConstraint: NSLayoutConstraint?
    private var femaleHealthHeightConstraint: NSLayoutConstraint?
    private var lastKnownCollectionWidth: CGFloat = 0
    private var numericDisplayLink: CADisplayLink?
    private var numericAnimationStates: [ObjectIdentifier: NumericLabelAnimationState] = [:]
    private var renderedNumericValues: [ObjectIdentifier: Double] = [:]
    private var shouldAnimateMetricCellsOnNextDisplay = true
    private var animatedMetricIndexPaths = Set<IndexPath>()
    private var lastMetricEntranceAnimationAt: CFTimeInterval = 0
    private let femaleHealthGradientLayer = CAGradientLayer()
    private let femaleHealthGlowView = UIView()
    private var latestStepCount = 0
    private var latestDistanceValue: Float = 0
    private var latestCalorieValue: Float = 0
    private var latestDistanceUnitText = ""

    // 女性健康入口视图
    private let femaleHealthContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 22
        view.layer.shadowColor = UIColor.brand.withAlphaComponent(0.18).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 12)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 24
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        view.layer.borderWidth = 1
        return view
    }()
    private let femaleHealthIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "heart.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        imageView.layer.cornerRadius = 22
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let femaleHealthTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_title".localized()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()

    private let femaleHealthSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "female_cycle_subtitle".localized()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.80)
        label.numberOfLines = 2
        return label
    }()
    private let femaleHealthBadgeLabel: EdgeInsetLabel = {
        let label = EdgeInsetLabel()
        label.text = "female_cycle_today".localized()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor.brand
        label.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        label.layer.cornerRadius = 11
        label.layer.masksToBounds = true
        label.contentInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return label
    }()

    private let femaleHealthArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = UIColor.white.withAlphaComponent(0.86)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    var xgztCount = 0
    
    var currentDialog: UIView? //记录当前的弹框，在页面异常关闭时移除
    
    var flag = 0 // 属性的作用
    private var hud: JGProgressHUD? // loading图标
    private var loadingViewCheckTimer: Timer?
    private var continueReadFootValueTimer: Timer?
    var header: MJRefreshNormalHeader?
    var isFirst = false
    var indexBigData:Int = 0
    var mBigDataManager:JL_BigDataManager?
    var bt_sdk:JL_RunSDK?
    var bt_ble:QCY_BLEApple?
    var arrayValue : [NSMutableAttributedString] = []
    
    var testData:Data?
    var getTimes:Int = 0
    var sendTimesOk:Int = 0
    var sendTimesFail:Int = 0
    var testAuto:Bool = true
    var isSupportAlipay = false // 是否支持支付宝支付
    var bHavenScanResult = false
    
    private var manager = OpenWeatherManager()
    var currentProgress = 0
    var alertController: UIAlertController?
    let dropDown = DropDown()
     
    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()
        // 设置导航栏标题颜色
        title = "health_head".localized()
        for _ in 0..<4 {
            arrayValue.append(NSMutableAttributedString(string: "null_data".localized(), attributes: [.font: UIFont.body2(), .foregroundColor: UIColor.text_secondary]))
        }
        let openCount = UserDefaults.standard.integer(forKey: "APPOPEN") // 如果app打开次数
        if openCount >= 20 { //当打开次数>20次后，就打开邀请评论app的弹窗
            perform(#selector(self.showDialogForInviteAPPReview), with: nil, afterDelay: 20)
            UserDefaults.standard.set(0, forKey: "APPOPEN")
        }
        registerNotification()
        
        if !isXGZT {
            WUBleManager.shared.didSetUserinfo = {
                result in
                XLogger.shared.log("设置用户信息是否成功: \(result)")
            }
        }
        
        navigationItem.rightBarButtonItem?.title = "health_head".localized()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterForgroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        if isSupportAlipay && !isXGZT {
            AliConnectMananger_C.shared.bleSendDataDelegate = self // 阿里云相关逻辑
            
            bt_sdk = JL_RunSDK.sharedMe() as? JL_RunSDK
            bt_ble = bt_sdk?.bt_ble

            mBigDataManager = bt_ble?.mAssist .mCmdManager.mBigDataManager
            onSetupBigData()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFootCount))
        footView.isUserInteractionEnabled = true
        tap.numberOfTapsRequired = 1
        footView.addGestureRecognizer(tap)
        
        configurePageAppearance()
        setupTopSummaryCard()

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 160, height: 166)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(HealthCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        setupMetricsSectionHeader()
        setupFemaleHealthEntry()
        setupMetricsCollectionLayout()
        configureEmptyStateView()
        updateDashboardPresentation(animated: false)
        
        // 设置 DropDown 数据源
        dropDown.dataSource = ["device_scan".localized(), "device_add".localized()]

        // 自定义下拉菜单样式
        dropDown.textFont = UIFont.systemFont(ofSize: 16)
        dropDown.textColor = .black
        dropDown.backgroundColor = .white
        dropDown.layer.cornerRadius = 16
        dropDown.clipsToBounds = true

        // 设置选中事件回调
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            XLogger.shared.log("选中了第 \(index) 项: \(item)")
            self.bHavenScanResult = false
            // 您可以在这里处理选中后的操作，例如更新界面或发送请求
            if index == 1 {
                var count = DeviceManager.shared.devices.count
                count += cacheDevices.count
                let storyboard = UIStoryboard(name: "Device", bundle: nil)
                if count == 0 {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController") as? DeviceSearchViewController
                    vc?.title = "device_add".localized()
                    vc?.refreshBackButton()
                    vc?.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc!, animated: true)
                } else {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController") as? DeviceListViewController
                    vc?.title = "device_change".localized()
                    vc?.refreshBackButton()
                    vc?.style = 1
                    vc?.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc!, animated: true)
                }
            } else {
                /// 创建二维码扫描
                let vc = ScannerVC()
                vc.modalPresentationStyle = .fullScreen
                //设置标题、颜色、扫描样式（线条、网格）、提示文字
                vc.setupScanner("device_scan".localized(), .blue, .grid, "device_scan_add_device".localized()) {[weak self] (code) in
                    // 扫描回调方法
                    XLogger.shared.log("扫描的结果是：\(code)")
                    
                    if self?.bHavenScanResult ?? false {
                        XLogger.shared.log("扫描的结果是重复了")
                        return
                    }
                    
                    guard !code.isEmpty else {
                        XLogger.shared.log("扫描的结果是无设备4")
                        self?.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    // 处理旧设备（含mac参数）
                    if code.contains("mac=") {
                        XLogger.shared.log("扫描的结果是旧设备")
                        self?.bHavenScanResult = true
                        if let mac = self?.extractMacValue(from: code) {
                            if bleSelf.bleModels.count > 0 {
                                for model in bleSelf.bleModels {
                                    let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                                    if m == mac.lowercased() {
                                        bleSelf.connectBleDevice(model: model)
                                        break
                                    }
                                }
                            } else {
                                BLEManager.shared.startScan()
                                Async.main(after: 1.5) {
                                    if bleSelf.bleModels.count > 0 {
                                        for model in bleSelf.bleModels {
                                            let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                                            if m == mac.lowercased() {
                                                bleSelf.connectBleDevice(model: model)
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // 处理新设备（含k参数）
                    else if code.contains("k=") {
                        XLogger.shared.log("扫描的结果是新设备")
                        self?.bHavenScanResult = true
                        
                        // 手动解析k参数值（避免URLComponents旧系统兼容问题）
                        if let kParamStart = code.range(of: "k=")?.upperBound {
                            let kParamEnd = code[kParamStart...].range(of: "&")?.lowerBound ?? code.endIndex
                            let kValueStr = String(code[kParamStart..<kParamEnd])
                            XLogger.shared.log("解析k参数的原始值：\(kValueStr)")
                            
                            // 按|分割字符串，获取所有部分
                            let components = kValueStr.components(separatedBy: "|")
                            
                            // 检查是否有足够的部分
                            guard components.count >= 2 else {
                                XLogger.shared.log("扫描的结果有错误1：参数k的值格式不正确，至少需要3个|分隔的部分，实际有\(components.count)个")
                                self?.dismiss(animated: true, completion: nil)
                                return
                            }
                            
                            // 提取各个部分并去除首尾空格
                            let macAddress = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            let deviceName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            XLogger.shared.log("解析到的mac地址是：\(macAddress)")
                            
                            if XGZTBlueToothManager.shared.isCurrentBleStateOFF() {
                                Toast(text: "ble_off".localized()).show()
                                XLogger.shared.log("蓝牙没有开启")
                            } else {
                                XGZTBlueToothManager.shared.connectAndScan(to: macAddress, deviceName: deviceName)
                            }
                        } else {
                            XLogger.shared.log("扫描的结果有错误2：未找到k参数")
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                    else {
                        XLogger.shared.log("扫描的结果有错误3：代码格式不匹配")
                    }
                    
                    // 关闭扫描页面（无论是否成功均关闭）
                    self?.dismiss(animated: true, completion: nil)
                }

                //Present到扫描页面
                self.navigationController?.present(vc, animated: true, completion: nil)
            }
            self.dropDown.clearSelection()
        }
    }
    
    func extractMacValue(from string: String) -> String? {
        let pattern = "mac="
        guard let range = string.range(of: pattern, options: .backwards) else {
            // 如果没有找到 "mac="，返回 nil
            return nil
        }
        // 截取 "mac=" 之后的字符串
        let macValue = string[range.upperBound...]
        return String(macValue)
    }
    
    private func configurePageAppearance() {
        view.backgroundColor = UIColor(hex: 0xF5F9FF)
        footView.backgroundColor = .clear
        footValueLabel.isHidden = true
        footMLabel.isHidden = true
        footKLabel.isHidden = true
        footViewHeightConstraint = footView.constraints.first(where: { $0.firstAttribute == .height })
        footViewHeightConstraint?.constant = preferredTopCardHeight()
    }
    
    private func setupTopSummaryCard() {
        topSummaryCardView.translatesAutoresizingMaskIntoConstraints = false
        topCardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        topCardDateLabel.translatesAutoresizingMaskIntoConstraints = false
        topCardStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        topCardPrimaryDecorationView.translatesAutoresizingMaskIntoConstraints = false
        topCardSecondaryDecorationView.translatesAutoresizingMaskIntoConstraints = false
        summaryStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        distanceStatContainerView.translatesAutoresizingMaskIntoConstraints = false
        calorieStatContainerView.translatesAutoresizingMaskIntoConstraints = false
        distanceStatTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        calorieStatTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        topCardValueLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceStatValueLabel.translatesAutoresizingMaskIntoConstraints = false
        calorieStatValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        topSummaryCardView.layer.cornerRadius = 30
        topSummaryCardView.layer.masksToBounds = true
        topSummaryCardView.layer.borderWidth = 1
        topSummaryCardView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        
        topSummaryGradientLayer.colors = dashboardGradientColors(for: .content).map { $0.cgColor }
        topSummaryGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        topSummaryGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        topSummaryCardView.layer.insertSublayer(topSummaryGradientLayer, at: 0)
        
        topCardPrimaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        topCardSecondaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        
        footView.addSubview(topSummaryCardView)
        topSummaryCardView.addSubview(topCardPrimaryDecorationView)
        topSummaryCardView.addSubview(topCardSecondaryDecorationView)
        topSummaryCardView.addSubview(topCardTitleLabel)
        topSummaryCardView.addSubview(topCardDateLabel)
        topSummaryCardView.addSubview(topCardStatusLabel)
        topSummaryCardView.addSubview(topCardValueLabel)
        
        configureSummaryStatCard(distanceStatContainerView)
        configureSummaryStatCard(calorieStatContainerView)
        summaryStatsStackView.addArrangedSubview(distanceStatContainerView)
        summaryStatsStackView.addArrangedSubview(calorieStatContainerView)
        topSummaryCardView.addSubview(summaryStatsStackView)
        
        distanceStatContainerView.addSubview(distanceStatTitleLabel)
        calorieStatContainerView.addSubview(calorieStatTitleLabel)
        distanceStatContainerView.addSubview(distanceStatValueLabel)
        calorieStatContainerView.addSubview(calorieStatValueLabel)
        
        NSLayoutConstraint.activate([
            topSummaryCardView.leadingAnchor.constraint(equalTo: footView.leadingAnchor, constant: 16),
            topSummaryCardView.trailingAnchor.constraint(equalTo: footView.trailingAnchor, constant: -16),
            topSummaryCardView.topAnchor.constraint(equalTo: footView.topAnchor, constant: 12),
            topSummaryCardView.bottomAnchor.constraint(equalTo: footView.bottomAnchor, constant: -8),
            
            topCardPrimaryDecorationView.widthAnchor.constraint(equalToConstant: 156),
            topCardPrimaryDecorationView.heightAnchor.constraint(equalToConstant: 156),
            topCardPrimaryDecorationView.trailingAnchor.constraint(equalTo: topSummaryCardView.trailingAnchor, constant: 48),
            topCardPrimaryDecorationView.topAnchor.constraint(equalTo: topSummaryCardView.topAnchor, constant: -52),
            
            topCardSecondaryDecorationView.widthAnchor.constraint(equalToConstant: 108),
            topCardSecondaryDecorationView.heightAnchor.constraint(equalToConstant: 108),
            topCardSecondaryDecorationView.trailingAnchor.constraint(equalTo: topSummaryCardView.trailingAnchor, constant: 18),
            topCardSecondaryDecorationView.bottomAnchor.constraint(equalTo: topSummaryCardView.bottomAnchor, constant: 36),
            
            topCardTitleLabel.leadingAnchor.constraint(equalTo: topSummaryCardView.leadingAnchor, constant: 22),
            topCardTitleLabel.topAnchor.constraint(equalTo: topSummaryCardView.topAnchor, constant: 22),
            
            topCardDateLabel.leadingAnchor.constraint(equalTo: topCardTitleLabel.leadingAnchor),
            topCardDateLabel.topAnchor.constraint(equalTo: topCardTitleLabel.bottomAnchor, constant: 6),
            
            topCardStatusLabel.trailingAnchor.constraint(equalTo: topSummaryCardView.trailingAnchor, constant: -20),
            topCardStatusLabel.centerYAnchor.constraint(equalTo: topCardTitleLabel.centerYAnchor),
            
            topCardValueLabel.leadingAnchor.constraint(equalTo: topSummaryCardView.leadingAnchor, constant: 24),
            topCardValueLabel.trailingAnchor.constraint(lessThanOrEqualTo: topSummaryCardView.trailingAnchor, constant: -30),
            topCardValueLabel.topAnchor.constraint(equalTo: topCardDateLabel.bottomAnchor, constant: 20),
            
            summaryStatsStackView.leadingAnchor.constraint(equalTo: topSummaryCardView.leadingAnchor, constant: 18),
            summaryStatsStackView.trailingAnchor.constraint(equalTo: topSummaryCardView.trailingAnchor, constant: -18),
            summaryStatsStackView.bottomAnchor.constraint(equalTo: topSummaryCardView.bottomAnchor, constant: -18),
            summaryStatsStackView.heightAnchor.constraint(equalToConstant: 90),
            
            topCardValueLabel.bottomAnchor.constraint(lessThanOrEqualTo: summaryStatsStackView.topAnchor, constant: -20),
            
            distanceStatTitleLabel.leadingAnchor.constraint(equalTo: distanceStatContainerView.leadingAnchor, constant: 16),
            distanceStatTitleLabel.trailingAnchor.constraint(equalTo: distanceStatContainerView.trailingAnchor, constant: -16),
            distanceStatTitleLabel.topAnchor.constraint(equalTo: distanceStatContainerView.topAnchor, constant: 16),
            
            distanceStatValueLabel.leadingAnchor.constraint(equalTo: distanceStatContainerView.leadingAnchor, constant: 16),
            distanceStatValueLabel.trailingAnchor.constraint(equalTo: distanceStatContainerView.trailingAnchor, constant: -16),
            distanceStatValueLabel.topAnchor.constraint(greaterThanOrEqualTo: distanceStatTitleLabel.bottomAnchor, constant: 8),
            distanceStatValueLabel.bottomAnchor.constraint(equalTo: distanceStatContainerView.bottomAnchor, constant: -16),
            
            calorieStatTitleLabel.leadingAnchor.constraint(equalTo: calorieStatContainerView.leadingAnchor, constant: 16),
            calorieStatTitleLabel.trailingAnchor.constraint(equalTo: calorieStatContainerView.trailingAnchor, constant: -16),
            calorieStatTitleLabel.topAnchor.constraint(equalTo: calorieStatContainerView.topAnchor, constant: 16),
            
            calorieStatValueLabel.leadingAnchor.constraint(equalTo: calorieStatContainerView.leadingAnchor, constant: 16),
            calorieStatValueLabel.trailingAnchor.constraint(equalTo: calorieStatContainerView.trailingAnchor, constant: -16),
            calorieStatValueLabel.topAnchor.constraint(greaterThanOrEqualTo: calorieStatTitleLabel.bottomAnchor, constant: 8),
            calorieStatValueLabel.bottomAnchor.constraint(equalTo: calorieStatContainerView.bottomAnchor, constant: -16)
        ])

        refreshValue(label: topCardValueLabel, value: "0", unit: "health_step_noun".localized(), size1: 52, size2: 16)
        refreshValue(label: distanceStatValueLabel, value: "0.000", unit: "health_walk_unit".localized(), size1: 24, size2: 11)
        refreshValue(label: calorieStatValueLabel, value: "0.000", unit: "health_kilo_calorie".localized(), size1: 24, size2: 11)
    }
    
    private func configureSummaryStatCard(_ view: UIView) {
        view.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        view.layer.cornerRadius = 18
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        view.layer.borderWidth = 1
    }
    
    private func setupMetricsSectionHeader() {
        metricsSectionSubtitleLabel.text = "mine_bluetooth_unconnect".localized()
        metricsSectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        metricsSectionSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metricsSectionTitleLabel)
        view.addSubview(metricsSectionSubtitleLabel)
        
        NSLayoutConstraint.activate([
            metricsSectionTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricsSectionTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            metricsSectionTitleLabel.topAnchor.constraint(equalTo: footView.bottomAnchor, constant: 18),
            
            metricsSectionSubtitleLabel.leadingAnchor.constraint(equalTo: metricsSectionTitleLabel.leadingAnchor),
            metricsSectionSubtitleLabel.trailingAnchor.constraint(equalTo: metricsSectionTitleLabel.trailingAnchor),
            metricsSectionSubtitleLabel.topAnchor.constraint(equalTo: metricsSectionTitleLabel.bottomAnchor, constant: 6)
        ])
    }
    
    private func setupDashboardInsightCard() {
        [
            dashboardInsightCardView,
            dashboardInsightChipLabel,
            dashboardInsightTitleLabel,
            dashboardInsightDetailLabel,
            dashboardInsightMetaLabel,
            dashboardInsightDividerView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(dashboardInsightCardView)
        dashboardInsightCardView.addSubview(dashboardInsightChipLabel)
        dashboardInsightCardView.addSubview(dashboardInsightTitleLabel)
        dashboardInsightCardView.addSubview(dashboardInsightDetailLabel)
        dashboardInsightCardView.addSubview(dashboardInsightDividerView)
        dashboardInsightCardView.addSubview(dashboardInsightMetaLabel)
        
        NSLayoutConstraint.activate([
            dashboardInsightCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dashboardInsightCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dashboardInsightCardView.topAnchor.constraint(equalTo: metricsSectionSubtitleLabel.bottomAnchor, constant: 14),
            
            dashboardInsightChipLabel.leadingAnchor.constraint(equalTo: dashboardInsightCardView.leadingAnchor, constant: 18),
            dashboardInsightChipLabel.topAnchor.constraint(equalTo: dashboardInsightCardView.topAnchor, constant: 18),
            
            dashboardInsightTitleLabel.leadingAnchor.constraint(equalTo: dashboardInsightCardView.leadingAnchor, constant: 18),
            dashboardInsightTitleLabel.trailingAnchor.constraint(equalTo: dashboardInsightCardView.trailingAnchor, constant: -18),
            dashboardInsightTitleLabel.topAnchor.constraint(equalTo: dashboardInsightChipLabel.bottomAnchor, constant: 12),
            
            dashboardInsightDetailLabel.leadingAnchor.constraint(equalTo: dashboardInsightTitleLabel.leadingAnchor),
            dashboardInsightDetailLabel.trailingAnchor.constraint(equalTo: dashboardInsightTitleLabel.trailingAnchor),
            dashboardInsightDetailLabel.topAnchor.constraint(equalTo: dashboardInsightTitleLabel.bottomAnchor, constant: 10),
            
            dashboardInsightDividerView.leadingAnchor.constraint(equalTo: dashboardInsightTitleLabel.leadingAnchor),
            dashboardInsightDividerView.trailingAnchor.constraint(equalTo: dashboardInsightTitleLabel.trailingAnchor),
            dashboardInsightDividerView.topAnchor.constraint(equalTo: dashboardInsightDetailLabel.bottomAnchor, constant: 14),
            dashboardInsightDividerView.heightAnchor.constraint(equalToConstant: 1),
            
            dashboardInsightMetaLabel.leadingAnchor.constraint(equalTo: dashboardInsightTitleLabel.leadingAnchor),
            dashboardInsightMetaLabel.trailingAnchor.constraint(equalTo: dashboardInsightTitleLabel.trailingAnchor),
            dashboardInsightMetaLabel.topAnchor.constraint(equalTo: dashboardInsightDividerView.bottomAnchor, constant: 12),
            dashboardInsightMetaLabel.bottomAnchor.constraint(equalTo: dashboardInsightCardView.bottomAnchor, constant: -18)
        ])
    }
    
    private func setupFemaleHealthEntry() {
        [femaleHealthContainerView, femaleHealthGlowView, femaleHealthIconImageView, femaleHealthArrowImageView, femaleHealthTitleLabel, femaleHealthSubtitleLabel, femaleHealthBadgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        femaleHealthContainerView.layer.insertSublayer(femaleHealthGradientLayer, at: 0)
        femaleHealthGradientLayer.colors = femaleHealthEntryGradientColors().map { $0.cgColor }
        femaleHealthGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        femaleHealthGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        femaleHealthGradientLayer.cornerRadius = 22

        femaleHealthGlowView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        femaleHealthGlowView.isUserInteractionEnabled = false
        
        view.addSubview(femaleHealthContainerView)
        femaleHealthContainerView.addSubview(femaleHealthGlowView)
        femaleHealthContainerView.addSubview(femaleHealthIconImageView)
        femaleHealthContainerView.addSubview(femaleHealthBadgeLabel)
        femaleHealthContainerView.addSubview(femaleHealthArrowImageView)
        femaleHealthContainerView.addSubview(femaleHealthTitleLabel)
        femaleHealthContainerView.addSubview(femaleHealthSubtitleLabel)
        femaleHealthHeightConstraint = femaleHealthContainerView.heightAnchor.constraint(equalToConstant: 108)
        
        NSLayoutConstraint.activate([
            femaleHealthContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            femaleHealthContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            femaleHealthContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            femaleHealthHeightConstraint!,

            femaleHealthGlowView.trailingAnchor.constraint(equalTo: femaleHealthContainerView.trailingAnchor, constant: 38),
            femaleHealthGlowView.topAnchor.constraint(equalTo: femaleHealthContainerView.topAnchor, constant: -30),
            femaleHealthGlowView.widthAnchor.constraint(equalToConstant: 132),
            femaleHealthGlowView.heightAnchor.constraint(equalToConstant: 132),
            
            femaleHealthIconImageView.leadingAnchor.constraint(equalTo: femaleHealthContainerView.leadingAnchor, constant: 18),
            femaleHealthIconImageView.topAnchor.constraint(equalTo: femaleHealthContainerView.topAnchor, constant: 18),
            femaleHealthIconImageView.widthAnchor.constraint(equalToConstant: 44),
            femaleHealthIconImageView.heightAnchor.constraint(equalToConstant: 44),
            
            femaleHealthBadgeLabel.trailingAnchor.constraint(equalTo: femaleHealthArrowImageView.leadingAnchor, constant: -12),
            femaleHealthBadgeLabel.topAnchor.constraint(equalTo: femaleHealthContainerView.topAnchor, constant: 16),
            
            femaleHealthArrowImageView.trailingAnchor.constraint(equalTo: femaleHealthContainerView.trailingAnchor, constant: -18),
            femaleHealthArrowImageView.centerYAnchor.constraint(equalTo: femaleHealthContainerView.centerYAnchor),
            femaleHealthArrowImageView.widthAnchor.constraint(equalToConstant: 16),
            femaleHealthArrowImageView.heightAnchor.constraint(equalToConstant: 16),
            
            femaleHealthTitleLabel.leadingAnchor.constraint(equalTo: femaleHealthIconImageView.trailingAnchor, constant: 14),
            femaleHealthTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: femaleHealthBadgeLabel.leadingAnchor, constant: -10),
            femaleHealthTitleLabel.topAnchor.constraint(equalTo: femaleHealthContainerView.topAnchor, constant: 18),
            
            femaleHealthSubtitleLabel.leadingAnchor.constraint(equalTo: femaleHealthTitleLabel.leadingAnchor),
            femaleHealthSubtitleLabel.trailingAnchor.constraint(equalTo: femaleHealthContainerView.trailingAnchor, constant: -44),
            femaleHealthSubtitleLabel.topAnchor.constraint(equalTo: femaleHealthTitleLabel.bottomAnchor, constant: 4),
            femaleHealthSubtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: femaleHealthContainerView.bottomAnchor, constant: -18)
        ])

        let femaleHealthTap = UITapGestureRecognizer(target: self, action: #selector(handleFemaleHealthTapped))
        femaleHealthContainerView.addGestureRecognizer(femaleHealthTap)
        femaleHealthContainerView.isUserInteractionEnabled = true
    }
    
    private func setupMetricsCollectionLayout() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: metricsSectionSubtitleLabel.bottomAnchor, constant: 14),
            collectionView.bottomAnchor.constraint(equalTo: femaleHealthContainerView.topAnchor, constant: -16)
        ])
    }
    
    private func configureEmptyStateView() {
        emptyStateView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        emptyStateView.primaryAction = { [weak self] in
            self?.handlePrimaryEmptyStateAction()
        }
        emptyStateView.secondaryAction = { [weak self] in
            self?.handleSecondaryEmptyStateAction()
        }
        collectionView.backgroundView = emptyStateView
    }
    
    private func preferredTopCardHeight() -> CGFloat {
        let currentHeight = max(view.bounds.height, UIScreen.main.bounds.height)
        return min(322, max(284, currentHeight * 0.34))
    }
    
    private func isCurrentDeviceConnected() -> Bool {
        guard !lastestDeviceMac.isEmpty else {
            return false
        }
        if isXGZT {
            return XGZTBlueToothManager.shared.isconnected()
        }
        return bleSelf.isConnected
    }
    
    private func currentDashboardState() -> HealthDashboardState {
        guard !lastestDeviceMac.isEmpty else {
            return .noDevice
        }
        guard isCurrentDeviceConnected() else {
            return .disconnected
        }
        return currentMetricCount() == 0 ? .noMetrics : .content
    }
    
    private func updateConnectionStatus() {
        let state = currentDashboardState()
        topCardDateLabel.text = formattedTodayString()
        updateTopCardVisuals(for: state)
        
        switch state {
        case .noDevice:
            topCardStatusLabel.text = "mine_unconnect".localized()
            topCardStatusLabel.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            topCardStatusLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
            metricsSectionSubtitleLabel.text = "device_add".localized()
            metricsSectionSubtitleLabel.textColor = UIColor.text_secondary
        case .disconnected:
            topCardStatusLabel.text = "mine_unconnect".localized()
            topCardStatusLabel.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            topCardStatusLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
            metricsSectionSubtitleLabel.text = "mine_bluetooth_unconnect".localized()
            metricsSectionSubtitleLabel.textColor = UIColor.text_secondary
        case .noMetrics:
            topCardStatusLabel.text = "mine_bluetooth_connect".localized()
            topCardStatusLabel.backgroundColor = UIColor.white.withAlphaComponent(0.24)
            topCardStatusLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
            metricsSectionSubtitleLabel.text = "null_data".localized()
            metricsSectionSubtitleLabel.textColor = UIColor.brand
        case .content:
            topCardStatusLabel.text = "mine_bluetooth_connect".localized()
            topCardStatusLabel.backgroundColor = UIColor.white.withAlphaComponent(0.24)
            topCardStatusLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
            metricsSectionSubtitleLabel.text = "\(formattedTodayString())"
            metricsSectionSubtitleLabel.textColor = UIColor.brand
        }
    }
    
    private func updateDashboardInsight() {
        let state = currentDashboardState()
        let presentation = dashboardInsightPresentation(for: state)
        dashboardInsightChipLabel.text = presentation.chipText
        dashboardInsightTitleLabel.text = presentation.titleText
        dashboardInsightDetailLabel.text = presentation.detailText
        dashboardInsightMetaLabel.text = presentation.metaText
        dashboardInsightChipLabel.textColor = presentation.accentColor
        dashboardInsightChipLabel.backgroundColor = presentation.accentColor.withAlphaComponent(0.10)
        dashboardInsightMetaLabel.textColor = presentation.accentColor
        dashboardInsightCardView.layer.borderColor = presentation.accentColor.withAlphaComponent(0.10).cgColor
        dashboardInsightCardView.layer.shadowColor = presentation.accentColor.withAlphaComponent(0.08).cgColor
    }
    
    private func dashboardInsightPresentation(for state: HealthDashboardState) -> DashboardInsightPresentation {
        switch state {
        case .noDevice:
            return DashboardInsightPresentation(
                chipText: "开始健康看板",
                titleText: "连接设备后，这里会自动生成你的每日健康洞察",
                detailText: "首页会结合步数、睡眠、心率等同步结果，优先告诉你今天最值得关注的变化，而不只是展示原始数字。",
                metaText: "先添加设备，再开始同步健康数据",
                accentColor: UIColor.brand
            )
        case .disconnected:
            return DashboardInsightPresentation(
                chipText: "等待同步",
                titleText: "设备已离线，今天的首页洞察暂停在上次同步结果",
                detailText: "重新连接手环后，首页会继续刷新步数、距离、消耗以及健康卡片的最新状态。",
                metaText: "重新连接后自动恢复今日看板",
                accentColor: UIColor(hex: 0x4C7DFF)
            )
        case .noMetrics:
            return DashboardInsightPresentation(
                chipText: "数据生成中",
                titleText: "设备已连接成功，今天的健康摘要还在生成",
                detailText: "继续佩戴手环一段时间后，首页会自动补齐今日步数、消耗和可查看的健康指标内容。",
                metaText: "连接正常，等待首批健康数据写入",
                accentColor: UIColor(hex: 0x1F8BFF)
            )
        case .content:
            let distanceText = formattedInsightMetricText(value: latestDistanceValue, unit: latestDistanceUnitText.isEmpty ? "health_walk_unit".localized() : latestDistanceUnitText)
            let calorieText = formattedInsightMetricText(value: latestCalorieValue, unit: "health_kilo_calorie".localized())
            let metricText = "\(max(currentMetricCount(), 1)) 项健康指标"
            if latestStepCount >= 10000 {
                return DashboardInsightPresentation(
                    chipText: "今日表现",
                    titleText: "今天已完成 \(latestStepCount) 步，活动节奏保持得很好",
                    detailText: "累计 \(distanceText)，约消耗 \(calorieText)，当前 \(metricText) 已进入首页联动展示。",
                    metaText: "建议继续查看睡眠与心率走势，完成今天的健康闭环",
                    accentColor: UIColor.brand
                )
            } else if latestStepCount >= 6000 {
                return DashboardInsightPresentation(
                    chipText: "继续推进",
                    titleText: "今天已经走了 \(latestStepCount) 步，再推进一点就更完整",
                    detailText: "目前累计 \(distanceText)，约消耗 \(calorieText)，首页已同步 \(metricText)。",
                    metaText: "优先把步数拉到更完整区间，再回看其他指标变化",
                    accentColor: UIColor(hex: 0x2E8DFF)
                )
            } else {
                return DashboardInsightPresentation(
                    chipText: "今日提醒",
                    titleText: "今天的活动量还偏低，可以再安排一次轻运动",
                    detailText: "当前仅完成 \(latestStepCount) 步，累计 \(distanceText)，约消耗 \(calorieText)，但 \(metricText) 已经准备好继续跟进。",
                    metaText: "先把活动量拉起来，首页洞察会更完整",
                    accentColor: UIColor(hex: 0x4E7BFF)
                )
            }
        }
    }
    
    private func formattedInsightMetricText(value: Float, unit: String) -> String {
        let formattedValue: String
        if value >= 100 {
            formattedValue = String(format: "%.0f", value)
        } else if value >= 10 {
            formattedValue = String(format: "%.1f", value)
        } else {
            formattedValue = String(format: "%.2f", value)
        }
        return "\(formattedValue) \(unit)"
    }
    
    private func updateFemaleHealthVisibility(animated: Bool) {
        let shouldShow = XGZTBlueToothManager.shared.device?.sex == 1
        updateFemaleHealthEntryContent()
        if shouldShow {
            femaleHealthContainerView.isHidden = false
        }
        femaleHealthHeightConstraint?.constant = shouldShow ? 108 : 0
        femaleHealthContainerView.alpha = shouldShow ? 1 : 0
        femaleHealthContainerView.isUserInteractionEnabled = shouldShow
        
        let updates: () -> Void = { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: updates) { [weak self] _ in
                self?.femaleHealthContainerView.isHidden = !shouldShow
            }
        } else {
            updates()
            femaleHealthContainerView.isHidden = !shouldShow
        }
    }
    
    private func currentMetricCount() -> Int {
        guard !lastestDeviceMac.isEmpty else {
            return 0
        }
        guard bleSelf.isConnected || XGZTBlueToothManager.shared.device != nil else {
            return 0
        }
        if isXGZT {
            var count = 0
            if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) & 1 == 1) {
                count += 1
            }
            if (((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1) {
                count += 1
            }
            if (((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1) {
                count += 1
            }
            if (((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1) {
                count += 1
            }
            xgztCount = count
            return count
        }
        return 4
    }
    
    private func updateTopCardVisuals(for state: HealthDashboardState) {
        topSummaryGradientLayer.colors = dashboardGradientColors(for: state).map { $0.cgColor }
        switch state {
        case .noDevice:
            topCardPrimaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
            topCardSecondaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.07)
            topCardPrimaryDecorationView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            topCardSecondaryDecorationView.transform = .identity
        case .disconnected:
            topCardPrimaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.11)
            topCardSecondaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            topCardPrimaryDecorationView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            topCardSecondaryDecorationView.transform = CGAffineTransform(translationX: -4, y: 0)
        case .noMetrics:
            topCardPrimaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            topCardSecondaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            topCardPrimaryDecorationView.transform = .identity
            topCardSecondaryDecorationView.transform = CGAffineTransform(translationX: -6, y: 2)
        case .content:
            topCardPrimaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.14)
            topCardSecondaryDecorationView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
            topCardPrimaryDecorationView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            topCardSecondaryDecorationView.transform = CGAffineTransform(translationX: -8, y: 4)
        }
    }

    private func updateFemaleHealthEntryContent() {
        let config = FemaleCycleDataManager.shared.getCycleConfiguration()
        femaleHealthGradientLayer.colors = femaleHealthEntryGradientColors().map { $0.cgColor }
        if config.isConfigured {
            femaleHealthBadgeLabel.text = "female_cycle_today".localized()
            femaleHealthSubtitleLabel.text = "\(config.periodDays)" + "female_cycle_days_unit".localized() + " · \(config.cycleLength)" + "female_cycle_days_unit".localized()
        } else {
            femaleHealthBadgeLabel.text = "female_cycle_today".localized()
            femaleHealthSubtitleLabel.text = "female_cycle_subtitle".localized()
        }
    }

    private func animateFemaleHealthEntrySelection(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.femaleHealthContainerView.transform = CGAffineTransform(scaleX: 0.985, y: 0.985)
        } completion: { _ in
            UIView.animate(withDuration: 0.24, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.16, options: [.allowUserInteraction, .curveEaseOut]) {
                self.femaleHealthContainerView.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    private func updateEmptyState() {
        let state = currentDashboardState()
        
        switch state {
        case .noDevice:
            emptyStateView.configure(
                image: UIImage(named: "health_empty_device") ?? UIImage(named: "health_null_data") ?? UIImage(systemName: "heart.text.square.fill"),
                title: "device_add".localized(),
                subtitle: "Add your first bracelet to unlock step tracking, heart rate cards and daily health insights.".localizedFallback("添加你的第一块手环后，这里会展示步数、心率和每日健康摘要。"),
                primaryTitle: "device_add".localized(),
                secondaryTitle: nil
            )
        case .disconnected:
            emptyStateView.configure(
                image: UIImage(named: "health_empty_disconnected") ?? UIImage(named: "health_null_data") ?? UIImage(systemName: "heart.text.square.fill"),
                title: "mine_bluetooth_unconnect".localized(),
                subtitle: "Reconnect your bracelet to refresh today's health dashboard and sync the latest data.".localizedFallback("重新连接手环后，这里会自动刷新今天的健康看板与最新数据。"),
                primaryTitle: "device_change".localized(),
                secondaryTitle: "device_scan".localized()
            )
        case .noMetrics:
            emptyStateView.configure(
                image: UIImage(named: "health_empty_metrics") ?? UIImage(named: "health_null_data") ?? UIImage(systemName: "heart.text.square.fill"),
                title: "null_data".localized(),
                subtitle: "Today's health data is still on the way. Keep wearing the bracelet and come back soon.".localizedFallback("今天的健康数据还在生成中，继续佩戴手环，稍后回来这里查看。"),
                primaryTitle: nil,
                secondaryTitle: nil
            )
        case .content:
            emptyStateView.configure(
                image: nil,
                title: "",
                subtitle: "",
                primaryTitle: nil,
                secondaryTitle: nil
            )
        }
        
        emptyStateView.isHidden = state == .content
        collectionView.alwaysBounceVertical = state == .content
    }
    
    private func updateDashboardPresentation(animated: Bool) {
        updateConnectionStatus()
        updateDashboardInsight()
        updateFemaleHealthVisibility(animated: animated)
        updateEmptyState()
    }

    private func dashboardGradientColors(for state: HealthDashboardState) -> [UIColor] {
        switch state {
        case .noDevice:
            return [UIColor(hex: 0x6DAEFF), UIColor.brand]
        case .disconnected:
            return [UIColor(hex: 0x3A92FF), UIColor(hex: 0x0754C7)]
        case .noMetrics:
            return [UIColor(hex: 0x5BA5FF), UIColor(hex: 0x0A6FE8)]
        case .content:
            return [UIColor.brand, UIColor(hex: 0x53AEFF)]
        }
    }

    private func femaleHealthEntryGradientColors() -> [UIColor] {
        let config = FemaleCycleDataManager.shared.getCycleConfiguration()
        if config.isConfigured {
            return [UIColor.brand, UIColor(hex: 0x5E8BFF)]
        }
        return [UIColor(hex: 0x2E90FF), UIColor(hex: 0x6EBEFF)]
    }
    
    private func startPremiumAnimationsIfNeeded() {
        stopPremiumAnimations()
    }
    
    private func stopPremiumAnimations() {
        [
            topCardPrimaryDecorationView.layer,
            topCardSecondaryDecorationView.layer,
            femaleHealthBadgeLabel.layer
        ].forEach { layer in
            layer.removeAllAnimations()
        }
    }
    
    private func handlePrimaryEmptyStateAction() {
        addDevice(self)
    }
    
    private func handleSecondaryEmptyStateAction() {
        addDevice(self)
    }
    
    private func formattedTodayString() -> String {
        return DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
    }
    
    private func reloadMetricsCollection(animated: Bool = true) {
        let now = CACurrentMediaTime()
        let canAnimate = false
        shouldAnimateMetricCellsOnNextDisplay = canAnimate
        animatedMetricIndexPaths.removeAll()
        if canAnimate {
            lastMetricEntranceAnimationAt = now
        }
        collectionView.reloadData()
    }
    
    private func configureMetricCell(_ cell: HealthCollectionViewCell, iconName: String, title: String, value: NSMutableAttributedString, accentColor: UIColor) {
        cell.configureCell(icon: UIImage(named: iconName), leftTitle: title, rightTitle: value, accentColor: accentColor)
    }
    
    private func metricAccentColor(for iconName: String) -> UIColor {
        switch iconName {
        case "health_heart":
            return UIColor.brand
        case "health_sleep":
            return UIColor(hex: 0x3C86FF)
        case "health_bloodpressure":
            return UIColor(hex: 0x2190FF)
        case "health_bloodoxygen":
            return UIColor(hex: 0x58B8FF)
        default:
            return UIColor.brand
        }
    }
    
    private func makeTopValueAttributedText(value: String, unit: String, size1: CGFloat, size2: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let bigFont = UIFont.systemFont(ofSize: size1, weight: .bold)
        let firstAttributes: [NSAttributedString.Key: Any] = [
            .font: bigFont,
            .foregroundColor: UIColor.white
        ]
        let firstString = NSAttributedString(string: value, attributes: firstAttributes)
        attributedString.append(firstString)

        let smallFont = UIFont.systemFont(ofSize: size2, weight: .semibold)
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: UIColor.white
        ]
        let secondString = NSAttributedString(string: unit, attributes: secondAttributes)
        attributedString.append(secondString)
        
        let baselineOffset = (bigFont.capHeight - smallFont.capHeight) / 2
        attributedString.addAttributes([.baselineOffset: baselineOffset], range: NSRange(location: firstString.length, length: secondString.length))
        return attributedString
    }
    
    private func animateTopValueChangeIfNeeded(label: UILabel, value: String, unit: String, size1: CGFloat, size2: CGFloat) {
        label.textAlignment = .center
        
        guard let targetValue = Double(value) else {
            label.attributedText = makeTopValueAttributedText(value: value, unit: unit, size1: size1, size2: size2)
            return
        }
        
        let key = ObjectIdentifier(label)
        let currentValue = numericAnimationStates[key]?.currentValue ?? renderedNumericValues[key] ?? 0
        renderedNumericValues[key] = targetValue
        
        guard label.window != nil else {
            label.attributedText = makeTopValueAttributedText(value: formattedNumericValue(targetValue, decimals: decimalCount(for: value)), unit: unit, size1: size1, size2: size2)
            return
        }
        
        if abs(currentValue - targetValue) < 0.0005 {
            label.attributedText = makeTopValueAttributedText(value: formattedNumericValue(targetValue, decimals: decimalCount(for: value)), unit: unit, size1: size1, size2: size2)
            return
        }
        
        let state = NumericLabelAnimationState(
            label: label,
            startValue: currentValue,
            targetValue: targetValue,
            startTime: CACurrentMediaTime(),
            duration: targetValue >= currentValue ? 0.8 : 0.55,
            decimals: decimalCount(for: value),
            unit: unit,
            size1: size1,
            size2: size2
        )
        numericAnimationStates[key] = state
        startNumberDisplayLinkIfNeeded()
    }
    
    private func decimalCount(for value: String) -> Int {
        guard let dotIndex = value.firstIndex(of: ".") else {
            return 0
        }
        return value.distance(from: value.index(after: dotIndex), to: value.endIndex)
    }
    
    private func formattedNumericValue(_ value: Double, decimals: Int) -> String {
        if decimals == 0 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.\(decimals)f", value)
    }
    
    private func startNumberDisplayLinkIfNeeded() {
        guard numericDisplayLink == nil else {
            return
        }
        let displayLink = CADisplayLink(target: self, selector: #selector(handleNumericDisplayLink))
        displayLink.add(to: .main, forMode: .common)
        numericDisplayLink = displayLink
    }
    
    private func stopNumberAnimations() {
        numericDisplayLink?.invalidate()
        numericDisplayLink = nil
        
        for state in numericAnimationStates.values {
            if let label = state.label {
                label.attributedText = makeTopValueAttributedText(
                    value: formattedNumericValue(state.targetValue, decimals: state.decimals),
                    unit: state.unit,
                    size1: state.size1,
                    size2: state.size2
                )
            }
        }
        numericAnimationStates.removeAll()
    }
    
    @objc private func handleNumericDisplayLink() {
        let now = CACurrentMediaTime()
        var completedKeys: [ObjectIdentifier] = []
        
        for (key, state) in numericAnimationStates {
            guard let label = state.label else {
                completedKeys.append(key)
                continue
            }
            
            let progress = min(max((now - state.startTime) / state.duration, 0), 1)
            let easedProgress = 1 - pow(1 - progress, 3)
            let currentValue = state.startValue + (state.targetValue - state.startValue) * easedProgress
            state.currentValue = currentValue
            label.attributedText = makeTopValueAttributedText(
                value: formattedNumericValue(currentValue, decimals: state.decimals),
                unit: state.unit,
                size1: state.size1,
                size2: state.size2
            )
            
            if progress >= 1 {
                renderedNumericValues[key] = state.targetValue
                completedKeys.append(key)
            }
        }
        
        completedKeys.forEach { numericAnimationStates.removeValue(forKey: $0) }
        if numericAnimationStates.isEmpty {
            numericDisplayLink?.invalidate()
            numericDisplayLink = nil
        }
    }
    
    func onSetupBigData(){
     
        mBigDataManager?.cmdBigDataMonitor({ [self] bigData in
            let status = bigData.mResult
            if status == .get{
                NSLog("--->ALi Get:")
                NSLog("%@",JL_Tools.dataChange(toString: bigData.mData))
                AliConnectMananger_C.shared.bleDataReceived(data: bigData.mData)
                
            }else if status == .sendSuccess{
                NSLog("--->ALi Send Success:\(bigData.mIndex)")
                
                JL_Tools.mainTask {
                    AudioServicesPlaySystemSound(1519);
                    self.sendTimesOk = self.sendTimesOk+1
                    let str = "GET:\(self.getTimes)    SEND(ok:\(self.sendTimesOk)  fail:\(self.sendTimesFail))"
                    //self.subLabel.text = str
                }

            }else{
                NSLog("--->ALi Send Fail! (Index:\(bigData.mIndex) Reason:\(bigData.mResult.rawValue))")

                JL_Tools.mainTask {
                    AudioServicesPlaySystemSound(1002);
                    self.sendTimesFail = self.sendTimesFail+1
                    let str = "GET:\(self.getTimes)    SEND(ok:\(self.sendTimesOk)  fail:\(self.sendTimesFail))"
                    //self.subLabel.text = str
                }
            }
        })
    }
    
    @objc private func handleDidEnterBackgroundNotification() {
        stopPremiumAnimations()
        stopNumberAnimations()
        if hud != nil {
            hud?.hideHud()
        }
    }
    
    @objc private func handleDidEnterForgroundNotification() {
        updateDashboardPresentation(animated: false)
        startPremiumAnimationsIfNeeded()
        if XGZTBlueToothManager.shared.centralManager?.state == .poweredOn {
            DispatchQueue.main.async {
                [weak self] in
                if self?.alertController != nil {
                    self?.alertController?.dismiss(animated: false)
                    self?.alertController = nil
                }
            }
            if cacheDevices.count >= 1 && !XGZTBlueToothManager.shared.isconnected() {
                for device in cacheDevices {
                    if device.max == lastestDeviceMac {
                        XGZTBlueToothManager.shared.connectAndScan(to: lastestDeviceMac, deviceName: device.deviceName ?? "e watch")
                    }
                }
            }
            return
        }
        if XGZTBlueToothManager.shared.centralManager?.state == .poweredOff {
            DispatchQueue.main.async {
                [weak self] in
                if self?.alertController != nil {
                    return
                }
                self?.alertController = UIAlertController(
                    title: nil,
                    message: "mine_bluetooth_unconnect".localized(),
                    preferredStyle: .alert
                )
                self?.alertController?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                let action = UIAlertAction(
                    title: "push_to_bt_settings".localized(),
                    style: .default
                ) { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, completionHandler: nil)
                    }
                }
                self?.alertController?.addAction(action)
                if self?.alertController != nil {
                    self?.navigationController?.tabBarController?.present(self!.alertController!, animated: true)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保 TabBar 显示
        tabBarController?.tabBar.isHidden = false
        updateDashboardPresentation(animated: false)
        
        if !isFirst {
            readDBStep() // 从本地数据库中读取步数数据
        }
        isFirst = true
        if isXGZT {
            return
        }
        readDBHeart() // 从本地数据库中读取心跳数据
        readDBBlood() // 从本地数据库中读取血压数据
        readDBOxygen() // 从本地数据库中读取血氧数据
        readDBSleep() // 从本地数据库中读取睡眠数据
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadMetricsCollection()
        updateDashboardPresentation(animated: false)
        startPremiumAnimationsIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPremiumAnimations()
        stopNumberAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topSummaryGradientLayer.frame = topSummaryCardView.bounds
        topCardPrimaryDecorationView.layer.cornerRadius = topCardPrimaryDecorationView.bounds.height / 2
        topCardSecondaryDecorationView.layer.cornerRadius = topCardSecondaryDecorationView.bounds.height / 2
        collectionView.backgroundView?.frame = collectionView.bounds
        dashboardInsightCardView.layer.shadowPath = UIBezierPath(roundedRect: dashboardInsightCardView.bounds, cornerRadius: dashboardInsightCardView.layer.cornerRadius).cgPath
        femaleHealthContainerView.layer.shadowPath = UIBezierPath(roundedRect: femaleHealthContainerView.bounds, cornerRadius: femaleHealthContainerView.layer.cornerRadius).cgPath
        femaleHealthGradientLayer.frame = femaleHealthContainerView.bounds
        femaleHealthGlowView.layer.cornerRadius = femaleHealthGlowView.bounds.height / 2
        
        let preferredHeight = preferredTopCardHeight()
        if abs((footViewHeightConstraint?.constant ?? 0) - preferredHeight) > 0.5 {
            footViewHeightConstraint?.constant = preferredHeight
        }
        
        if abs(collectionView.bounds.width - lastKnownCollectionWidth) > 0.5 {
            lastKnownCollectionWidth = collectionView.bounds.width
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    deinit {
        stopPremiumAnimations()
        stopNumberAnimations()
        unregisterNotification()
        currentDialog?.removeFromSuperview()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("HealthViewController"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowLoading(_:)), name: Notification.Name("HealthVCLoading"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func refreshStepValue(unit: Float, v: Float) {
        latestCalorieValue = v
        refreshValue(label: calorieStatValueLabel, value: String(format: "%.3f", v), unit: "health_kilo_calorie".localized(), size1: 24, size2: 11)
        if isXGZT {
            if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                let new = unit * 62 / 100
                let truncated = (new * 1000).rounded(.towardZero)/1000
                latestDistanceValue = Float(truncated)
                latestDistanceUnitText = "mile".localized()
                refreshValue(label: distanceStatValueLabel, value: String(format: "%.3f", truncated), unit: "mile".localized(), size1: 24, size2: 11)
            } else {
                latestDistanceValue = unit
                latestDistanceUnitText = "health_walk_unit".localized()
                refreshValue(label: distanceStatValueLabel, value: String(format: "%.3f", unit), unit: "health_walk_unit".localized(), size1: 24, size2: 11)
            }
        } else {
            latestDistanceValue = unit
            latestDistanceUnitText = "health_walk_unit".localized()
            refreshValue(label: distanceStatValueLabel, value: String(format: "%.3f", unit), unit: "health_walk_unit".localized(), size1: 24, size2: 11)
        }
        if isViewLoaded {
            updateDashboardInsight()
        }
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "step" {
            let step = isXGZT ? (XGZTBlueToothManager.shared.device?.currentStep ?? 0) : bleSelf.step
            DispatchQueue.main.async {
                [weak self] in
                
                self?.refreshValue(label: self?.topCardValueLabel, value: "\(step)", unit: "health_step_noun".localized(), size1: 52, size2: 16)
            }
            if (isXGZT) {
                let distance = Int(XGZTBlueToothManager.shared.device?.height ?? 0) * 415 / 1000
                let unit = step * distance
                let v = unit * Int(XGZTBlueToothManager.shared.device?.weight ?? 0) * 55
                DispatchQueue.main.async {
                    [weak self] in
                    let truncated = (Float(v) / 10000).rounded(.towardZero) / 1000
                    self?.refreshStepValue(unit: Float(unit) / 100000, v: Float(truncated))
                    XLogger.shared.log("距离：\(unit), 千卡：\(v)")
                }
            } else {
                let distance = bleSelf.distance
                let unit = Float(distance) / 1000
            
                let cal = bleSelf.cal
                let v = Float(cal) / 1000
                DispatchQueue.main.async {
                    [weak self] in
                    self?.refreshStepValue(unit: unit, v: v)
                }
            }
        } else if objc == "sleep" {
            DispatchQueue.main.async {
                [weak self] in
                if (isXGZT) {
                    let sleep = XGZTBlueToothManager.shared.device?.currentSleep ?? 0
                    if sleep > 0 {
                        let h = sleep / 60
                        let m = sleep % 60
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.reloadMetricsCollection()
                    } else {
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.reloadMetricsCollection()
                    }
                } else {
                    let array = BLEManager.shared.sleepArray[0]
                    if array.count > 0 {
                        let arr = BLEManager.shared.readSleepData(array: array) // 获得睡眠时间
                        let total = arr[1] + arr[2]
                        let h = total / 60
                        let m = total % 60
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.reloadMetricsCollection()
                        
                    } else {
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.reloadMetricsCollection()
                    }
                }
            }
        } else if objc == "heart" {
            if isXGZT {
                DispatchQueue.main.async {
                    [weak self] in
                    var heart = 0
                    heart = XGZTBlueToothManager.shared.device?.currentHeartrate ?? 0
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if heart > 0 {
                        self?.arrayValue[0] = v
                        self?.reloadMetricsCollection()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    if BLEManager.shared.heartArray.count == 0 {
                        return
                    }
                    var heart = 0
                    heart = BLEManager.shared.heartArray[0].heart
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if heart > 0 {
                        self?.arrayValue[0] = v
                        self?.reloadMetricsCollection()
                    }
                }
            }
        } else if objc == "blood" {
            if isXGZT {
                DispatchQueue.main.async {
                    [weak self] in
                    var min = 0
                    var max = 0
                    min = XGZTBlueToothManager.shared.device?.currentDiastolicpressure ?? 0
                    max = XGZTBlueToothManager.shared.device?.currentSystolicpressure ?? 0
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if min > 0 {
                        self?.arrayValue[2] = v
                        self?.reloadMetricsCollection()
                        UserDefaults.standard.setValue("\(max)/\(min)", forKey: "blood")
                        UserDefaults.standard.synchronize()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    if BLEManager.shared.bloodArray.count == 0 {
                        return
                    }
                    var min = 0
                    var max = 0
                    min = BLEManager.shared.bloodArray[0].min
                    max = BLEManager.shared.bloodArray[0].max
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if min > 0 {
                        self?.arrayValue[2] = v
                        self?.reloadMetricsCollection()
                        UserDefaults.standard.setValue("\(max)/\(min)", forKey: "blood")
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        } else if objc == "oxygen" {
            if isXGZT {
                DispatchQueue.main.async {
                    [weak self] in
                    var value = 0
                    value = XGZTBlueToothManager.shared.device?.currentOxygen ?? 0
                    if value > 100 {
                        value = 0
                    }
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if value > 0 {
                        self?.arrayValue[3] = v
                        self?.reloadMetricsCollection()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    var value = 0
                    if BLEManager.shared.oxygenArray.count > 0 {
                        value = BLEManager.shared.oxygenArray[0].oxygen
                    } else {
                        value = 0
                    }
                    if value > 100 {
                        value = 0
                    }
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if value > 0 {
                        self?.arrayValue[3] = v
                        self?.reloadMetricsCollection()
                    }
                }
            }
        } else if objc == "delete" {
            XLogger.shared.log("执行删除设备的动作")
            let userinfo = notification.userInfo as? [String : String]
            var mac = userinfo?["mac"] ?? ""
            if mac.count == 0 {
                mac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
            }
            if mac.count > 0 {
                XLogger.shared.log("执行删除设备的动作: \(mac)")
                for device in DeviceManager.shared.devices {
                    if device.mac == mac {
                        if let model = try? BLEModel.er.array("mac = '\(mac)'").first {
                            try? model.er.delete()
                            XLogger.shared.log("执行删除设备的动作标志成功")
                        }
                        break
                    }
                }
            }
            if mac.count == 0 && DeviceManager.shared.devices.count == 1 {
                try? BLEModel.er.deleteAll() // 删除所有设备
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                [weak self] in
                DeviceManager.shared.initializeDevices()

                self?.refreshDBStep()
                self?.refreshDBHeart()
                self?.refreshDBSleep()
                self?.refreshDBBlood()
                self?.refreshDBOxygen()
                
                if DeviceManager.shared.devices.count == 0 {
                    self?.readDBStep(null: true)
                }
            }
        } else if objc == "refresh" {
            DispatchQueue.main.async {
                [weak self] in
                self?.reloadMetricsCollection()
            }
        } else if objc == "head" {
            
        } else if objc == "scan" {
            didUpdateBLEModels(models: bleSelf.bleModels)
        } else if objc == "connected" { // 设备连接成功
            var bTemp = false
            if currentModel != nil {
                if let model = try? BLEModel.er.fromRealm(with: "\(currentModel.mac)"), model.mac.count > 0 {
                    XLogger.shared.log("数据库已经有该设备")
                } else {
                    bTemp = true
                }
            } else {
                bTemp = true
            }
            if bTemp {
                XLogger.shared.log("将设备添加到数据库里面")
                currentModel = BLEModel()
                currentModel.isBond = bleSelf.bleModel.isBond
                currentModel.uuidString = bleSelf.bleModel.uuidString
                currentModel.name = bleSelf.bleModel.name
                currentModel.localName = "ITIME"
                currentModel.rssi = bleSelf.bleModel.rssi
                currentModel.mac = bleSelf.bleModel.mac
                currentModel.hardwareVersion = bleSelf.bleModel.hardwareVersion
                currentModel.firmwareVersion = bleSelf.bleModel.firmwareVersion
                currentModel.vendorNumberASCII = bleSelf.bleModel.vendorNumberASCII
                currentModel.vendorNumberString = bleSelf.bleModel.vendorNumberString
                currentModel.internalNumber = bleSelf.bleModel.internalNumber
                currentModel.internalNumberString = bleSelf.bleModel.internalNumberString
                currentModel.imageName = "produce_image_no.2"
                try? currentModel?.er.save(update: true)
                DeviceManager.shared.initializeDevices() // 重新刷新绑定的设备
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
                NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: "1")
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateDashboardPresentation(animated: false)
        }
    }
    
    // 假设这是你的数据获取回调
    func didUpdateBLEModels(models: [TJDWristbandSDK.WUBleModel]) {
        // 过滤掉 mac 为空或者长度为 0 的设备
        bleSelf.bleModels = models.filter { $0.mac.count > 0 }
    }

    
    @objc private func handleShowLoading(_ notification: Notification) {
        let obj = notification.object as? Int ?? 0
        if obj == 0 {
            DispatchQueue.main.async {
                [weak self] in
                if UIApplication.shared.applicationState == .background {
                    return
                }
                if self?.alertController != nil {
                    self?.alertController?.dismiss(animated: false)
                    self?.alertController = nil
                }
            }
            
            return
        }
        if obj == 1 {
            DispatchQueue.main.async {
                [weak self] in
                if UIApplication.shared.applicationState == .background {
                    return
                }
                if self?.alertController != nil {
                    return
                }
                self?.alertController = UIAlertController(
                    title: nil,
                    message: "mine_bluetooth_unconnect".localized(),
                    preferredStyle: .alert
                )
                self?.alertController?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                let action = UIAlertAction(
                    title: "push_to_bt_settings".localized(),
                    style: .default
                ) { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, completionHandler: nil)
                    }
                }
                self?.alertController?.addAction(action)
                if self?.alertController != nil {
                    self?.navigationController?.tabBarController?.present(self!.alertController!, animated: true)
                }
            }
            return
        }
        if obj == 2 {
            if isSupportAlipay {
                checkFGSStatus() // 连接成功后，再检查
            }
            XLogger.shared.log("显示loading图片")
            if hud != nil {
                hud?.dismiss(animated: false)
                hud = nil
            }
            if let delegate  = UIApplication.shared.delegate as? AppDelegate {
                hud = JGProgressHUD(style: .light)
                let gifImage = UIImage.gifImageWithName("loading")
                let imageView = UIImageView(image: gifImage)
                let indicatorView = JGProgressHUDImageIndicatorView(contentView: imageView)
                hud?.indicatorView = indicatorView
                hud?.textLabel.text = "\("sync_data".localized())0/9"
                hud?.show(in: delegate.window ?? UIView())
            }
            startLoadingViewCheckTimer()
            return
        }
        if obj == 3 {
            endLoadingViewCheckTimer()
            DispatchQueue.main.async {
                [weak self] in
                if self?.currentProgress ?? 0 > 1 {
                    self?.hud?.textLabel.text = "\("sync_data".localized())9/9"
                } else {
                    var i = 2
                    self?.hud?.textLabel.text = "\("sync_data".localized())\(i)/9"
                    // 创建一个计时器，每秒增加i直到i达到9
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        if i < 9 {
                            i += 1
                            self?.hud?.textLabel.text = "\("sync_data".localized())\(i)/9"
                        } else {
                            timer.invalidate() // 停止计时器
                        }
                    }
                }
                self?.currentProgress = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.hud?.dismiss(animated: false)
                }
            }
            if isXGZT {
                return
            }
            manager.syncTemprature() //  连接成功后，则同步天气。
            BLEManager.shared.currentReadProgress = 0
            if bleSelf.isConnected == false {
                continueReadFootValueTimer?.invalidate()
                continueReadFootValueTimer = nil
            }
            if continueReadFootValueTimer != nil {
                return
            }
            continueReadFootValueTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { t in
                if BLEManager.shared.needContinueRead() {
                    BLEManager.shared.startContinueRead() // 每秒都读取一下步数
                }
            })
            RunLoop.current.add(continueReadFootValueTimer!, forMode: .common)
            
        }
        if obj == 100 {
            let userinfo = notification.userInfo as? [String : String]
            currentProgress = Int(userinfo?["msg"] ?? "0") ?? 0
            let msg = "\("sync_data".localized())\(currentProgress)/9"
            DispatchQueue.main.async {
                [weak self] in
                self?.hud?.textLabel.text = msg
            }
        }
        if obj == 1000 {
            XLogger.shared.log("显示loading图片")
            if hud != nil {
                hud?.dismiss(animated: false)
                hud = nil
            }
            if let delegate  = UIApplication.shared.delegate as? AppDelegate {
                hud = JGProgressHUD(style: .light)
                let gifImage = UIImage.gifImageWithName("loading")
                let imageView = UIImageView(image: gifImage)
                let indicatorView = JGProgressHUDImageIndicatorView(contentView: imageView)
                hud?.indicatorView = indicatorView
                hud?.textLabel.text = "\("sync_data".localized())"
                hud?.show(in: delegate.window ?? UIView())
            }
            startLoadingViewCheckTimer()
        }
        if obj == 2000 {
            endLoadingViewCheckTimer()
            DispatchQueue.main.async {
                [weak self] in
                self?.hud?.dismiss(animated: false)
                self?.updateDashboardPresentation(animated: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                [weak self] in
                guard let s = self else {
                    return
                }
                s.manager.syncTemprature(flag: 1) //  连接成功后，则同步天气。
            }
        }
        if obj == 10000 {
            startPhoto()
        }
        if obj == 10001 {
            takePhoto()
        }
        if obj == 10002 {
            closePhoto()
        }
    }
    
    private func startLoadingViewCheckTimer() {
        XLogger.shared.log("张晓飞：启动加载loading的检查")
        endLoadingViewCheckTimer()
        loadingViewCheckTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false, block: { (timer) in
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3)
        })
        RunLoop.current.add(loadingViewCheckTimer!, forMode: .common)
    }
    
    private func endLoadingViewCheckTimer() {
        loadingViewCheckTimer?.invalidate()
        loadingViewCheckTimer = nil
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? HealthDetailViewController else {
            return
        }
        vc.colors = detailGradientColors(for: flag)
        vc.type = flag
    }
    
    private func detailGradientColors(for type: Int) -> [UIColor] {
        switch type {
        case 2:
            return [UIColor.kFF5E46, UIColor(hex: 0xFF8D64)]
        case 3:
            return [UIColor.k7A61FF, UIColor(hex: 0xA78BFF)]
        case 4:
            return [UIColor.kFFB642, UIColor(hex: 0xFF8A54)]
        case 5:
            return [UIColor.k08CCCC, UIColor(hex: 0x4B8DFF)]
        default:
            return [UIColor.brand, UIColor(hex: 0x53AEFF)]
        }
    }

    private func availableDetailTypes() -> [Int] {
        guard isXGZT else {
            return [2, 3, 4, 5]
        }
        var types: [Int] = []
        let flags = XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0
        if flags & 1 == 1 {
            types.append(2)
        }
        if (flags >> 4) & 1 == 1 {
            types.append(3)
        }
        if (flags >> 2) & 1 == 1 {
            types.append(4)
        }
        if (flags >> 1) & 1 == 1 {
            types.append(5)
        }
        return types
    }
    
    private func presentHealthDetail(type: Int) {
        let palette = detailGradientColors(for: type)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let vc = HealthDetailViewController()
        vc.type = type
        vc.colors = palette
        vc.hidesBottomBarWhenPushed = true
        vc.prefersSharedTransition = false
        
        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentFemaleHealthFlow(destination: UIViewController) {
        destination.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
    }
    
    // MARK: - Action
    
    @objc func handleFootCount() {
        flag = 0
        presentHealthDetail(type: 0)
    }

    @objc func handleFemaleHealthTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        animateFemaleHealthEntrySelection { [weak self] in
            guard let self else { return }
            let config = FemaleCycleDataManager.shared.getCycleConfiguration()
            let hasConfigured = config.isConfigured

            if hasConfigured {
                XLogger.shared.log("女性健康已配置，跳转到日历页面")
                let vc = FemaleCycleCalendarViewController()
                self.presentFemaleHealthFlow(destination: vc)
            } else {
                XLogger.shared.log("女性健康未配置，跳转到设置页面")
                let vc = FemaleHealthViewController()
                self.presentFemaleHealthFlow(destination: vc)
            }
        }
    }

    @IBAction func addDevice(_ sender: Any) {
        
        // 获取导航栏按钮的视图
        if let rightBarButton = self.navigationItem.rightBarButtonItem,
           let view = rightBarButton.value(forKey: "view") as? UIView {
            // 设置锚点视图
            dropDown.anchorView = view
            dropDown.bottomOffset = CGPoint(x: 0, y: view.bounds.height)
            dropDown.show()
        }
    }
    
    private func refreshValue(label: UILabel?, value: String, unit: String, size1: CGFloat, size2: CGFloat) {
        guard let label else {
            return
        }
        if label === topCardValueLabel {
            latestStepCount = Int(value) ?? 0
        }
        animateTopValueChangeIfNeeded(label: label, value: value, unit: unit, size1: size1, size2: size2)
        if isViewLoaded, label === topCardValueLabel {
            updateDashboardInsight()
        }
    }
    
    // 读取数据库内缓存数据
    private func readDBStep(null: Bool = false) {
        if null {
            refreshValue(label: topCardValueLabel, value: "\(0)", unit: "health_step_noun".localized(), size1: 52, size2: 16)
            refreshStepValue(unit: 0, v: 0)
            return
        }
        let time = Int(Date().zeroTimeStamp())
        let models = try? DStepModel.er.array("timeStamp > \(time) AND mac = '\(lastestDeviceMac)'")
        XLogger.shared.log("数据库里\(lastestDeviceMac)步数晚于\(time)的数据总条数：\(models?.count ?? 0)")
        var step = 0
        var distance = 0
        var cal = 0
        let count = models?.count ?? 0
        for i in 0..<count {
            step += models?[i].step ?? 0
            distance += models?[i].distance ?? 0
            cal += models?[i].cal ?? 0
        }
        refreshValue(label: topCardValueLabel, value: "\(step)", unit: "health_step_noun".localized(), size1: 52, size2: 16)
        let unit = Float(distance) / 1000
        let v = Float(cal) / 1000
        refreshStepValue(unit: unit, v: v)
    }
    
    private func refreshDBStep() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DStepModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBHeart() {
        let stamp = Int(Date().zeroTimeStamp())
        let a = try? DHeartRateModel.er.array("timeStamp>=\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        let models = a?.sorted {$0.timeStamp > $1.timeStamp}
        XLogger.shared.log("数据库里心跳的数据总条数：\(models?.count ?? 0)")
        
        let b = try? DHeartRateModel.er.last("mac='\(lastestDeviceMac)'")
        let heart = b?.heartRate ?? 0
        
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[0] = v
        reloadMetricsCollection()
    }
    
    private func refreshDBHeart() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DHeartRateModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBSleep() {
        let value = Int(Date().zeroTimeStamp())
        let models = try? DSleepModel.er.array("timeStamp>=\(value - 2 * 60 * 60) AND timeStamp<\(value + 10 * 60 * 60) AND mac = '\(lastestDeviceMac)'")
        XLogger.shared.log("数据库里睡眠的数据总条数：\(models?.count ?? 0)")
        var array: [SleepModel] = []
        if models != nil {
            for model in models! {
                let m = SleepModel()
                m.uuidString = model.uuidString
                m.mac = model.mac
                m.timeStamp = model.timeStamp
                m.state = model.state
                array.append(m)
            }
        }
        if array.count > 0 {
            BLEManager.shared.sleepArray[0] = array
            let arr = BLEManager.shared.readSleepData(array: array) // 获得睡眠时间
            let total = arr[1] + arr[2]
            let h = total / 60
            let m = total % 60
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrayValue[1] = arrStr
            reloadMetricsCollection()
            
        } else {
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrayValue[1] = arrStr
            reloadMetricsCollection()
        }
    }
    
    private func refreshDBSleep() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DSleepModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBBlood() {
        let models = try? DBloodModel.er.array("mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        XLogger.shared.log("数据库里血压的数据总条数：\(models?.count ?? 0)")
        var min = 0
        var max = 0
        if models?.count ?? 0 > 0 {
            min = models?[0].min ?? 0
            max = models?[0].max ?? 0
        }
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[2] = v
        reloadMetricsCollection()
    }
    
    private func refreshDBBlood() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DBloodModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBOxygen() {
        let models = try? DOxygenModel.er.array("mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        XLogger.shared.log("数据库里血氧的数据总条数：\(models?.count ?? 0)")
        let value = models?.first?.oxygen ?? 0
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[3] = v
        reloadMetricsCollection()
    }
    
    private func refreshDBOxygen() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DOxygenModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    
    @objc public func showDialogForInviteAPPReview() {
        if
            let navigationView = navigationController?.view{
            let noActionInfo = SCReviewView.ActionInfo(
                title: "NO",
                titleFont: UIFont.systemFont(ofSize: 18),
                image: UIImage(named: "amazon_image_sad_no"))
            let yesActionInfo = SCReviewView.ActionInfo(
                title: "YES",
                titleFont: UIFont.systemFont(ofSize: 18),
                image: UIImage(named: "amazon_image_smile_yes"))
            let viewInfo = SCReviewView.ViewInfo(
                image: UIImage(named: "amazon_image_heart") ?? UIImage(),
                imageSize: CGSize(width: 70, height: 60),
                imageTop: 19,
                title: " ",
                spaceBetweenImageAndTitle: 13,
                spaceBetweenArcBGAndTitle: 26,
                actionsInfo: [noActionInfo, yesActionInfo])
            let inviteReviewAPPDialog = SCReviewView(viewInfo: viewInfo).then {
                //将视图加到navigation上，达到全页面模态的效果，否则无法覆盖导航栏
                navigationView.addSubview($0)
                $0.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
            }
            currentDialog = inviteReviewAPPDialog
            inviteReviewAPPDialog.didClickedClosure = {
                [weak self] (index) in
                    guard let sself = self else { return }
                    inviteReviewAPPDialog.removeFromSuperview()
                    if index == 0 {
                        sself.notEnjoyApp()
                    } else {
                        sself.enjoyApp()
                    }
            }
        }
    }
    
    private func enjoyApp() {
        showAPPStoreReview()
    }
    
    private func showAPPStoreReview() {
        SKStoreReviewController.requestReview()
    }
    
    private func notEnjoyApp() {
        //显示help弹框
        
    }
    
    public func checkFGSStatus() {

        AliConnectMananger_C.shared.checkFgsState { isSuccess, data in
            JL_Tools.mainTask {
                [weak self] in
                self?.connectLp()
                if isSuccess {
                    NSLog("已有三元组数据")
                    //DFUITools.showText("已有三元组数据", on: self.view, delay: 1.0)
                }else {
                    NSLog("没有,错误日志 : \(String(describing: data["msg"]))")
                    //DFUITools.showText("三元组数据错误", on: self.view, delay: 1.0)
                }
            }
        }
    }
    
    public func connectLp() {
        
        //swift-Lp连接
        AliConnectMananger_C.shared.startConnectLpState { isSuccess, data in
            JL_Tools.mainTask {
                if isSuccess {
                    NSLog("LP连接成功")
                    //DFUITools.showText("LP连接成功", on: self.view, delay: 1.0)
                }else {
                    NSLog("LP连接失败,错误日志 : \(String(describing: data["msg"]))")
                    //DFUITools.showText("LP连接失败", on: self.view, delay: 1.0)
                }
            }
        }
    }
    
    var cameraViewController: CameraViewController?
    private var currentTime: TimeInterval = 0 // 当前时间戳
    
    private func takePhoto() {
        DispatchQueue.main.async {
            [weak self] in
            if UIApplication.shared.applicationState == .background {
                return
            }
            if self?.cameraViewController != nil {
                return
            }
            var croppingParameters: CroppingParameters {
                return CroppingParameters(isEnabled: false, allowResizing: false, allowMoving: false, minimumSize: CGSize(width: 60, height: 60))
            }
            self?.cameraViewController = CameraViewController(croppingParameters: croppingParameters, allowsLibraryAccess: true) { [weak self] image, asset in
                self?.dismiss(animated: true, completion: nil)
                self?.cameraViewController = nil
                XGZTCommand.remotePhoto(action: 0)
            }
            self?.cameraViewController?.modalPresentationStyle = .fullScreen
            UIApplication.shared.topMostViewController()?.present(self!.cameraViewController!, animated: true, completion: nil)
        }
    }
    
    private func closePhoto() {
        DispatchQueue.main.async {
            [weak self] in
            if UIApplication.shared.applicationState == .background {
                return
            }
            self?.cameraViewController?.dismiss(animated: true, completion: nil)
            self?.cameraViewController = nil
        }
    }
    
    private func startPhoto() {
        let current = Date().timeIntervalSince1970
        if currentTime > 0 {
            if abs(current - currentTime) < 4 {
                return
            }
        }
        currentTime = current
        DispatchQueue.main.async {
            [weak self] in
            if UIApplication.shared.applicationState == .background {
                return
            }
            if self?.cameraViewController == nil {
                return
            }
            self?.cameraViewController?.capturePhoto()
        }
    }
    
}


extension UIImage {
    class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                XLogger.shared.log("Unable to find the GIF file named \(name).gif")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            XLogger.shared.log("Unable to load the data for the GIF file \(name).gif")
            return nil
        }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            XLogger.shared.log("Unable to create image source for the GIF file \(name).gif")
            return nil
        }
        var images = [UIImage]()
        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                XLogger.shared.log("Unable to create image for frame \(i) of the GIF file \(name).gif")
                continue
            }
            let uiImage = UIImage(cgImage: cgImage)
            images.append(uiImage)
        }
        return UIImage.animatedImage(with: images, duration: 1.0)
    }
}

extension HealthViewController: BleNeedSendDataDelegate_C {
    func sendBleData(data: Data) {
        NSLog("--->ALi Send:")
        NSLog("%@",JL_Tools.dataChange(toString: data))


        let bigData = JL_BigData()
        bigData.mIndex = indexBigData
        bigData.mData  = data
        bigData.mType  = 1;

        mBigDataManager?.cmdInputBigData(bigData)
        indexBigData = indexBigData+1
    }
}


extension HealthViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? HealthCollectionViewCell)?.setHighlightedState(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? HealthCollectionViewCell)?.setHighlightedState(false)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let metricCell = cell as? HealthCollectionViewCell else {
            return
        }
        
        guard shouldAnimateMetricCellsOnNextDisplay, !animatedMetricIndexPaths.contains(indexPath) else {
            metricCell.alpha = 1
            metricCell.transform = .identity
            return
        }
        
        animatedMetricIndexPaths.insert(indexPath)
        metricCell.alpha = 0
        metricCell.transform = CGAffineTransform(translationX: 0, y: 22).scaledBy(x: 0.96, y: 0.96)
        
        UIView.animate(
            withDuration: 0.62,
            delay: min(Double(indexPath.item) * 0.07, 0.24),
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.18,
            options: [.allowUserInteraction, .curveEaseOut]
        ) {
            metricCell.alpha = 1
            metricCell.transform = .identity
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 处理cell点击事件
        let selectedView = collectionView.cellForItem(at: indexPath)
        if isXGZT {
            if xgztCount >= 4 {
                flag = 2 + indexPath.item
                presentHealthDetail(type: flag)
            } else {
                if indexPath.item == 0 {
                    if (XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) & 1 == 1 {
                        flag = 2
                        presentHealthDetail(type: flag)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                        flag = 3
                        presentHealthDetail(type: flag)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        flag = 4
                        presentHealthDetail(type: flag)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        flag = 5
                        presentHealthDetail(type: flag)
                    }
                } else if indexPath.item == 1 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                        flag = 3
                        presentHealthDetail(type: flag)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        flag = 4
                        presentHealthDetail(type: flag)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        flag = 5
                        presentHealthDetail(type: flag)
                    }
                } else if indexPath.item == 2 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        flag = 4
                        presentHealthDetail(type: flag)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        flag = 5
                        presentHealthDetail(type: flag)
                    }
                }
            }
        } else {
            flag = 2 + indexPath.item
            presentHealthDetail(type: flag)
        }
    }
}

extension HealthViewController: UICollectionViewDataSource {
    // UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentMetricCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! HealthCollectionViewCell
        if indexPath.item == 0 {
            if isXGZT {
                if (XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) & 1 == 1 {
                    configureMetricCell(cell, iconName: "health_heart", title: "health_heart_rate".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_heart"))
                } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                    configureMetricCell(cell, iconName: "health_sleep", title: "health_sleep".localized(), value: arrayValue[indexPath.item + 1], accentColor: metricAccentColor(for: "health_sleep"))
                } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                    configureMetricCell(cell, iconName: "health_bloodpressure", title: "health_blood_pressure".localized(), value: arrayValue[indexPath.item + 2], accentColor: metricAccentColor(for: "health_bloodpressure"))
                } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                    configureMetricCell(cell, iconName: "health_bloodoxygen", title: "health_blood_oxygen".localized(), value: arrayValue[indexPath.item + 3], accentColor: metricAccentColor(for: "health_bloodoxygen"))
                }
            } else {
                configureMetricCell(cell, iconName: "health_heart", title: "health_heart_rate".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_heart"))
            }
            
        } else if indexPath.item == 1 {
            if isXGZT {
                if xgztCount > 1 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                        configureMetricCell(cell, iconName: "health_sleep", title: "health_sleep".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_sleep"))
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        configureMetricCell(cell, iconName: "health_bloodpressure", title: "health_blood_pressure".localized(), value: arrayValue[indexPath.item + 1], accentColor: metricAccentColor(for: "health_bloodpressure"))
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        configureMetricCell(cell, iconName: "health_bloodoxygen", title: "health_blood_oxygen".localized(), value: arrayValue[indexPath.item + 2], accentColor: metricAccentColor(for: "health_bloodoxygen"))
                    }
                }
            } else {
                configureMetricCell(cell, iconName: "health_sleep", title: "health_sleep".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_sleep"))
            }
        } else if indexPath.item == 2 {
            if isXGZT {
                if xgztCount > 2 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        configureMetricCell(cell, iconName: "health_bloodpressure", title: "health_blood_pressure".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_bloodpressure"))
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        configureMetricCell(cell, iconName: "health_bloodoxygen", title: "health_blood_oxygen".localized(), value: arrayValue[indexPath.item + 1], accentColor: metricAccentColor(for: "health_bloodoxygen"))
                    }
                }
            } else {
                configureMetricCell(cell, iconName: "health_bloodpressure", title: "health_blood_pressure".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_bloodpressure"))
            }
            
        } else {
            configureMetricCell(cell, iconName: "health_bloodoxygen", title: "health_blood_oxygen".localized(), value: arrayValue[indexPath.item], accentColor: metricAccentColor(for: "health_bloodoxygen"))
        }
        return cell
    }
    
    // 如果需要多个分区，可以实现这个方法
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

extension HealthViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let insets = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
        let availableWidth = collectionView.bounds.width - insets.left - insets.right
        let itemCount = currentMetricCount()
        
        guard availableWidth > 0 else {
            return CGSize(width: 0, height: 0)
        }
        
        if itemCount <= 1 {
            return CGSize(width: availableWidth, height: 132)
        }
        
        if itemCount % 2 == 1 && indexPath.item == itemCount - 1 {
            return CGSize(width: availableWidth, height: 136)
        }
        
        let itemWidth = floor((availableWidth - 12) / 2)
        let itemHeight = max(132, min(148, itemWidth * 0.78))
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}

private final class EdgeInsetLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + contentInsets.left + contentInsets.right, height: size.height + contentInsets.top + contentInsets.bottom)
    }
}

private extension String {
    func localizedFallback(_ fallback: String) -> String {
        let value = self.localized()
        return value == self ? fallback : value
    }
}
