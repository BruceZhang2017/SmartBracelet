//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  HealthDetailViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK
import RealmSwift

class HealthDetailViewController: BaseViewController {
    let lineChartView: LineChartView = LineChartView()
    let barChartView: BarChartView = BarChartView()
    var ecgWaveforms: [Double] = []
    private var ecgTimer: Timer?
    private var ecgPhase: Double = 0.0
    private let ecgSampleRate: Double = 60.0
    private let ecgWaveformStretchFactor: Double = 2.0
    private var ecgHeartRateBPM: Int?
    private let ecgHeartRateLabel: UILabel = UILabel()
    private var isECGMeasuring: Bool = false
    private var ecgWorn: Bool = false
    private var ecgMeasureCountdown = 30
    // 脉搏波 PPG 实时平滑波形（算法对齐 mock_phone_app._get_ppg_point）
    private var ppgWaveforms: [Double] = []
    private var ppgTimer: Timer?
    private var ppgPhase: Double = 0.0
    private var isPPGMeasuring: Bool = false
    private var ppgWorn: Bool = false
    private var ppgHeartRateBPM: Int?
    private var ppgBaseline: Double = 1000.0
    private let ppgSampleRate: Double = 60.0
    private let ppgWindowSeconds: Double = 10.0
    private let ppgHeartRateLabel: UILabel = UILabel()
    private var ppgWornLabel: UILabel?
    private var ppgMeasureCountdown = 30
    private var disclaimerLabel: UILabel?
    // Android 对齐：ECG 实时测量点采集与持久化、2s 无上报自动结束
    private var ecgPoints: [EcgPoint] = []
    private var ecgRecordId: String = ""
    private var ecgStartUptime: TimeInterval = 0
    private var ecgSaveErrorShown = false
    private var ecgStaleTimer: Timer?
    let dateLabel: UILabel = UILabel() // 日期
    let prevDayButton: UIButton = UIButton(type: .custom) // 前一个
    let nextDayButton: UIButton = UIButton(type: .custom) // 后一个
    let valueView = HealthValueView()
    let fanView = FanView() // 步数和睡眠view
    let roundView = RoundView() // 血压和睡眠view
    let testView = TestView()
    public var colors: [UIColor]!
    var commonCalendarView: CommonCalendarView?
    var type = 0 // 0 步数 1 热量 2 心率 3 睡眠
    var mDate: Date = Date()
    var totalValue = 0 // 总步数
    var totalKM = 0 // 总公里
    var measureAsync: Async?
    var mTimer: Timer?
    var alpha: CGFloat = 0.3
    var maxValue = 0

