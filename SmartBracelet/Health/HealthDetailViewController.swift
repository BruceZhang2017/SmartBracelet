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

class HealthDetailViewController: BaseViewController {
    let lineChartView: LineChartView = LineChartView()
    let pieChartView: PieChartView = PieChartView()
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
        
//        unitBLabel.text = "health_step_noun".localized()
//        dataDynamicLabel.text = "health_data_dynamic".localized()
        
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
            fanView.setupView(titles: ["health_distance".localized(), "消耗"], values: [m, c], title: "今日步数", value: b)
        }
        if type == 2 {
            title = "health_heart_rate".localized()
            fanView.isHidden = true
            roundView.isHidden = false
            testView.isHidden = true
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: "次/分", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
            roundView.setupView(value: b)
        }
        if type == 3 {
            title = "health_sleep".localized()
            fanView.isHidden = false
            roundView.isHidden = true
            testView.isHidden = true
            let qing = NSMutableAttributedString()
            qing.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            qing.append(NSAttributedString(string: "m", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let qian = NSMutableAttributedString()
            qian.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            qian.append(NSAttributedString(string: "m", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let shen = NSMutableAttributedString()
            shen.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            shen.append(NSAttributedString(string: "m", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
            let b = NSMutableAttributedString()
            b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: "H", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
            b.append(NSAttributedString(string: "0", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 40, weight: .black)]))
            b.append(NSAttributedString(string: "M", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
            fanView.setupView(titles: ["清醒", "浅睡", "深睡"], values: [qing, qian, shen], title: "今日睡眠", value: b)
        }
        if type == 4 {
            title = "health_blood_pressure".localized()
            fanView.isHidden = true
            roundView.isHidden = true
            testView.isHidden = false
            testView.setupView()
        }
        if type == 5 {
            title = "health_blood_oxygen".localized()
            fanView.isHidden = true
            roundView.isHidden = true
            testView.isHidden = false
            testView.setupView()
        }
        
        if type == 3 {
            //lineChartView.isHidden = true
            setupPieChart()
            setDataCount()
        } else {
            //pieChartView.isHidden = true
            setupChart()
            setData()
        }
        dateLabel.text = mDate.stringFromYmd()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if type == 0 {
            
        } else if type == 2 {
            //goalLabel.isHidden = true
        }
//        unitBLabel.text = type == 0 ? "health_step_noun".localized() : "health_kilo_calorie".localized()
//        tipLabel.text = type == 0 ? "every_day_goal".localized() : "每日热量目标"
//        goalView.isHidden = type > 0
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
    }

    // 后一天按钮点击事件
    @objc func nextDayTapped() {
        mDate = Calendar.current.date(byAdding: .day, value: 1, to: mDate)!
        dateLabel.text = mDate.stringFromYmd()
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        testView.stop()
        setData() // 刷新数据
    }
    
    /// 设置图表
    private func setupChart() {
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
        } else if type == 1 {
            lineChartView.rightAxis.axisMaximum = 50000
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
    
    func setData() {
        var values: [ChartDataEntry] = []
        values += initializeData()
        let set1 = LineChartDataSet(entries: values, label: "")
        set1.drawIconsEnabled = false
        
        set1.setColor(UIColor.brand)
        set1.lineWidth = 1
        set1.valueFont = .systemFont(ofSize: 9)
        set1.formLineWidth = 0.5
        set1.mode = .horizontalBezier
        set1.drawValuesEnabled = false // 不要绘制值
        set1.drawCirclesEnabled = true
        set1.circleRadius = 3
        set1.circleHoleRadius = 3
        
        let gradientColors = [ChartColorTemplates.colorFromString("#FFFFFFFF").cgColor,
                              ChartColorTemplates.colorFromString("#88FFFFFF").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!

        set1.fillAlpha = 0.25
        set1.fill = Fill(linearGradient: gradient, angle: 90)
        set1.drawFilledEnabled = true
        
        let data = LineChartData(dataSet: set1)

        lineChartView.data = data
        
        valueView.refreshView(isHideNull: values.count != 0)
        lineChartView.isHidden = values.count == 0
    }
    
    private func setupPieChart() {
        pieChartView.delegate = self
        pieChartView.drawHoleEnabled = false
        let l = pieChartView.legend
        l.horizontalAlignment = .right
        l.verticalAlignment = .top
        l.orientation = .vertical
        l.xEntrySpace = 7
        l.yEntrySpace = 0
        l.yOffset = 0
        //pieChartView.legend = l

        // entry label styling
        pieChartView.entryLabelColor = .white
        pieChartView.entryLabelFont = .systemFont(ofSize: 12, weight: .light)
        
        pieChartView.animate(xAxisDuration: 0.4, easingOption: .easeOutBack)
    }
    
    func setDataCount() {
        var models: [PieChartDataEntry] = []
        let array = ["health_detail_sleep_awake".localized(), "health_detail_sleep_light".localized(), "health_detail_sleep_deep".localized()]
        let entries = initializePreData()
        for (index, item) in entries.enumerated() {
            models.append(PieChartDataEntry(value: item, label: array[index]))
        }
        
        let set = PieChartDataSet(entries: models, label: "")
        set.drawIconsEnabled = false
        set.sliceSpace = 2
        
        set.colors = ChartColorTemplates.vordiplom()
            + ChartColorTemplates.joyful()
            + ChartColorTemplates.colorful()
            + ChartColorTemplates.liberty()
            + ChartColorTemplates.pastel()
            + [UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)]
        
        let data = PieChartData(dataSet: set)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        
        data.setValueFont(UIFont.systemFont(ofSize: 11))
        data.setValueTextColor(.black)
        
        pieChartView.data = data
        pieChartView.highlightValues(nil)
    }
    
    private func initializeData() -> [ChartDataEntry] {
        var values: [ChartDataEntry] = []
        for i in 0..<24 {
            values.append(ChartDataEntry(x: Double(i), y: Double(0)))
        }
        if type == 0 { // 步数
            totalValue = 0
            totalKM = 0
            let array = readDBStep()
            if array.count > 0 {
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].step
                    totalValue += value
                    totalKM += array[i].distance
                    let x = (array[i].timeStamp - Int(zero)) / 3660
                    let item = values[x]
                    values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(1000) + item.y)
                }
            }

            var totalValue1 = 0
            let array1 = readDBStep()
            if array1.count > 0 {
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array1.count {
                    let value = array1[i].cal // 热量
                    totalValue1 += value
                    let x = (array1[i].timeStamp - Int(zero)) / 3660
                    let item = values[x]
                    values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(10000) + item.y)
                }
            }
            
            let m = NSMutableAttributedString()
            m.append(NSAttributedString(string: String(format: "%.2f", Float(totalKM) / Float(1000)), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .black)]))
            m.append(NSAttributedString(string: "health_walk_unit".localized(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
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
        } else if type == 2 { // 心率
            var count = 0
            let array = readDBHeart()
            if array.count > 0 {
                count = array.count
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].heartRate
                    let x = (array[i].timeStamp - Int(zero)) / 3660
                    values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
                }
                print("获取到数据的数量为：\(values.count)")
            }
            if count > 0 {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "\(array.last!.heartRate)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
            }
        } else if type == 4 { // 血压
            var count = 0
            let array = readPressure()
            if array.count > 0 {
                count = array.count
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].max
                    let x = (array[i].timeStamp - Int(zero)) / 3660
                    values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(40))
                }
                print("获取到数据的数量为：\(values.count)")
            }
            if count > 0 {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "\(array.last!.max)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
            }
        } else if type == 5 { // 血氧
            var count = 0
            let array = readBlood()
            print("从数据库里读取到的血氧数据数量为：\(array.count)")
            if array.count > 0 {
                count = array.count
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].oxygen
                    let x = (array[i].timeStamp - Int(zero)) / 3660
                    values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(20))
                }
                print("获取到数据的数量为：\(values.count)")
            }
            if count > 0 {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "\(array.last!.oxygen)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
            }
        }
        return values
    }
    
    private func initializePreData() -> [Double] {
        if type == 3 { // 睡眠
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
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
                if arr.count == 3 {
                    let h1 = arr[2] / 60
                    let m1 = arr[2] % 60
                    let h2 = arr[1] / 60
                    let m2 = arr[1] % 60
                    let h3 = arr[0] / 60
                    let m3 = arr[0] % 60
                    //goalLabel.text = "\("health_detail_sleep_deep".localized())\(h1)\("health_hour".localized())\(m1)\("health_minute".localized()) \("health_detail_sleep_light".localized())\(h2)\("health_hour".localized())\(m2)\("health_minute".localized()) \("health_detail_sleep_awake".localized())\(h3)\("health_hour".localized())\(m3)\("health_minute".localized())"
                    let total = h1 * 60 + m1 + h2 * 60 + m2 + h3 * 60 + m3
                    return [Double(h3 * 60 + m3) * 100 / Double(total), Double(h2 * 60 + m2) * 100 / Double(total), Double(h1 * 60 + m1) * 100 / Double(total)]
                }
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                //valueLabel.attributedText = arrStr
                //goalLabel.text = "\("health_detail_sleep_deep".localized())0\("health_hour".localized())0\("health_minute".localized()) \("health_detail_sleep_light".localized())0\("health_hour".localized())0\("health_minute".localized()) \("health_detail_sleep_awake".localized())0\("health_hour".localized())0\("health_minute".localized())"
            }
        }
        return [100, 0, 0]
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
    
}

