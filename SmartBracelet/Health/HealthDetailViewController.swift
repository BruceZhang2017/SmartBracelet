//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  HealthDetailViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK
import RealmSwift

class HealthDetailViewController: BaseViewController {
    let lineChartView: LineChartView = LineChartView()
    let barChartView: BarChartView = BarChartView()
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
        }
        if type == 4 {
            title = "health_blood_pressure".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            testView.setupView()
            valueView.refreshLabel(text: "blood_pressure_desc".localized())
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
        
        if type == 3 {
            setBarChartView()
            setBarData()
        } else {
            setupChart()
            setChartViewData()
        }
        dateLabel.text = mDate.stringFromYmd()
        
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
    
    private func addTest() {
        let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
        if bk {
            return
        }
        
        if bleSelf.isConnected == false && XGZTBlueToothManager.shared.device == nil {
            return
        }
        
        if isXGZT {
            return
        }
        
//        if (type == 2 && isXGZT) && (XGZTBlueToothManager.shared.device?.brandID ?? 0) == 0 {
//            return
//        }
//        
//        if (type == 5 && isXGZT) && (XGZTBlueToothManager.shared.device?.brandID ?? 0) == 0  {
//            return
//        }
        
        if screenHeight <= 667 {
            // 创建一个UIBarButtonItem
            let rightButton = UIBarButtonItem(title: "health_start_test".localized(), style: .plain, target: self, action: #selector(self.rightBarButtonAction))
            // 设置字体颜色
            rightButton.tintColor = UIColor.white
            // 将UIBarButtonItem设置为navigationItem的右侧按钮
            self.navigationItem.rightBarButtonItem = rightButton
        } else {
            let testButton = UIButton(type: .custom)
            testButton.tag = 8888
            testButton.setTitle("health_start_test".localized(), for: .normal)
            testButton.setTitleColor(UIColor.brand, for: .normal)
            testButton.layer.borderColor = UIColor.brand.cgColor
            testButton.layer.borderWidth = 1.0
            testButton.backgroundColor = .white
            testButton.layer.cornerRadius = 22
            // 添加按钮到视图中
            view.addSubview(testButton)
            testButton.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(150)
                make.height.equalTo(44)
                make.bottom.equalTo(valueView.snp.top).offset(-10)
            }
            testButton.addTarget(self, action: #selector(rightBarButtonAction), for: .touchUpInside)
        }
        
    }
    
    // UIBarButtonItem的点击事件处理器
    @objc func rightBarButtonAction() {
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
        UINavigationBar.appearance().tintColor = UIColor.text_primary
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 前一天按钮点击事件
    @objc func prevDayTapped() {
        mDate = Calendar.current.date(byAdding: .day, value: -1, to: mDate)!
        dateLabel.text = mDate.stringFromYmd()
        if type == 3 {
            setBarData()
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
        } else {
            setChartViewData() // 刷新数据
        }
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if testView.isHidden == false {
            testView.stop()
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
            if type == 2 || type == 4 || type == 5 {
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
        } else {
            setChartViewData() // 刷新数据
        }
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
        lineChartView.xAxis.axisMinimum = Double(0)
        lineChartView.xAxis.axisMaximum = Double(23)
        lineChartView.xAxis.setLabelCount(24, force: true)
        lineChartView.xAxis.gridColor = UIColor.clear
        lineChartView.xAxis.drawGridLinesEnabled = true
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
        
        lineChartView.leftAxis.labelTextColor = UIColor.clear
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.leftAxis.axisMaximum = 5
        lineChartView.leftAxis.setLabelCount(6, force: true)
        lineChartView.leftAxis.gridColor = UIColor.clear
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        
        lineChartView.rightAxis.labelTextColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.rightAxis.axisMinimum = 0
        if type == 0 {
            lineChartView.rightAxis.axisMaximum = 5000
        } else if type == 2 {
            lineChartView.rightAxis.axisMaximum = 200
        } else if type == 4 {
            lineChartView.rightAxis.axisMaximum = 200
        } else if type == 5 {
            lineChartView.rightAxis.axisMaximum = 100
        }
        lineChartView.rightAxis.setLabelCount(6, force: true)
        lineChartView.rightAxis.gridColor = UIColor(hex: 0x9097A0, alpha: 1)
        lineChartView.rightAxis.drawGridLinesEnabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.legend.form = .none
    }
    
    func setChartViewData() {
        var values: [ChartDataEntry] = []
        initializeData { [weak self] v in
            // Handle the values array here
            values += v
            let set1 = LineChartDataSet(entries: values, label: "")
            set1.drawIconsEnabled = false
            
            set1.setColor(UIColor.brand)
            set1.lineWidth = 1
            set1.valueFont = .systemFont(ofSize: 9)
            set1.formLineWidth = 0.5
            set1.mode = .horizontalBezier
            set1.drawValuesEnabled = false // 不要绘制值
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
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
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
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
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
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
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
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
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
                                values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(20))
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
                            values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(20))
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
                } else {
                    let b = NSMutableAttributedString()
                    b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
                    b.append(NSAttributedString(string: "SPO2", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
                    roundView.refreshView(value: b)
                    roundView.setProgress(0)
                }
                completion(values)
            }
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