    private func makeRoundValue(_ value: String, unit: String, valueFont: CGFloat = 40, unitFont: CGFloat = 14) -> NSMutableAttributedString {
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: value, attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: valueFont, weight: .black)]))
        text.append(NSAttributedString(string: unit, attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: unitFont, weight: .medium)]))
        return text
    }

    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()
        dateLabel.textColor = UIColor.white
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(chooseDate))
        dateLabel.isUserInteractionEnabled = true
        tap.numberOfTapsRequired = 1
        dateLabel.addGestureRecognizer(tap)
        
        prevDayButton.setImage(UIImage(named: "health_pre_date"), for: .normal)
        prevDayButton.addTarget(self, action: #selector(prevDayTapped), for: .touchUpInside)
        view.addSubview(prevDayButton)
        prevDayButton.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalTo(dateLabel.snp.centerY)
            make.trailing.equalTo(dateLabel.snp.leading).offset(-2)
        }
        
        nextDayButton.setImage(UIImage(named: "health_next_date"), for: .normal)
        nextDayButton.addTarget(self, action: #selector(nextDayTapped), for: .touchUpInside)
        view.addSubview(nextDayButton)
        nextDayButton.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalTo(dateLabel.snp.centerY)
            make.leading.equalTo(dateLabel.snp.trailing).offset(2)
        }
        
        view.addSubview(valueView)
        valueView.backgroundColor = UIColor.white
        let h = screenWidth <= 375 ? 320.0 : 388.0
        valueView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(valueView.snp.width).multipliedBy(h/375.0)
        }
        
        view.addSubview(roundView)
        roundView.backgroundColor = UIColor.clear
        roundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom)
            make.bottom.equalTo(valueView.snp.top)
        }
        
        view.addSubview(fanView)
        fanView.backgroundColor = UIColor.clear
        fanView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom)
            make.bottom.equalTo(valueView.snp.top)
        }
        
        view.addSubview(testView)
        testView.backgroundColor = UIColor.clear
        testView.delegate = self 
        testView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom)
            make.bottom.equalTo(valueView.snp.top)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("healthDetail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleECGHeartRate(_:)), name: Notification.Name("ecg_heart_rate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleECGSamples(_:)), name: Notification.Name("ecg_samples"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleECGMeasureFailed(_:)), name: Notification.Name("ecg_measure_failed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleECGWornStatus(_:)), name: Notification.Name("ecg_worn_status"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePPGHeartRate(_:)), name: Notification.Name("ppg_heart_rate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePPGWornStatus(_:)), name: Notification.Name("ppg_worn_status"), object: nil)
        
        if type == 0 {
            title = "health_step".localized()
            fanView.isHidden = false
            roundView.isHidden = true
            testView.isHidden = true
            let m = NSMutableAttributedString()
            m.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            m.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let c = NSMutableAttributedString()
            c.append(NSAttributedString(string: "-- ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            c.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            fanView.setupView(titles: ["health_distance".localized(), "consumption".localized()], values: [m, c], title: "today_step".localized(), value: b)
        }
        if type == 2 {
            title = "health_heart_rate".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            roundView.setupView(value: b)
            valueView.refreshLabel(text: "heart_desc".localized())
            addTest()
        }
        if type == 3 {
            title = "health_sleep".localized()
            fanView.isHidden = false
            roundView.isHidden = true
            testView.isHidden = true
            let qing = NSMutableAttributedString()
            qing.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            qing.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let qian = NSMutableAttributedString()
            qian.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            qian.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let shen = NSMutableAttributedString()
            shen.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            shen.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
            b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
            fanView.setupView(titles: ["health_detail_sleep_awake".localized(), "health_detail_sleep_light".localized(), "health_detail_sleep_deep".localized()], values: [qing, qian, shen], title: "today_sleep".localized(), value: b)
            valueView.refreshLabel(text: "health_conclusion_sleep_reference".localized(), color: HealthDetailViewController.cGray)
        }
        if type == 4 {
            title = "health_blood_pressure".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
            setupDisclaimer()
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
            roundView.setupView(value: b)
            addTest()
        }
        if type == 5 {
            title = "health_blood_oxygen".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            roundView.setupView(value: b)
            addTest()
            
        }
        if type == 7 {
            title = "health_blood_glucose".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            roundView.setupView(value: makeRoundValue("--", unit: " mmol/L", valueFont: 34, unitFont: 12))
            valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
            setupDisclaimer()
            addTest()
        }
        if type == 8 {
            title = "health_uric_acid".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            roundView.setupView(value: makeRoundValue("--", unit: " umol/L", valueFont: 34, unitFont: 12))
            valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
            setupDisclaimer()
            addTest()
        }
        if type == 9 {
            title = "health_blood_lipid".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            roundView.setupView(value: makeRoundValue("--", unit: " mmol/L", valueFont: 32, unitFont: 12))
            valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
            setupDisclaimer()
            addTest()
        }
        if type == 10 {
            title = "health_ppg".localized()
            fanView.isHidden = true
            roundView.isHidden = true
            testView.isHidden = true
            testView.setupView()

            // 脉搏波实时平滑波形视图（对齐 mock_phone_app 的 _get_ppg_point 形态）
            ppgHeartRateLabel.textAlignment = .center
            ppgHeartRateLabel.numberOfLines = 1
            ppgHeartRateLabel.alpha = 1.0
            updatePPGPulseDisplay(nil)
            view.addSubview(ppgHeartRateLabel)
            ppgHeartRateLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(12)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }

            valueView.layoutIfNeeded()
            let worn = UILabel()
            worn.text = "ppg_worn_off".localized()
            worn.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            worn.textColor = UIColor(red: 0.90, green: 0.24, blue: 0.28, alpha: 1.0)
            worn.textAlignment = .center
            worn.numberOfLines = 0
            worn.isHidden = true
            view.addSubview(worn)
            worn.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(valueView.snp.top).offset(-14)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }
            ppgWornLabel = worn

            valueView.refreshLabel(text: "health_ppg_desc".localized())
            addTest()
            startPPGRealtimeRendering()
        }
        if type == 11 {
            title = "health_hrv".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            roundView.setupView(value: makeRoundValue("--", unit: " ms", valueFont: 34, unitFont: 12))
            valueView.refreshLabel(text: "health_hrv_desc".localized())
            addTest()
        }
        if type == 12 {
            title = "health_stress".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            roundView.setupView(value: makeRoundValue("--", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
            valueView.refreshLabel(text: "health_stress_desc".localized())
            addTest()
        }
        if type == 13 {
            title = "health_fatigue".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            roundView.setupView(value: makeRoundValue("--", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
            valueView.refreshLabel(text: "health_fatigue_desc".localized())
            addTest()
        }
        if type == 6 {
            title = "health_ecg".localized()
            fanView.isHidden = true
            roundView.isHidden = true
            testView.isHidden = true
            testView.setupView()

            // Android 对齐：ECG 详情页右上角提供历史记录入口
            let historyButton = UIButton(type: .custom)
            historyButton.setImage(UIImage(named: "ecg_history_icon") ?? UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
            historyButton.tintColor = UIColor.white
            historyButton.addTarget(self, action: #selector(ecgHistoryTapped), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: historyButton)

            ecgHeartRateLabel.textAlignment = .center
            ecgHeartRateLabel.numberOfLines = 1
            ecgHeartRateLabel.alpha = 1.0
            updateECGHeartRateDisplay(nil)
            view.addSubview(ecgHeartRateLabel)
            ecgHeartRateLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(44)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }

            valueView.refreshLabel(text: "ecg_desc".localized())
            addTest()
        }
        
        if type == 3 {
            setBarChartView()
            setBarData()
        } else {
            setupChart()
            if type == 6 {
                setECGChartViewData()
            } else if type == 10 {
                setPPGChartViewData()
            } else {
                setChartViewData()
            }
        }
        dateLabel.text = mDate.stringFromYmd()
        if type == 6 || type == 10 {
            dateLabel.isHidden = true
            prevDayButton.isHidden = true
            nextDayButton.isHidden = true
            roundView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(valueView.snp.top)
            }
            fanView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(valueView.snp.top)
            }
            testView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(valueView.snp.top)
            }
            ecgHeartRateLabel.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }
        }
        if type == 10 {
            ppgHeartRateLabel.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }
        }
        
        // 创建一个自定义的返回按钮
        let backButton = UIBarButtonItem(image: UIImage(named: "health_back_white"), style: .plain, target: self, action: #selector(backButtonTapped))
        
        // 将自定义的返回按钮设置为左侧按钮
        self.navigationItem.leftBarButtonItem = backButton
        
        // 如果你不希望保留原有的返回按钮文本，可以将其设置为空字符串
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func getBitValue(of number: Int, at position: Int) -> Int {
        // 使用位运算获取指定位置的位值
        let bitValue = (number >> position) & 1
        return bitValue
    }
    
    private func setupDisclaimer() {
        guard disclaimerLabel == nil else { return }
        let label = UILabel()
        label.text = "health_disclaimer".localized()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor(hex: 0x718096)
        label.textAlignment = .center
        label.numberOfLines = 0
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(valueView.snp.top).offset(-6)
        }
        disclaimerLabel = label
    }

    private static let cGreen = UIColor(hex: 0x16A34A)
    private static let cOrange = UIColor(hex: 0xED8936)
    private static let cRed = UIColor(hex: 0xE53E3E)
    private static let cGray = UIColor(hex: 0x718096)

    private func applyHealthConclusion(type: Int, doubleValue: Double?) {
        switch type {
        case 2:
            guard let v = doubleValue, v > 0 else { return }
            if v >= 60 && v <= 100 {
                valueView.refreshLabel(text: "health_conclusion_normal".localized(), color: HealthDetailViewController.cGreen)
            } else if v < 60 {
                valueView.refreshLabel(text: "health_conclusion_bradycardia".localized(), color: HealthDetailViewController.cRed)
            } else {
                valueView.refreshLabel(text: "health_conclusion_tachycardia".localized(), color: HealthDetailViewController.cRed)
            }
        case 5:
            guard let v = doubleValue, v > 0 else { return }
            if v >= 96 {
                valueView.refreshLabel(text: "health_conclusion_normal".localized(), color: HealthDetailViewController.cGreen)
            } else if v >= 90 {
                valueView.refreshLabel(text: "health_conclusion_low".localized(), color: HealthDetailViewController.cOrange)
            } else {
                valueView.refreshLabel(text: "health_conclusion_too_low".localized(), color: HealthDetailViewController.cRed)
            }
        case 12:
            guard let v = doubleValue else { return }
            if v < 20 {
                valueView.refreshLabel(text: "health_conclusion_relaxed".localized(), color: HealthDetailViewController.cGreen)
            } else if v <= 40 {
                valueView.refreshLabel(text: "health_conclusion_moderate_stress".localized(), color: HealthDetailViewController.cOrange)
            } else {
                valueView.refreshLabel(text: "health_conclusion_high_stress".localized(), color: HealthDetailViewController.cRed)
            }
        case 13:
            guard let v = doubleValue else { return }
            if v <= 21 {
                valueView.refreshLabel(text: "health_conclusion_no_fatigue".localized(), color: HealthDetailViewController.cGreen)
            } else if v <= 34 {
                valueView.refreshLabel(text: "health_conclusion_moderate_fatigue".localized(), color: HealthDetailViewController.cOrange)
            } else {
                valueView.refreshLabel(text: "health_conclusion_severe_fatigue".localized(), color: HealthDetailViewController.cRed)
            }
        case 11:
            valueView.refreshLabel(text: "health_conclusion_hrv_reference".localized(), color: HealthDetailViewController.cGray)
        default:
            break
        }
    }

    private func addTest() {
        let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
        if bk {
            return
        }
        
        if bleSelf.isConnected == false && XGZTBlueToothManager.shared.device == nil {
            return
        }
        
        if isXGZT && ![2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].contains(type) {
            return
        }
        
        // 与 Android 对齐：带屏设备的测量由设备端发起，只有无屏设备需要在详情页显示“开始测试”按钮（ECG 除外，ECG 始终由 App 触发）
        if isXGZT && type != 6 && !(XGZTBlueToothManager.shared.device?.isNoScreenDevice ?? false) {
            return
        }
        
//        if (type == 2 && isXGZT) && (XGZTBlueToothManager.shared.device?.brandID ?? 0) == 0 {
//            return
//        }
//        
//        if (type == 5 && isXGZT) && (XGZTBlueToothManager.shared.device?.brandID ?? 0) == 0  {
//            return
//        }

        let title = "health_start_test".localized()

        if screenHeight <= 667 {
            let rightButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.rightBarButtonAction))
            rightButton.tintColor = UIColor.white
            self.navigationItem.rightBarButtonItem = rightButton
        } else {
            let testButton: UIButton
            if let existed = view.viewWithTag(8888) as? UIButton {
                testButton = existed
            } else {
                testButton = UIButton(type: .custom)
                testButton.tag = 8888
                testButton.setTitleColor(UIColor.brand, for: .normal)
                testButton.layer.borderColor = UIColor.brand.cgColor
                testButton.layer.borderWidth = 1.0
                testButton.backgroundColor = .white
                testButton.layer.cornerRadius = 22
                testButton.addTarget(self, action: #selector(rightBarButtonAction), for: .touchUpInside)
                view.addSubview(testButton)
                testButton.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.width.equalTo(type == 6 ? 180 : 150)
                    make.height.equalTo(44)
                    make.bottom.equalTo(valueView.snp.top).offset(-10)
                }
            }
            testButton.isHidden = false
            testButton.setTitle(title, for: .normal)
        }
    }
    
    // UIBarButtonItem的点击事件处理器
    @objc func rightBarButtonAction() {
        if type == 6 {
            if screenHeight <= 667 {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                if let btn = view.viewWithTag(8888) as? UIButton {
                    btn.isHidden = true
                }
            }
            roundView.isHidden = true
            fanView.isHidden = true
            testView.isHidden = false
            testView.testing()
            valueView.refreshView(isHideNull: true)
            valueView.refreshLabel(text: "ecg_desc".localized())
            lineChartView.isHidden = false
            setECGChartViewData()
            handleStartTest()
            return
        }
        if type == 10 {
            if screenHeight <= 667 {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                if let btn = view.viewWithTag(8888) as? UIButton {
                    btn.isHidden = true
                }
            }
            roundView.isHidden = true
            fanView.isHidden = true
            testView.isHidden = false
            testView.testing()
            valueView.refreshView(isHideNull: true)
            valueView.refreshLabel(text: "health_ppg_desc".localized())
            lineChartView.isHidden = false
            setPPGChartViewData()
            handleStartTest()
            return
        }
        if screenHeight <= 667 {
            // 隐藏按钮
            self.navigationItem.rightBarButtonItem = nil
            // 或者，如果你想保持按钮但仅仅是禁用它，可以这样做：
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            if let btn = view.viewWithTag(8888) as? UIButton {
                btn.isHidden = true
            }
        }
        
        roundView.isHidden = true
        fanView.isHidden = true
        testView.isHidden = false
        handleStartTest() // 启动测试
        
    }
    
    @objc func backButtonTapped() {
        // 在这里处理返回按钮的点击事件
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if type == 6, isECGMeasuring {
            // Android 对齐：onStop/销毁时结束并保存测量
            finishECGMeasurement(showComplete: false)
        }
        if type == 10, isPPGMeasuring {
            finishPPGMeasurement(showComplete: false)
        }
        UINavigationBar.appearance().tintColor = UIColor.text_primary
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
        mTimer?.invalidate()
        mTimer = nil
        ecgTimer?.invalidate()
        ecgTimer = nil
        ecgStaleTimer?.invalidate()
        ecgStaleTimer = nil
        ppgTimer?.invalidate()
        ppgTimer = nil
    }
    
    // 前一天按钮点击事件
    @objc func prevDayTapped() {
        mDate = Calendar.current.date(byAdding: .day, value: -1, to: mDate)!
        dateLabel.text = mDate.stringFromYmd()
        if type == 3 {
            setBarData()
        } else if type == 6 {
            setECGChartViewData()
        } else {
            setChartViewData() // 刷新数据
        }
    }

    // 后一天按钮点击事件
    @objc func nextDayTapped() {
        mDate = Calendar.current.date(byAdding: .day, value: 1, to: mDate)!
        dateLabel.text = mDate.stringFromYmd()
        if type == 3 {
            setBarData()
        } else if type == 6 {
            setECGChartViewData()
        } else {
            setChartViewData() // 刷新数据
        }
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        // BLE 回调在后台线程同步 post healthDetail，UI 操作必须切回主线程
        if Thread.isMainThread {
            handleNotificationOnMain()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleNotificationOnMain()
            }
        }
    }

    private func handleNotificationOnMain() {
        if type == 6 {
            // 测量过程中设备会持续上报心率帧并触发 healthDetail，忽略这些帧，避免打断实时渲染
            guard !isECGMeasuring else { return }
            stopECGRealtimeRendering()
            stopECGCountdown()
            fanView.isHidden = true
            roundView.isHidden = true
            testView.isHidden = true
            if screenHeight <= 667 {
                addTest()
            } else {
                if let btn = view.viewWithTag(8888) as? UIButton {
                    btn.isHidden = false
                }
            }
            valueView.refreshLabel(text: "health_ecg_measure_complete".localized())
            updateECGWornConclusion()
            setECGChartViewData()
            return
        }
        if type == 10 {
            // 实时波长页面：保持波形渲染，仅结束倒计时（healthDetail 帧不打断平滑波形）
            stopPPGCountdown()
            testView.isHidden = true
            valueView.refreshLabel(text: "ppg_measure_complete".localized())
            updatePPGWornConclusion()
            return
        }
        if testView.isHidden == false {
            testView.stop()
            if type == 6 {
                stopECGRealtimeRendering()
            }
            if type == 0 {
                fanView.isHidden = false
                roundView.isHidden = true
                testView.isHidden = true
            }
            if type == 2 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
            }
            if type == 3 {
                fanView.isHidden = false
                roundView.isHidden = true
                testView.isHidden = true
            }
            if type == 4 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
            }
            if type == 5 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
                
            }
            if type == 7 || type == 8 || type == 9 || type == 10 || type == 11 || type == 12 || type == 13 {
                fanView.isHidden = true
                roundView.isHidden = false
                testView.isHidden = true
            }
            if type == 6 {
                fanView.isHidden = true
                roundView.isHidden = true
                testView.isHidden = true
            }
            if type == 2 || type == 4 || type == 5 || type == 6 || type == 7 || type == 8 || type == 9 || type == 10 || type == 11 || type == 12 || type == 13 {
                if screenHeight <= 667 {
                    addTest()
                } else {
                    if let btn = view.viewWithTag(8888) as? UIButton {
                        btn.isHidden = false
                    }
                }
            }
        }
        if type == 3 {
            setBarData()
        } else if type == 6 {
            setECGChartViewData()
        } else {
            setChartViewData() // 刷新数据
        }
    }

    @objc private func handleECGHeartRate(_ notification: Notification) {
        guard type == 6 else { return }
        // BLE 回调在后台线程同步 post，UI 更新必须切回主线程
        if Thread.isMainThread {
            handleECGHeartRateOnMain(notification)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleECGHeartRateOnMain(notification)
            }
        }
    }

    private func handleECGHeartRateOnMain(_ notification: Notification) {
        let bpm = notification.userInfo?["bpm"] as? Int
        ecgHeartRateBPM = bpm
        ecgWorn = (bpm != nil && bpm! > 0)
        updateECGHeartRateDisplay(bpm)
        guard isECGMeasuring else { return }
        // Android 对齐：采集 (elapsedMillis, heartRate) 采样点，并在每次有效上报后重置 2s 无上报检测
        if let bpm = bpm {
            let offsetMillis = Int64((ProcessInfo.processInfo.systemUptime - ecgStartUptime) * 1000)
            ecgPoints.append(EcgPoint(offsetMillis: offsetMillis, heartRate: bpm))
        }
        resetECGStaleTimer()
    }

    @objc private func handleECGWornStatus(_ notification: Notification) {
        guard type == 6 else { return }
        // BLE 回调在后台线程同步 post，UI 更新必须切回主线程
        if Thread.isMainThread {
            handleECGWornStatusOnMain(notification)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleECGWornStatusOnMain(notification)
            }
        }
    }

    private func handleECGWornStatusOnMain(_ notification: Notification) {
        let worn = (notification.userInfo?["worn"] as? Bool) ?? false
        ecgWorn = worn
        if !worn {
            ecgHeartRateBPM = nil
        }
        updateECGHeartRateDisplay(ecgHeartRateBPM)
        if !isECGMeasuring {
            updateECGWornConclusion()
        }
    }

    @objc private func handlePPGHeartRate(_ notification: Notification) {
        guard type == 10 else { return }
        if Thread.isMainThread {
            handlePPGHeartRateOnMain(notification)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePPGHeartRateOnMain(notification)
            }
        }
    }

    private func handlePPGHeartRateOnMain(_ notification: Notification) {
        let bpm = notification.userInfo?["bpm"] as? Int
        ppgHeartRateBPM = bpm
        ppgWorn = (bpm != nil && bpm! > 0)
        updatePPGPulseDisplay(bpm)
        ppgWornLabel?.isHidden = ppgWorn
    }

    @objc private func handlePPGWornStatus(_ notification: Notification) {
        guard type == 10 else { return }
        if Thread.isMainThread {
            handlePPGWornStatusOnMain(notification)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePPGWornStatusOnMain(notification)
            }
        }
    }

    private func handlePPGWornStatusOnMain(_ notification: Notification) {
        let worn = (notification.userInfo?["worn"] as? Bool) ?? false
        ppgWorn = worn
        if !worn {
            ppgHeartRateBPM = nil
        }
        updatePPGPulseDisplay(ppgHeartRateBPM)
        ppgWornLabel?.isHidden = worn
        if !isPPGMeasuring {
            updatePPGWornConclusion()
        }
    }

    private func updateECGWornConclusion() {
        if ecgWorn {
            valueView.refreshLabel(text: "health_conclusion_signal_good".localized(), color: HealthDetailViewController.cGreen)
        } else {
            valueView.refreshLabel(text: "health_conclusion_not_worn".localized(), color: HealthDetailViewController.cRed)
        }
    }

    private func updatePPGWornConclusion() {
        if ppgWorn {
            valueView.refreshLabel(text: "health_conclusion_signal_good".localized(), color: HealthDetailViewController.cGreen)
        } else {
            valueView.refreshLabel(text: "health_conclusion_not_worn".localized(), color: HealthDetailViewController.cRed)
        }
    }

    private func updatePPGPulseDisplay(_ bpm: Int?) {
        let text = NSMutableAttributedString()
        let baseFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        let valueFont = UIFont.systemFont(ofSize: 26, weight: .black)
        let baseColor = UIColor.white
        text.append(NSAttributedString(string: "ppg_real_time_pulse".localized(), attributes: [.foregroundColor: baseColor, .font: baseFont]))
        if let b = bpm, b > 0 {
            text.append(NSAttributedString(string: "\(b)", attributes: [.foregroundColor: baseColor, .font: valueFont]))
            text.append(NSAttributedString(string: " bpm", attributes: [.foregroundColor: baseColor.withAlphaComponent(0.85), .font: baseFont]))
        } else {
            text.append(NSAttributedString(string: "--", attributes: [.foregroundColor: baseColor, .font: valueFont]))
            text.append(NSAttributedString(string: " bpm", attributes: [.foregroundColor: baseColor.withAlphaComponent(0.85), .font: baseFont]))
        }
        ppgHeartRateLabel.attributedText = text
    }

    @objc private func handleECGSamples(_ notification: Notification) {
        guard type == 6 else { return }
        guard let samples = notification.userInfo?["samples"] as? [Double], !samples.isEmpty else { return }
        // BLE 回调在后台线程同步 post，UI 更新必须切回主线程
        if Thread.isMainThread {
            handleECGSamplesOnMain(samples)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleECGSamplesOnMain(samples)
            }
        }
    }

    private func handleECGSamplesOnMain(_ samples: [Double]) {
        for v in samples {
            appendECGSample(v)
        }
    }

    @objc private func handleECGMeasureFailed(_ notification: Notification) {
        guard type == 6 else { return }
        measureAsync?.cancel()
        isECGMeasuring = false
        stopECGCountdown()
        let reason = (notification.userInfo?["reason"] as? String) ?? "ecg_measure_fail_reason".localized()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopECGRealtimeRendering()
            self.ecgHeartRateBPM = nil
            self.updateECGHeartRateDisplay(nil)
            self.fanView.isHidden = true
            self.roundView.isHidden = true
            self.testView.isHidden = true
            if screenHeight <= 667 {
                self.addTest()
            } else {
                if let btn = self.view.viewWithTag(8888) as? UIButton {
                    btn.isHidden = false
                }
            }
            self.valueView.refreshLabel(text: reason)
            self.setECGChartViewData()
        }
    }

    private func updateECGHeartRateDisplay(_ bpm: Int?) {
        let text = NSMutableAttributedString()
        let baseFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        let valueFont = UIFont.systemFont(ofSize: 26, weight: .black)
        let baseColor = UIColor.white
        if let b = bpm, b > 0 {
            text.append(NSAttributedString(string: "实时心率: ", attributes: [.foregroundColor: baseColor, .font: baseFont]))
            text.append(NSAttributedString(string: "\(b)", attributes: [.foregroundColor: baseColor, .font: valueFont]))
            text.append(NSAttributedString(string: " bpm", attributes: [.foregroundColor: baseColor.withAlphaComponent(0.85), .font: baseFont]))
        } else {
            text.append(NSAttributedString(string: "实时心率: ", attributes: [.foregroundColor: baseColor, .font: baseFont]))
            text.append(NSAttributedString(string: "--", attributes: [.foregroundColor: baseColor, .font: valueFont]))
            text.append(NSAttributedString(string: " bpm", attributes: [.foregroundColor: baseColor.withAlphaComponent(0.85), .font: baseFont]))
        }
        ecgHeartRateLabel.attributedText = text
    }
    
    /// 设置图表
    private func setupChart() {
        if type == 0 && bleSelf.bleModel.isBond == false {
            valueView.isHidden = true
        }
        valueView.addSubview(lineChartView)
        lineChartView.snp.makeConstraints { make in
            make.leading.equalTo(15)
            make.trailing.equalTo(-15)
            make.top.equalTo(50)
            make.bottom.equalTo(-10)
        }
        
        lineChartView.delegate = self
        
        lineChartView.chartDescription?.enabled = false
        lineChartView.dragEnabled = false
        lineChartView.setScaleEnabled(false)
        lineChartView.pinchZoomEnabled = false
        
        lineChartView.xAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.gridColor = UIColor.clear
        lineChartView.xAxis.drawGridLinesEnabled = true
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
        
        lineChartView.leftAxis.labelTextColor = UIColor.clear
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.leftAxis.setLabelCount(6, force: true)
        lineChartView.leftAxis.gridColor = UIColor.clear
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        
        lineChartView.rightAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.rightAxis.axisMinimum = 0
        
        if type == 6 || type == 10 {
            lineChartView.xAxis.axisMinimum = Double(0)
            lineChartView.xAxis.axisMaximum = type == 6 ? Double(ecgSampleRate == 0 ? 10 : 10) : ppgWindowSeconds
            lineChartView.xAxis.setLabelCount(5, force: false)
            lineChartView.xAxis.granularity = 1.0
            lineChartView.xAxis.granularityEnabled = true
            lineChartView.xAxis.valueFormatter = DefaultAxisValueFormatter { value, _ in
                String(format: "%.0f", value)
            }
            if type == 6 {
                lineChartView.rightAxis.axisMaximum = 2000
            } else {
                lineChartView.rightAxis.axisMinimum = ppgBaseline - 120
                lineChartView.rightAxis.axisMaximum = ppgBaseline + 120
            }
            lineChartView.rightAxis.setLabelCount(5, force: true)
            lineChartView.rightAxis.labelTextColor = UIColor.clear
        } else {
            lineChartView.xAxis.axisMinimum = Double(0)
            lineChartView.xAxis.axisMaximum = Double(23)
            lineChartView.xAxis.setLabelCount(24, force: true)
            if type == 0 {
                lineChartView.rightAxis.axisMaximum = 5000
            } else if type == 2 {
                lineChartView.rightAxis.axisMaximum = 200
            } else if type == 4 {
                lineChartView.rightAxis.axisMaximum = 200
            } else if type == 5 {
                lineChartView.rightAxis.axisMaximum = 100
            } else if type == 7 {
                lineChartView.rightAxis.axisMaximum = 30
            } else if type == 8 {
                lineChartView.rightAxis.axisMaximum = 1000
            } else if type == 9 {
                lineChartView.rightAxis.axisMaximum = 15
            } else if type == 11 {
                lineChartView.rightAxis.axisMaximum = 200
            } else if type == 12 {
                lineChartView.rightAxis.axisMaximum = 100
            } else if type == 13 {
                lineChartView.rightAxis.axisMaximum = 100
            }
            lineChartView.rightAxis.setLabelCount(6, force: true)
        }
        
        lineChartView.rightAxis.gridColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.rightAxis.drawGridLinesEnabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.legend.form = .none
    }
    
    func setChartViewData() {
        var values: [ChartDataEntry] = []
        initializeData { [weak self] v in
            values += v
            let set1 = LineChartDataSet(entries: values, label: "")
            set1.drawIconsEnabled = false
            if let self = self, [2, 4, 5, 7, 8, 9, 10, 11, 12, 13].contains(self.type) {
                set1.axisDependency = .right
            }
            
            set1.setColor(UIColor.brand)
            set1.lineWidth = 1
            set1.valueFont = .systemFont(ofSize: 9)
            set1.formLineWidth = 0.5
            set1.mode = .horizontalBezier
            set1.drawValuesEnabled = false
            set1.drawCirclesEnabled = false
            set1.circleHoleRadius = 2
            set1.circleRadius = 4
            
            let gradientColors = [ChartColorTemplates.colorFromString("#1A80FCFF").cgColor,
                                  ChartColorTemplates.colorFromString("#1A80FC11").cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!

            set1.fillAlpha = 1
            set1.fill = Fill(linearGradient: gradient, angle: 90)
            set1.drawFilledEnabled = true
            
            let data = LineChartData(dataSet: set1)

            self?.lineChartView.data = data
            
            self?.valueView.refreshView(isHideNull: values.count != 0)
            self?.lineChartView.isHidden = values.count == 0
        }
        
    }
    
    func setECGChartViewData() {
        let count = ecgWaveforms.count
        var values: [ChartDataEntry] = []
        if count > 0 {
            for i in 0..<count {
                let t = Double(i) / ecgSampleRate
                values.append(ChartDataEntry(x: t, y: ecgWaveforms[i]))
            }
        } else {
            let totalSamples = Int(30.0 * ecgSampleRate)
            for i in 0..<totalSamples {
                values.append(ChartDataEntry(x: Double(i) / ecgSampleRate, y: 1000))
            }
        }
        let set1 = LineChartDataSet(entries: values, label: "")
        set1.drawIconsEnabled = false
        set1.setColor(UIColor(red: 0.95, green: 0.35, blue: 0.48, alpha: 1.0))
        set1.lineWidth = 1.2
        set1.valueFont = .systemFont(ofSize: 9)
        set1.formLineWidth = 0.5
        set1.mode = .linear
        set1.drawValuesEnabled = false
        set1.drawCirclesEnabled = false
        set1.drawFilledEnabled = false

        let data = LineChartData(dataSet: set1)
        lineChartView.data = data
        let duration = Double(max(count, Int(30.0 * ecgSampleRate))) / ecgSampleRate
        let fullWindow: Double = 30.0
        lineChartView.xAxis.axisMinimum = 0.0
        lineChartView.xAxis.axisMaximum = max(fullWindow, duration)
        lineChartView.moveViewToX(max(0, duration - fullWindow))
        valueView.refreshView(isHideNull: true)
        lineChartView.isHidden = false
    }
    
    func setPPGChartViewData() {
        let count = ppgWaveforms.count
        var values: [ChartDataEntry] = []
        if count > 0 {
            for i in 0..<count {
                let t = Double(i) / ppgSampleRate
                values.append(ChartDataEntry(x: t, y: ppgWaveforms[i]))
            }
        } else {
            let totalSamples = Int(ppgWindowSeconds * ppgSampleRate)
            for i in 0..<totalSamples {
                values.append(ChartDataEntry(x: Double(i) / ppgSampleRate, y: ppgBaseline))
            }
        }
        let set1 = LineChartDataSet(entries: values, label: "")
        set1.drawIconsEnabled = false
        set1.setColor(UIColor(red: 0.20, green: 0.50, blue: 0.99, alpha: 1.0))
        set1.lineWidth = 1.6
        set1.mode = .cubicBezier
        set1.valueFont = .systemFont(ofSize: 9)
        set1.formLineWidth = 0.5
        set1.drawValuesEnabled = false
        set1.drawCirclesEnabled = false
        set1.drawFilledEnabled = false

        let data = LineChartData(dataSet: set1)
        lineChartView.data = data
        let duration = Double(max(count, Int(ppgWindowSeconds * ppgSampleRate))) / ppgSampleRate
        lineChartView.xAxis.axisMinimum = 0.0
        lineChartView.xAxis.axisMaximum = ppgWindowSeconds
        lineChartView.rightAxis.axisMinimum = ppgBaseline - 120
        lineChartView.rightAxis.axisMaximum = ppgBaseline + 120
        lineChartView.rightAxis.labelTextColor = UIColor.clear
        lineChartView.moveViewToX(max(0, duration - ppgWindowSeconds))
        valueView.refreshView(isHideNull: true)
        lineChartView.isHidden = false
    }
    
    func setBarChartView() {
        valueView.addSubview(barChartView)
        barChartView.snp.makeConstraints { make in
            make.leading.equalTo(15)
            make.trailing.equalTo(-15)
            make.top.equalTo(50)
            make.bottom.equalTo(-10)
        }
        barChartView.delegate = self
        
        barChartView.chartDescription?.enabled = false
        barChartView.dragEnabled = false
        barChartView.setScaleEnabled(false)
        barChartView.pinchZoomEnabled = false
        
        barChartView.xAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        barChartView.xAxis.avoidFirstLastClippingEnabled = true
        barChartView.xAxis.axisMinimum = Double(0)
        barChartView.xAxis.axisMaximum = Double(4)
        barChartView.xAxis.setLabelCount(5, force: true)
        barChartView.xAxis.gridColor = UIColor.clear
        barChartView.xAxis.drawGridLinesEnabled = true
        barChartView.xAxis.drawAxisLineEnabled = false
        barChartView.xAxis.labelPosition = .bottom
        let xAxisFormatter = CustomXAxisFormatter()
        xAxisFormatter.labels = [" ", "health_detail_sleep_awake".localized(), "health_detail_sleep_light".localized(), "health_detail_sleep_deep".localized(), " "]
        barChartView.xAxis.valueFormatter = xAxisFormatter
        barChartView.xAxis.granularity = 1 // 设置粒度以避免重复值
        
        barChartView.leftAxis.labelTextColor = UIColor.clear
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.axisMaximum = 5
        barChartView.leftAxis.setLabelCount(6, force: true)
        barChartView.leftAxis.gridColor = UIColor.clear
        barChartView.leftAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.drawAxisLineEnabled = false
        
        barChartView.rightAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        barChartView.rightAxis.axisMinimum = 0
 
        barChartView.rightAxis.axisMaximum = 500 // 12小时
        
        barChartView.rightAxis.setLabelCount(6, force: true)
        barChartView.rightAxis.gridColor = UIColor(hex: 0x9097A0, alpha: 1)
        barChartView.rightAxis.drawGridLinesEnabled = true
        barChartView.rightAxis.drawAxisLineEnabled = false
        barChartView.legend.form = .none
    }
    
    func setBarData() {
        var values: [BarChartDataEntry] = []
        initializeBarData { [weak self] updatedValues in
            // 使用 updatedValues 进行后续操作
            values += updatedValues
            let set1 = BarChartDataSet(entries: values, label: "")
            set1.drawIconsEnabled = false
            
            let data = BarChartData(dataSet: set1)
            data.barWidth = 0.5
            self?.barChartView.data = data
            
            self?.valueView.refreshView(isHideNull: values.count != 0)
            self?.barChartView.isHidden = values.count == 0
            
            set1.drawValuesEnabled = false // 不要绘制值
            // 设置柱状图的颜色
            set1.colors = [NSUIColor.kDC98FF] // 你可以使用数组来设置多个颜色
        }
        
        
    }
    
    private func initializeData(completion: @escaping ([ChartDataEntry]) -> Void) {
        var values: [ChartDataEntry] = []
        for i in 0..<24 {
            values.append(ChartDataEntry(x: Double(i), y: Double(0)))
        }
        
        if type == 0 { // 步数
            if isXGZT {
                totalValue = 0
                totalKM = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readXGZTDBStep { [weak self] stepObj in
                    var value = 0
                    if stepObj.count > 0 {
                        value = stepObj.first?.step ?? 0
                    }
                    var distance = Int(XGZTBlueToothManager.shared.device?.height ?? 0) * 415 / 1000
                    var unit = value * distance
                    var v = unit * Int(XGZTBlueToothManager.shared.device?.weight ?? 0) * 55
                    var truncated = (Float(v) / 10000).rounded(.towardZero) / 1000

                    if self?.mDate.isToday() ?? false {
                        value = XGZTBlueToothManager.shared.device?.currentStep ?? 0
                        distance = Int(XGZTBlueToothManager.shared.device?.height ?? 0) * 415 / 1000
                        unit = value * distance
                        v = unit * Int(XGZTBlueToothManager.shared.device?.weight ?? 0) * 55
                        truncated = (Float(v) / 10000).rounded(.towardZero) / 1000
                    }
                    self?.totalValue = value
                    let m = NSMutableAttributedString()
                    if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                        let new = (Float(unit) / Float(100000)) * 62 / 100
                        let truncated = (new * 1000).rounded(.towardZero)/1000
                        m.append(NSAttributedString(string: String(format: "%.3f", Float(truncated)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        m.append(NSAttributedString(string: "mile".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    } else {
                        m.append(NSAttributedString(string: String(format: "%.3f", Float(unit) / Float(100000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        m.append(NSAttributedString(string: "health_walk_unit".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    }
                    let c = NSMutableAttributedString()
                    c.append(NSAttributedString(string: String(format: "%.3f", Float(truncated)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    c.append(NSAttributedString(string: "health_kilo_calorie".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(value)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_step_noun".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))

                    self?.fanView.refreshValue(values: [m, c], value: b)
                    var goal = UserDefaults.standard.integer(forKey: "Goal")
                    if goal == 0 {
                        goal = 8000
                    }
                    self?.fanView.setProgress(CGFloat(self?.totalValue ?? 0) / CGFloat(goal))
                    
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                totalValue = 0
                totalKM = 0
                let array = readDBStep()
                var scale = 1000
                if array.count > 0 {
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].step
                        totalValue += value
                        totalKM += array[i].distance
                        let x = (array[i].timeStamp - Int(zero)) / 3600
                        let item = values[x]
                        values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(scale) + item.y)
                        if value > maxValue {
                            maxValue = value
                        }
                    }
                    if maxValue <= 50 {
                        lineChartView.rightAxis.axisMaximum = 50
                        for i in 0..<values.count {
                            values[i].y *= 100
                        }
                        scale = 100
                    } else if maxValue <= 500 {
                        lineChartView.rightAxis.axisMaximum = 500
                        for i in 0..<values.count {
                            values[i].y *= 10
                        }
                        scale = 10
                    } else {
                        lineChartView.rightAxis.axisMaximum = 5000
                        scale = 1000
                    }
                    lineChartView.notifyDataSetChanged()
                }

                var totalValue1 = 0
                let array1 = readDBStep()
                if array1.count > 0 {
                    for i in 0..<array1.count {
                        let value = array1[i].cal // 热量
                        totalValue1 += value
                    }
                }

                if array1.count > 0 && bleSelf.step > totalValue && mDate.isToday() {
                    let zero = mDate.zeroTimeStamp()
                    let x = (Int(Date().timeIntervalSince1970) - Int(zero)) / 3600
                    values[x].y += Double((bleSelf.step - totalValue)) / Double(scale)
                    totalValue = bleSelf.step
                    totalKM = bleSelf.distance
                    totalValue1 = bleSelf.cal
                    lineChartView.notifyDataSetChanged()
                }

                let m = NSMutableAttributedString()
                if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                    let new = (Float(totalKM) / Float(1000)) * 62 / 100
                    let truncated = (new * 1000).rounded(.towardZero)/1000
                    m.append(NSAttributedString(string: String(format: "%.2f", Float(truncated)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    m.append(NSAttributedString(string: "mile".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                } else {
                    m.append(NSAttributedString(string: String(format: "%.2f", Float(totalKM) / Float(1000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    m.append(NSAttributedString(string: "health_walk_unit".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                }
                
                let c = NSMutableAttributedString()
                c.append(NSAttributedString(string: String(format: "%.2f", Float(totalValue1) / Float(1000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                c.append(NSAttributedString(string: "health_kilo_calorie".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                let b = NSMutableAttributedString()
                b.append(NSAttributedString(string: "\(totalValue)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                b.append(NSAttributedString(string: "health_step_noun".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))

                fanView.refreshValue(values: [m, c], value: b)
                var goal = UserDefaults.standard.integer(forKey: "Goal")
                if goal == 0 {
                    goal = bleSelf.userInfo.stepGoal
                }
                fanView.setProgress(CGFloat(totalValue) / CGFloat(goal))
                completion(values)
            }
        } else if type == 2 { // 心率
            if isXGZT {
                var count = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readXGZTDBHeart { [weak self] heartObjs in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    let array = heartObjs
                    if array.count > 0 {
                        count = array.count
                        let zero = self.mDate.zeroTimeStampUTC()
                        for i in 0..<array.count {
                            let value = array[i].heart
                            let x = (array[i].time - Int(zero)) / 3660
                            if x >= 0 && x < 24 {
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value))
                            }
                            XLogger.shared.log("历史心率数据: \(value) \(array[i].time)")
                        }
                        XLogger.shared.log("获取到数据的数量为：\(array.count)")
                    }
                    if count > 0 {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(array.last?.heart ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(CGFloat(array.last?.heart ?? 0) / 200)
                        self.applyHealthConclusion(type: 2, doubleValue: Double(array.last?.heart ?? 0))
                    } else {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(0)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                var count = 0
                let array = readDBHeart()
                if array.count > 0 {
                    count = array.count
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].heartRate
                        let x = (array[i].timeStamp - Int(zero)) / 3660
                        if x >= 0 && x < 24 {
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value))
                        }
                    }
                    XLogger.shared.log("获取到数据的数量为：\(array.count)")
                }
                if count > 0 {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(array.last?.heartRate ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(CGFloat(array.last?.heartRate ?? 0) / 200)
                    self.applyHealthConclusion(type: 2, doubleValue: Double(array.last?.heartRate ?? 0))
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
        } else if type == 4 { // 血压
            if isXGZT {
                var count = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readPressure { [weak self] pressureObjs in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    let array = pressureObjs
                    if array.count > 0 {
                        count = array.count
                        let zero = self.mDate.zeroTimeStampUTC()
                        for i in 0..<array.count {
                            let value = array[i].max
                            let x = (array[i].time - Int(zero)) / 3660
                            if x >= 0 && x < 24 {
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value))
                            }
                        }
                        XLogger.shared.log("获取到数据的数量为：\(array.count)")
                    }
                    if count > 0 {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(array.last?.max ?? 0)/\(array.last?.min ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                        b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(CGFloat(array.last?.max ?? 0) / 200)
                    } else {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                        b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(0)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                var count = 0
                let array = readPressure()
                if array.count > 0 {
                    count = array.count
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].max
                        let x = (array[i].timeStamp - Int(zero)) / 3660
                        if x >= 0 && x < 24 {
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value))
                        }
                    }
                    XLogger.shared.log("获取到数据的数量为：\(array.count)")
                }
                if count > 0 {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(array.last?.max ?? 0)/\(array.last?.min ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                    b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(CGFloat(array.last?.max ?? 0) / 200)
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 30, weight: .black)]))
                    b.append(NSAttributedString(string: "MMHG", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
            
        } else if type == 5 { // 血氧
            if isXGZT {
                var count = 0
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                readXGZTBlood { [weak self] oxgenObjs in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    let array = oxgenObjs
                    XLogger.shared.log("从数据库里读取到的血氧数据数量为：\(array.count)")
                    if array.count > 0 {
                        count = array.count
                        let zero = self.mDate.zeroTimeStampUTC()
                        for i in 0..<array.count {
                            let value = array[i].oxgen
                            let x = (array[i].time - Int(zero)) / 3660
                            if x >= 0 && x < 24 {
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value))
                            }
                        }
                        XLogger.shared.log("获取到数据的数量为：\(array.count)")
                    }
                    if count > 0 {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(array.last?.oxgen ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(CGFloat(array.last?.oxgen ?? 0) / 200)
                        self.applyHealthConclusion(type: 5, doubleValue: Double(array.last?.oxgen ?? 0))
                    } else {
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        self.roundView.refreshView(value: b)
                        self.roundView.setProgress(0)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: .main) {
                    completion(values)
                }
            } else {
                var count = 0
                let array = readBlood()
                XLogger.shared.log("从数据库里读取到的血氧数据数量为：\(array.count)")
                if array.count > 0 {
                    count = array.count
                    let zero = mDate.zeroTimeStamp()
                    for i in 0..<array.count {
                        let value = array[i].oxygen
                        let x = (array[i].timeStamp - Int(zero)) / 3660
                        if x >= 0 && x < 24 {
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value))
                        }
                    }
                    XLogger.shared.log("获取到数据的数量为：\(array.count)")
                }
                if count > 0 {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(array.last?.oxygen ?? 0)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(CGFloat(array.last?.oxygen ?? 0) / 200)
                    self.applyHealthConclusion(type: 5, doubleValue: Double(array.last?.oxygen ?? 0))
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
        } else if type == 6 { // 心电图ECG
            completion(values)
        } else if type == 7 { // 血糖
            loadXGZTExtendedMetricData(type: 7, baseValues: values) { result in
                completion(result)
            }
        } else if type == 8 { // 尿酸
            loadXGZTExtendedMetricData(type: 8, baseValues: values) { result in
                completion(result)
            }
        } else if type == 9 { // 血脂
            loadXGZTExtendedMetricData(type: 9, baseValues: values) { result in
                completion(result)
            }
        } else if type == 10 { // 脉搏 PPG
            loadXGZTExtendedMetricData(type: 10, baseValues: values) { result in
                completion(result)
            }
        } else if type == 11 { // HRV
            loadXGZTExtendedMetricData(type: 11, baseValues: values) { result in
                completion(result)
            }
        } else if type == 12 { // 精神压力
            loadXGZTExtendedMetricData(type: 12, baseValues: values) { result in
                completion(result)
            }
        } else if type == 13 { // 疲劳度
            loadXGZTExtendedMetricData(type: 13, baseValues: values) { result in
                completion(result)
            }
        }
    }
    
    /// 血糖/尿酸/血脂 详情页：按所选日期从历史库读取 24 小时趋势数据，并刷新环形进度上的最新值
    private func loadXGZTExtendedMetricData(type: Int, baseValues: [ChartDataEntry], completion: @escaping ([ChartDataEntry]) -> Void) {
        var values = baseValues
        let date = mDate.stringFromYmd()
        let zero = Int(mDate.zeroTimeStampUTC())
        let descText: String
        switch type {
        case 7:
            descText = "health_blood_glucose_desc".localized()
            DatabaseManager.shared.getGlucoseObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: obj.value)
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue(String(format: "%.1f", latest.value), unit: " mmol/L", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(latest.value / 30.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentBloodGlucose, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue(String(format: "%.1f", v), unit: " mmol/L", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(v / 30.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " mmol/L", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    self.valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
                }
                completion(values)
            }
        case 8:
            descText = "health_uric_acid_desc".localized()
            DatabaseManager.shared.getUricAcidObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: Double(obj.value))
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue("\(latest.value)", unit: " umol/L", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(latest.value) / 1000.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentUricAcid, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue("\(v)", unit: " umol/L", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(v) / 1000.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " umol/L", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    self.valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
                }
                completion(values)
            }
        case 9:
            descText = "health_blood_lipid_desc".localized()
            DatabaseManager.shared.getLipidObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: obj.tc)
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue(String(format: "%.2f", latest.tc), unit: " mmol/L", valueFont: 32, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(latest.tc / 15.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentBloodLipid, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue(String(format: "%.2f", v), unit: " mmol/L", valueFont: 32, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(v / 15.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " mmol/L", valueFont: 32, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    self.valueView.refreshLabel(text: "health_conclusion_reference".localized(), color: UIColor(hex: 0x718096))
                }
                completion(values)
            }
        case 10: // 脉搏 PPG
            descText = "health_ppg_desc".localized()
            DatabaseManager.shared.getPpgObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: Double(obj.value))
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue("\(latest.value)", unit: " bpm", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(latest.value) / 200.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentPPG, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue("\(v)", unit: " bpm", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(v) / 200.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " bpm", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    self.valueView.refreshLabel(text: descText)
                }
                completion(values)
            }
        case 11: // 心率变异性 HRV
            descText = "health_hrv_desc".localized()
            DatabaseManager.shared.getHRVObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: Double(obj.value))
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue("\(latest.value)", unit: " ms", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(latest.value) / 200.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentHRV, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue("\(v)", unit: " ms", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(v) / 200.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " ms", valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    self.valueView.refreshLabel(text: "health_conclusion_hrv_reference".localized(), color: UIColor(hex: 0x718096))
                }
                completion(values)
            }
        case 12: // 精神压力
            descText = "health_stress_desc".localized()
            DatabaseManager.shared.getStressObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: Double(obj.value))
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue("\(latest.value)", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(latest.value) / 100.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentStress, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue("\(v)", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(v) / 100.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.applyHealthConclusion(type: 12, doubleValue: Double(latest.value))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentStress, v > 0 {
                        self.applyHealthConclusion(type: 12, doubleValue: Double(v))
                    } else {
                        self.valueView.refreshLabel(text: descText)
                    }
                }
                completion(values)
            }
        case 13: // 疲劳度
            descText = "health_fatigue_desc".localized()
            DatabaseManager.shared.getFatigueObj(byDate: date) { [weak self] results in
                let sorted = (results.map { Array($0) } ?? []).sorted { $0.time < $1.time }
                for obj in sorted {
                    let x = (obj.time - zero) / 3600
                    if x >= 0 && x < 24 {
                        values[x] = ChartDataEntry(x: Double(x), y: Double(obj.value))
                    }
                }
                if let self = self {
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.roundView.refreshView(value: self.makeRoundValue("\(latest.value)", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(latest.value) / 100.0, 1.0)))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentFatigue, v > 0 {
                        self.roundView.refreshView(value: self.makeRoundValue("\(v)", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(CGFloat(min(Double(v) / 100.0, 1.0)))
                    } else {
                        self.roundView.refreshView(value: self.makeRoundValue("--", unit: " health_score_unit".localized(), valueFont: 34, unitFont: 12))
                        self.roundView.setProgress(0)
                    }
                    if let latest = sorted.max(by: { $0.time < $1.time }) {
                        self.applyHealthConclusion(type: 13, doubleValue: Double(latest.value))
                    } else if self.mDate.isToday(), let v = XGZTBlueToothManager.shared.device?.currentFatigue, v > 0 {
                        self.applyHealthConclusion(type: 13, doubleValue: Double(v))
                    } else {
                        self.valueView.refreshLabel(text: descText)
                    }
                }
                completion(values)
            }
        default:
            completion(values)
        }
    }
    
    private func initializeBarData(completion: @escaping ([BarChartDataEntry]) -> Void) {
        var values: [BarChartDataEntry] = []
        for i in 0...4 {
            values.append(BarChartDataEntry(x: Double(i), y: Double(0)))
        }
        if type == 3 { // 睡眠
            if isXGZT {
                readXGZTDBSleep { [weak self] v in
                    guard let self = self else { return }
                    let array = v
                    if array.count > 0 {
                        let total = array[0].light + array[0].deep
                        let h = total / 60
                        let m = total % 60
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "\(h)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_hour".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        b.append(NSAttributedString(string: "\(m)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                        if array.count > 0 {
                            let m1 = array[0].awake
                            let m2 = array[0].light
                            let m3 = array[0].deep
                            let qing = NSMutableAttributedString()
                            qing.append(NSAttributedString(string: "\(m1)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                            qing.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                            let qian = NSMutableAttributedString()
                            qian.append(NSAttributedString(string: "\(m2)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                            qian.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                            let shen = NSMutableAttributedString()
                            shen.append(NSAttributedString(string: "\(m3)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                            shen.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                            self.fanView.refreshValue(values: [qing, qian, shen], value: b)
                            self.fanView.setProgress(CGFloat(total) / (60*12))
                            values[1] = BarChartDataEntry(x: Double(1), y: Double(m1) / 100)
                            values[2] = BarChartDataEntry(x: Double(2), y: Double(m2) / 100)
                            values[3] = BarChartDataEntry(x: Double(3), y: Double(m3) / 100)
                        }
                    } else {
                        let qing = NSMutableAttributedString()
                        qing.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qing.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let qian = NSMutableAttributedString()
                        qian.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qian.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let shen = NSMutableAttributedString()
                        shen.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        shen.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let b = NSMutableAttributedString()
                        b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                        b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                        b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                        self.fanView.refreshValue(values: [qing, qian, shen], value: b)
                        self.fanView.setProgress(0)
                    }
                    completion(values)
                }
            } else {
                let array = readDBSleep()
                if array.count > 0 {
                    let a = array.map { item -> SleepModel in
                        let model = SleepModel()
                        model.timeStamp = item.timeStamp
                        model.totalCount = item.totalCount
                        model.indexOfTotal = item.indexOfTotal
                        model.mac = item.mac
                        model.uuidString = item.uuidString
                        model.state = item.state
                        model.day = item.day
                        return model
                    }
                    let arr = BLEManager.shared.readSleepData(array: a) // 获得睡眠时间
                    let total = arr[1] + arr[2]
                    let h = total / 60
                    let m = total % 60
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "\(h)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_hour".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    b.append(NSAttributedString(string: "\(m)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    if arr.count == 3 {
                        let m1 = arr[2]
                        let m2 = arr[1]
                        let m3 = arr[0]
                        let qing = NSMutableAttributedString()
                        qing.append(NSAttributedString(string: "\(m1)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qing.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let qian = NSMutableAttributedString()
                        qian.append(NSAttributedString(string: "\(m2)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        qian.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        let shen = NSMutableAttributedString()
                        shen.append(NSAttributedString(string: "\(m3)", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                        shen.append(NSAttributedString(string: "health_minute".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                        fanView.refreshValue(values: [qing, qian, shen], value: b)
                        fanView.setProgress(CGFloat(total) / (60*12))
                        values[1] = BarChartDataEntry(x: Double(1), y: Double(m1) / 100)
                        values[2] = BarChartDataEntry(x: Double(2), y: Double(m2) / 100)
                        values[3] = BarChartDataEntry(x: Double(3), y: Double(m3) / 100)
                    }
                } else {
                    let qing = NSMutableAttributedString()
                    qing.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    qing.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let qian = NSMutableAttributedString()
                    qian.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    qian.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let shen = NSMutableAttributedString()
                    shen.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
                    shen.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "--", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: " ", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                    b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
                    fanView.refreshValue(values: [qing, qian, shen], value: b)
                    fanView.setProgress(0)
                }
                completion(values)
            }
        } else {
            completion(values)
        }
    }
    
    /// 选择日期
    @objc func chooseDate() {
        let pickerView = TTADataPickerView(title: "health_select_time".localized(), type: .text, delegate: nil)
        pickerView.type = .date
        pickerView.delegate = self
        pickerView.show {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = UIColor(white: 1.0, alpha: 0.01)
            })
        }
    }
    
    @IBAction func pushToGoal(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Sport", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SetTargetCViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HealthDetailViewController: ChartViewDelegate {
    // ChartViewDelegate 方法
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {

    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {

    }
}

extension HealthDetailViewController: CommonCalendarViewProtocol {
    func callbackForHide(_ date: Date) {
        commonCalendarView?.isHidden = true
        mDate = date
        setChartViewData()
        dateLabel.text = mDate.stringFromYmd()
    }
}

extension HealthDetailViewController {
    private func appendECGSample(_ value: Double) {
        ecgWaveforms.append(value)
        let totalPoints = ecgWaveforms.count
        let duration = Double(totalPoints) / ecgSampleRate
        let firstStageSeconds: Double = 10.0
        let scrollWindowSeconds: Double = 10.0
        if duration <= firstStageSeconds {
            lineChartView.xAxis.axisMinimum = 0.0
            lineChartView.xAxis.axisMaximum = firstStageSeconds
        } else {
            let axisMin = duration - scrollWindowSeconds
            lineChartView.xAxis.axisMinimum = axisMin
            lineChartView.xAxis.axisMaximum = duration
        }
        refreshECGChartIncrementally()
    }

    private func refreshECGChartIncrementally() {
        let count = ecgWaveforms.count
        let duration = Double(count) / ecgSampleRate
        var values: [ChartDataEntry] = []
        values.reserveCapacity(count)
        for i in 0..<count {
            let t = Double(i) / ecgSampleRate
            values.append(ChartDataEntry(x: t, y: ecgWaveforms[i]))
        }
        let windowSeconds: Double = 10.0
        let viewStart = max(0, duration - windowSeconds)
        if let data = lineChartView.data as? LineChartData,
           let set = data.dataSets.first as? LineChartDataSet {
            set.replaceEntries(values)
            data.notifyDataChanged()
            lineChartView.notifyDataSetChanged()
            lineChartView.moveViewToX(viewStart)
        } else {
            setECGChartViewData()
            lineChartView.moveViewToX(viewStart)
        }
    }

    private func startECGRealtimeRendering() {
        ecgWaveforms.removeAll()
        ecgPhase = 0.0
        ecgTimer?.invalidate()
        ecgHeartRateBPM = nil
        ecgWorn = false
        updateECGHeartRateDisplay(nil)
        let initialBPM: Double = 75.0
        let baseline: Double = 1000.0
        func gaussian(_ t: Double, mu: Double, sigma: Double, amp: Double) -> Double {
            let x = (t - mu) / sigma
            return amp * exp(-0.5 * x * x)
        }
        let timer = Timer(timeInterval: 1.0 / ecgSampleRate, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.ecgWorn, let hr = self.ecgHeartRateBPM, hr > 0 else {
                // 未佩戴：保持基线向左滚动，波形不缩小
                self.appendECGSample(baseline)
                return
            }
            let bpm = Double(max(40, min(220, hr)))
            let samplesPerBeat = self.ecgSampleRate * 60.0 / bpm * self.ecgWaveformStretchFactor
            let phaseStep = 1.0 / samplesPerBeat
            let p  = gaussian(self.ecgPhase, mu: 0.12, sigma: 0.03, amp: 120.0)
            let q  = gaussian(self.ecgPhase, mu: 0.22, sigma: 0.008, amp: -100.0)
            let r  = gaussian(self.ecgPhase, mu: 0.25, sigma: 0.015, amp: 900.0)
            let s  = gaussian(self.ecgPhase, mu: 0.28, sigma: 0.008, amp: -160.0)
            let t  = gaussian(self.ecgPhase, mu: 0.40, sigma: 0.035, amp: 220.0)
            let noise = (Double.random(in: -1.0...1.0)) * 12.0
            let value = baseline + p + q + r + s + t + noise
            self.appendECGSample(value)
            self.ecgPhase += phaseStep
            if self.ecgPhase >= 1.0 {
                self.ecgPhase.formTruncatingRemainder(dividingBy: 1.0)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ecgTimer = timer
    }

    private func stopECGRealtimeRendering() {
        ecgTimer?.invalidate()
        ecgTimer = nil
        setECGChartViewData()
    }

    // MARK: - ECG 倒计时提示（与 Android 详情页一致）
    private func ecgCountdownString(_ seconds: Int) -> String {
        String(format: "health_ecg_measure_remaining".localized(), seconds)
    }

    private func startECGCountdown() {
        stopECGCountdown()
        ecgMeasureCountdown = 30
        valueView.refreshLabel(text: ecgCountdownString(ecgMeasureCountdown))
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.ecgMeasureCountdown -= 1
            if self.ecgMeasureCountdown <= 0 {
                self.stopECGCountdown()
            } else {
                self.valueView.refreshLabel(text: self.ecgCountdownString(self.ecgMeasureCountdown))
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        mTimer = timer
    }

    private func stopECGCountdown() {
        mTimer?.invalidate()
        mTimer = nil
    }

    // MARK: - Android 对齐：ECG 测量点持久化与 2s 无上报自动结束

    private func resetECGStaleTimer() {
        ecgStaleTimer?.invalidate()
        let timer = Timer(timeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.finishECGMeasurement(showComplete: false)
        }
        RunLoop.main.add(timer, forMode: .common)
        ecgStaleTimer = timer
    }

    private func stopECGStaleTimer() {
        ecgStaleTimer?.invalidate()
        ecgStaleTimer = nil
    }

    /// 统一结束 ECG 测量：发送 stop、停止渲染与倒计时、保存记录
    private func finishECGMeasurement(showComplete: Bool) {
        guard isECGMeasuring else { return }
        stopECGStaleTimer()
        if isXGZT {
            XGZTCommand.startTest(cmdType: 6, control: 0)
        }
        isECGMeasuring = false
        stopECGRealtimeRendering()
        stopECGCountdown()
        saveECGRecord()
        NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: showComplete ? "ecg_complete" : nil)
    }

    private func startECGRecording() {
        ecgRecordId = UUID().uuidString
        ecgStartUptime = ProcessInfo.processInfo.systemUptime
        ecgPoints.removeAll()
        ecgSaveErrorShown = false
        resetECGStaleTimer()
    }

    private func saveECGRecord() {
        let validPoints = ecgPoints.filter { $0.heartRate > 0 }
        guard !validPoints.isEmpty, !ecgRecordId.isEmpty else { return }
        let obj = EcgHistoryObj()
        obj.id = ecgRecordId
        obj.address = lastestDeviceMac
        obj.startedAt = Date().timeIntervalSince1970 * 1000
        obj.durationMillis = (validPoints.last?.offsetMillis).map { Int($0) } ?? 0
        obj.samplesJson = DatabaseManager.encodeEcgPoints(validPoints)
        DatabaseManager.shared.addEcgHistoryObj(ecgObj: obj)
    }

    @objc private func ecgHistoryTapped() {
        stopECGStaleTimer()
        let vc = EcgHistoryViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HealthDetailViewController {
    // MARK: - 脉搏波 PPG 实时平滑波形渲染（算法对齐 mock_phone_app._get_ppg_point）

    private func appendPPGSample(_ value: Double) {
        ppgWaveforms.append(value)
        let totalPoints = ppgWaveforms.count
        let duration = Double(totalPoints) / ppgSampleRate
        if duration <= ppgWindowSeconds {
            lineChartView.xAxis.axisMinimum = 0.0
            lineChartView.xAxis.axisMaximum = ppgWindowSeconds
        } else {
            let axisMin = duration - ppgWindowSeconds
            lineChartView.xAxis.axisMinimum = axisMin
            lineChartView.xAxis.axisMaximum = duration
        }
        refreshPPGChartIncrementally()
    }

    private func refreshPPGChartIncrementally() {
        let count = ppgWaveforms.count
        let duration = Double(count) / ppgSampleRate
        var values: [ChartDataEntry] = []
        values.reserveCapacity(count)
        for i in 0..<count {
            let t = Double(i) / ppgSampleRate
            values.append(ChartDataEntry(x: t, y: ppgWaveforms[i]))
        }
        let viewStart = max(0, duration - ppgWindowSeconds)
        if let data = lineChartView.data as? LineChartData,
           let set = data.dataSets.first as? LineChartDataSet {
            set.replaceEntries(values)
            data.notifyDataChanged()
            lineChartView.notifyDataSetChanged()
            lineChartView.moveViewToX(viewStart)
        } else {
            setPPGChartViewData()
            lineChartView.moveViewToX(viewStart)
        }
    }

    /// 标准连续医疗 PPG 脉搏波动力学模型：
    /// 1. 收缩期快速射血陡升支 2. 收缩主峰 3. 重搏切迹 (Dicrotic Notch) 4. 舒张期反射次峰 5. 连续光滑的血管弹性舒张径流衰减
    private func ppgWaveValue(_ t: Double, bpm: Double) -> Double {
        if t < 0 || bpm <= 0 {
            return ppgBaseline + Double.random(in: -0.5...0.5)
        }
        let hr = Double(max(48.0, min(130.0, bpm)))
        let scale = 0.48 + ((hr - 48.0) / 75.0) * 0.85
        let cycleSec = 60.0 / hr
        let theta = (t.truncatingRemainder(dividingBy: cycleSec)) / cycleSec
        let amp = 55.0

        // 1. 收缩期主波峰（快速射血）
        let mainPeak = 56.0 * scale * amp * exp(-pow(theta - 0.18, 2) / (2 * 0.065 * 0.065))
        // 2. 舒张期次峰（主动脉瓣关闭反射波）
        let diastolicPeak = 20.0 * scale * amp * exp(-pow(theta - 0.38, 2) / (2 * 0.055 * 0.055))
        // 3. 连续血管弹性舒张底基（消除死平基线，平滑延续至下一个周期起点）
        let decayBase: Double
        if theta >= 0.16 {
            decayBase = 26.0 * scale * amp * exp(-(theta - 0.16) / 0.32)
        } else {
            decayBase = 26.0 * scale * amp * exp(-(theta + 1.0 - 0.16) / 0.32)
        }

        let val = mainPeak + diastolicPeak + decayBase
        let noise = Double.random(in: -1.0...1.0) * 0.5
        return ppgBaseline - val + noise
    }

    private func startPPGRealtimeRendering() {
        ppgWaveforms.removeAll()
        ppgPhase = 0.0
        ppgTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / ppgSampleRate, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let hasDevice = XGZTBlueToothManager.shared.device != nil
            // 无设备或未在测量：用默认脉率模拟波形，保证直接运行（无设备）也能看到平滑脉搏波
            let simBPM: Double = 75.0
            if !hasDevice || !self.isPPGMeasuring {
                let v = self.ppgWaveValue(self.ppgPhase, bpm: simBPM)
                self.appendPPGSample(v)
                self.ppgPhase += 1.0 / self.ppgSampleRate
                if self.ppgPhase >= 60.0 / simBPM * 2 {
                    self.ppgPhase.formTruncatingRemainder(dividingBy: 60.0 / simBPM)
                }
                return
            }
            // 有设备且正在测量：真实脉率驱动，脱腕/0 时平直基线 + 微小底噪
            guard self.ppgWorn, let bpm = self.ppgHeartRateBPM, bpm > 0 else {
                self.appendPPGSample(self.ppgBaseline + Double.random(in: -0.5...0.5))
                self.ppgPhase = 0.0
                return
            }
            let period = 60.0 / Double(bpm)
            let v = self.ppgWaveValue(self.ppgPhase, bpm: Double(bpm))
            self.appendPPGSample(v)
            self.ppgPhase += 1.0 / self.ppgSampleRate
            if self.ppgPhase >= period * 2 {
                self.ppgPhase.formTruncatingRemainder(dividingBy: period)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ppgTimer = timer
    }

    private func stopPPGRealtimeRendering() {
        ppgTimer?.invalidate()
        ppgTimer = nil
        setPPGChartViewData()
    }

    // MARK: - 脉搏波 PPG 倒计时提示
    private func ppgCountdownString(_ seconds: Int) -> String {
        String(format: "ppg_measure_remaining".localized(), seconds)
    }

    private func startPPGCountdown() {
        stopPPGCountdown()
        ppgMeasureCountdown = 30
        valueView.refreshLabel(text: ppgCountdownString(ppgMeasureCountdown))
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.ppgMeasureCountdown -= 1
            if self.ppgMeasureCountdown <= 0 {
                self.stopPPGCountdown()
            } else {
                self.valueView.refreshLabel(text: self.ppgCountdownString(self.ppgMeasureCountdown))
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        mTimer = timer
    }

    private func stopPPGCountdown() {
        mTimer?.invalidate()
        mTimer = nil
    }

    private func finishPPGMeasurement(showComplete: Bool) {
        guard isPPGMeasuring else { return }
        if isXGZT {
            XGZTCommand.startTest(cmdType: 7, control: 0)
        }
        isPPGMeasuring = false
        stopPPGCountdown()
        fanView.isHidden = true
        roundView.isHidden = true
        testView.isHidden = true
        if screenHeight <= 667 {
            addTest()
        } else {
            if let btn = view.viewWithTag(8888) as? UIButton {
                btn.isHidden = false
            }
        }
        valueView.refreshLabel(text: showComplete ? "ppg_measure_complete".localized() : "health_ppg_desc".localized())
    }
}

extension HealthDetailViewController {
    func changeTimeToWeek(_ value: Int) -> String {
        switch value {
        case 0:
            return "week_7".localized()
        case 1:
            return "week_1".localized()
        case 2:
            return "week_2".localized()
        case 3:
            return "week_3".localized()
        case 4:
            return "week_4".localized()
        case 5:
            return "week_5".localized()
        default:
            return "week_6".localized()
        }
    }
}

extension HealthDetailViewController {
    func readDBStep() -> [DStepModel] {
        XLogger.shared.log("你想查询的设备的mac地址是：\(lastestDeviceMac)")
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DStepModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readXGZTDBStep(completion: @escaping ([StepObj]) -> Void) {
        DatabaseManager.shared.getStepObj(byDate: mDate.stringFromYmd()) { results in
            let objs = results?.map { $0 } ?? []
            completion(objs)
        }
    }
    
    
    func readDBHeart() -> [DHeartRateModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DHeartRateModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readXGZTDBHeart(completion: @escaping ([HeartObj]) -> Void) {
        DatabaseManager.shared.getHeartObj(byDate: mDate.stringFromYmd()) { results in
            let heartObjs = results?.map { $0 } ?? []
            completion(heartObjs)
        }
    }
    
    
    func readDBSleep() -> [DSleepModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DSleepModel.er.array("timeStamp>=\(stamp - 2 * 60 * 60) AND timeStamp<\(stamp + 10 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
        
    }
    
    func readXGZTDBSleep(completion: @escaping ([SleepObj]) -> Void) {
        if mDate.isToday() {
            let sleep = XGZTBlueToothManager.shared.device?.currentSleepArray ?? [0, 0, 0]
            if sleep[0] + sleep[1] + sleep[2] > 0 {
                let sleepObj = SleepObj()
                sleepObj.date = mDate.stringFromYmd()
                sleepObj.mac = lastestDeviceMac
                sleepObj.awake = sleep[0]
                sleepObj.light = sleep[1]
                sleepObj.deep = sleep[2]
                completion([sleepObj])
                return
            }
        }
        DatabaseManager.shared.getSleepObj(byDate: mDate.stringFromYmd()) { results in
            let objs = results?.map { $0 } ?? []
            completion(objs)
        }
        
    }
    
    func readPressure() -> [DBloodModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DBloodModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readPressure(completion: @escaping ([BloodObj]) -> Void) {
        DatabaseManager.shared.getBloodObj(byDate: mDate.stringFromYmd()) { results in
            let objs = results?.map { $0 } ?? []
            completion(objs)
        }
    }
    
    func readBlood() -> [DOxygenModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DOxygenModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readXGZTBlood(completion: @escaping ([OxgenObj]) -> Void) {
        DatabaseManager.shared.getOxgenObj(byDate: mDate.stringFromYmd()) { results in
            let oxgenObjs = results?.map { $0 } ?? []
            completion(oxgenObjs)
        }
    }
}

extension HealthDetailViewController: TTADataPickerViewDelegate {
    // when the pickerView type is `.text`, you clicked the done button, you will get the titles you selected just now from the `titles` parameter
    func dataPickerView(_ pickerView: TTADataPickerView, didSelectTitles titles: [String]) {
        //showLabel.text = titles.joined(separator: " ")
    }
    // when the pickerView type is NOT `.text`, you clicked the done button, you will get the date you selected just now from the `date` parameters
    func dataPickerView(_ pickerView: TTADataPickerView, didSelectDate date: Date) {
        mDate = date
        setChartViewData()
        dateLabel.text = mDate.stringFromYmd()
    }
    // when the pickerView  has been changed, this function will be called, and you will get the row and component which changed just now
    func dataPickerView(_ pickerView: TTADataPickerView, didChange row: Int, inComponent component: Int) {
        XLogger.shared.log(#function)
    }
    // when you clicked the cancel button, this function will be called firstly
    func dataPickerViewWillCancel(_ pickerView: TTADataPickerView) {
        XLogger.shared.log(#function)
    }
    // when you clicked the cancel button, this function will be called at the last
    func dataPickerViewDidCancel(_ pickerView: TTADataPickerView) {
        XLogger.shared.log(#function)
    }
}

extension HealthDetailViewController: TestViewDelegate {
    func handleStartTest() {
        if isXGZT{
            if type == 2 {
                XGZTCommand.startTest(cmdType: 0, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                    
                }
            }
            if type == 4 {
                XGZTCommand.startTest(cmdType: 2, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }
            
            if type == 5 {
                XGZTCommand.startTest(cmdType: 1, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }

            if type == 7 {
                XGZTCommand.startTest(cmdType: 3, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }

            if type == 8 {
                XGZTCommand.startTest(cmdType: 4, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }

            if type == 9 {
                XGZTCommand.startTest(cmdType: 5, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }

            if type == 10 {
                XGZTCommand.startTest(cmdType: 7, control: 1)
                isPPGMeasuring = true
                ppgHeartRateBPM = nil
                ppgWorn = false
                ppgWornLabel?.isHidden = true
                startPPGRealtimeRendering()
                startPPGCountdown()
                measureAsync = Async.main(after: 30) { [weak self] in
                    self?.finishPPGMeasurement(showComplete: true)
                }
            }

            if type == 11 {
                XGZTCommand.startTest(cmdType: 8, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }

            if type == 12 {
                XGZTCommand.startTest(cmdType: 9, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }

            if type == 13 {
                XGZTCommand.startTest(cmdType: 10, control: 1)
                testView.testing()
                measureAsync = Async.main(after: 30) {
                    // do something for update UI
                }
            }
            
            if type == 6 {
                XGZTCommand.startTest(cmdType: 6, control: 1)
                isECGMeasuring = true
                startECGRecording()
                startECGRealtimeRendering()
                startECGCountdown()
                measureAsync = Async.main(after: 30) { [weak self] in
                    self?.finishECGMeasurement(showComplete: true)
                }
            }
            return
        }
        if type == 2 {
            bleSelf.startMeasure(WristbandMeasureType.heart)
            testView.testing()
            measureAsync = Async.main(after: 30) {
                // do something for update UI
                
            }
        }
        if type == 4 {
            bleSelf.startMeasure(WristbandMeasureType.blood)
            testView.testing()
            measureAsync = Async.main(after: 30) {
                // do something for update UI
            }
        }
        
        if type == 5 {
            bleSelf.startMeasure(WristbandMeasureType.oxygen)
            testView.testing()
            measureAsync = Async.main(after: 30) {
                // do something for update UI
            }
        }
        
        if type == 6 {
            isECGMeasuring = true
            startECGRecording()
            startECGRealtimeRendering()
            startECGCountdown()
            measureAsync = Async.main(after: 30) { [weak self] in
                self?.finishECGMeasurement(showComplete: true)
            }
        }
    }
}

class CustomXAxisFormatter: NSObject, IAxisValueFormatter {
    var labels: [String] = []

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard labels.indices.contains(index) else {
            return ""
        }
        return labels[index]
    }
}