extension HealthDetailViewController: CommonCalendarViewProtocol {
    func callbackForHide(_ date: Date) {
        commonCalendarView?.isHidden = true
        mDate = date
        setData()
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
        print("你想查询的设备的mac地址是：\(lastestDeviceMac)")
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DStepModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    
    func readDBHeart() -> [DHeartRateModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DHeartRateModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readDBSleep() -> [DSleepModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DSleepModel.er.array("timeStamp>=\(stamp - 2 * 60 * 60) AND timeStamp<\(stamp + 10 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
        
    }
    
    func readPressure() -> [DBloodModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DBloodModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
    }
    
    func readBlood() -> [DOxygenModel] {
        let stamp = Int(mDate.zeroTimeStamp())
        let models = try? DOxygenModel.er.array("timeStamp>\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
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
        setData()
        dateLabel.text = mDate.stringFromYmd()
    }
    // when the pickerView  has been changed, this function will be called, and you will get the row and component which changed just now
    func dataPickerView(_ pickerView: TTADataPickerView, didChange row: Int, inComponent component: Int) {
        print(#function)
    }
    // when you clicked the cancel button, this function will be called firstly
    func dataPickerViewWillCancel(_ pickerView: TTADataPickerView) {
        print(#function)
    }
    // when you clicked the cancel button, this function will be called at the last
    func dataPickerViewDidCancel(_ pickerView: TTADataPickerView) {
        print(#function)
    }
}

extension HealthDetailViewController: TestViewDelegate {
    func handleStartTest() {
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


