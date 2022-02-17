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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var gradentView: UIView!
    @IBOutlet weak var goalView: UIView!
    @IBOutlet weak var dateLabel: UILabel! // 日期
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var unitBLabel: UILabel!
    @IBOutlet weak var kmLabel: UILabel!
    @IBOutlet weak var goalBLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var dataDynamicLabel: UILabel!
    @IBOutlet weak var startTestButton: UIButton! // 开始测试按钮
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
        super.viewDidLoad()
        if type == 3 {
            lineChartView.isHidden = true
            setupPieChart()
            setDataCount()
        } else {
            pieChartView.isHidden = true
            setupChart()
            setData()
        }
        setupProperty()
        
        unitBLabel.text = "health_step_noun".localized()
        dataDynamicLabel.text = "health_data_dynamic".localized()
        
        startTestButton.setTitleColor(UIColor.white, for: .normal)
        startTestButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        startTestButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        startTestButton.isHidden = type <= 0 || type == 3
        startTestButton.clipsToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("healthDetail"), object: nil)
        
        if type == 0 {
            title = "health_step".localized()
        }
        if type == 2 {
            title = "health_heart_rate".localized()
        }
        if type == 3 {
            title = "health_sleep".localized()
        }
        if type == 4 {
            title = "health_blood_pressure".localized()
        }
        if type == 5 {
            title = "health_blood_oxygen".localized()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type == 0 {
            var goal = UserDefaults.standard.integer(forKey: "Goal")
            if goal == 0 {
                goal = bleSelf.userInfo.stepGoal
            }
            goalLabel.text = "\("health_goal".localized()) \(goal)"
            goalBLabel.text = "\(goal)"
        }
        //kmLabel.isHidden = type != 0
        if type == 0 {
            
        } else if type == 1 {
            
        } else if type == 2 {
            goalLabel.isHidden = true
        }
        unitBLabel.text = type == 0 ? "health_step_noun".localized() : "health_kilo_calorie".localized()
        tipLabel.text = type == 0 ? "每日步数目标" : "每日热量目标"
        goalView.isHidden = type > 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        startTestButton.setTitle("开始测试", for: .normal)
        startTestButton.isUserInteractionEnabled = true
        endColorChangeAnimation()
        setData() // 刷新数据
    }
    
    /// 设置图表
    private func setupChart() {
        lineChartView.delegate = self
        
        lineChartView.chartDescription?.enabled = false
        lineChartView.dragEnabled = false
        lineChartView.setScaleEnabled(false)
        lineChartView.pinchZoomEnabled = false
        
        lineChartView.xAxis.labelTextColor = UIColor.white
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
        
        lineChartView.rightAxis.labelTextColor = UIColor.white
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
        lineChartView.rightAxis.gridColor = UIColor.white
        lineChartView.rightAxis.drawGridLinesEnabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.legend.form = .none
    }
    
    func setData() {
        var values: [ChartDataEntry] = []
        values += initializeData()
        let set1 = LineChartDataSet(entries: values, label: "")
        set1.drawIconsEnabled = false
        
        set1.setColor(UIColor.white)
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
        let array = ["清醒", "浅睡", "深睡"]
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
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "\(totalValue)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
            arrStr.append(NSAttributedString(string: "\("health_step_noun".localized())", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
            valueLabel.attributedText = arrStr
            kmLabel.text = "\(String(format: "%.2f", Float(totalKM) / Float(1000))) \("health_walk_unit".localized())"
        } else if type == 1 { // 热量 卡路里
            totalValue = 0
            let array = readDBStep()
            if array.count > 0 {
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].cal // 热量
                    totalValue += value
                    let x = (array[i].timeStamp - Int(zero)) / 3660
                    let item = values[x]
                    values[x] = ChartDataEntry(x: Double(x), y: Double(value) / Double(10000) + item.y)
                }
            }
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "\(String(format: "%.2f", Float(totalValue) / Float(1000)))", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
            arrStr.append(NSAttributedString(string: "health_kilo_calorie".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
            valueLabel.attributedText = arrStr
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
                valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
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
                valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
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
                valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
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
                valueLabel.attributedText = arrStr
                if arr.count == 3 {
                    let h1 = arr[2] / 60
                    let m1 = arr[2] % 60
                    let h2 = arr[1] / 60
                    let m2 = arr[1] % 60
                    let h3 = arr[0] / 60
                    let m3 = arr[0] % 60
                    goalLabel.text = "深睡\(h1)\("health_hour".localized())\(m1)\("health_minute".localized()) 浅睡\(h2)\("health_hour".localized())\(m2)\("health_minute".localized()) 清醒\(h3)\("health_hour".localized())\(m3)\("health_minute".localized())"
                    let total = h1 * 60 + m1 + h2 * 60 + m2 + h3 * 60 + m3
                    return [Double(h3 * 60 + m3) * 100 / Double(total), Double(h2 * 60 + m2) * 100 / Double(total), Double(h1 * 60 + m1) * 100 / Double(total)]
                }
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
                goalLabel.text = "深睡0\("health_hour".localized())0\("health_minute".localized()) 浅睡0\("health_hour".localized())0\("health_minute".localized()) 清醒0小时0\("health_minute".localized())"
            }
        }
        return [100, 0, 0]
    }

    private func setupProperty() {
        goalView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.3)
        if type != 3 {
            gradentView.addGradientLayer(at: CGRect(x: 0, y: 0, width: ScreenWidth, height: 322), colors: colors)
        }
        dateLabel.isUserInteractionEnabled = true
        let times = getTimes(date: mDate)
        dateLabel.text = changeTimeToWeek(times[6]) + "\(times[1])/\(times[2])"
    }
    
    /// 选择日期
    @IBAction func chooseDate(_ sender: Any) {
//        if commonCalendarView != nil {
//            commonCalendarView?.isHidden = !commonCalendarView!.isHidden
//            return
//        }
//        commonCalendarView = Bundle.main.loadNibNamed("CommonCalendarView", owner: nil, options: nil)?.first as? CommonCalendarView
//        commonCalendarView?.delegate = self
//        view.addSubview(commonCalendarView!)
//        commonCalendarView?.snp.makeConstraints {
//            $0.left.right.equalToSuperview()
//            $0.top.equalTo(dateLabel.snp.bottom)
//            $0.bottom.equalToSuperview()
//        }
        let pickerView = TTADataPickerView(title: "选择时间", type: .text, delegate: nil)
        pickerView.type = .date
        /* Set `minimumDate` and `maximumDate`
        pickerView.minimumDate = Date(timeIntervalSinceNow: -24 * 60 * 60)
        pickerView.maximumDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
        */
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
    
    @IBAction func handleStartTest(_ sender: Any) {
        if type == 2 {
            bleSelf.startMeasure(WristbandMeasureType.heart)
            startTestButton.setTitle("测试中...", for: .normal)
            startTestButton.isUserInteractionEnabled = false
            measureAsync = Async.main(after: 30) {
                // do something for update UI
                
            }
            startColorChangeAnimation()
        }
        if type == 4 {
            bleSelf.startMeasure(WristbandMeasureType.blood)
            startTestButton.setTitle("测试中...", for: .normal)
            startTestButton.isUserInteractionEnabled = false
            measureAsync = Async.main(after: 30) {
                // do something for update UI
            }
            startColorChangeAnimation()
        }
        
        if type == 5 {
            bleSelf.startMeasure(WristbandMeasureType.oxygen)
            startTestButton.setTitle("测试中...", for: .normal)
            startTestButton.isUserInteractionEnabled = false
            measureAsync = Async.main(after: 30) {
                // do something for update UI
            }
            startColorChangeAnimation()
        }
    }
    
    private func startColorChangeAnimation() {
        mTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(mTimer!, forMode: .common)
    }
    
    private func endColorChangeAnimation() {
        mTimer?.invalidate()
        mTimer = nil
        alpha = 0.3
        startTestButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    @objc private func handleTimer() {
        if alpha >= 1 {
            alpha = 0.3
        }
        alpha += 0.1
        startTestButton.backgroundColor = UIColor.blue.withAlphaComponent(alpha)
    }
}

extension HealthDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! HealthDetailTableViewCell
        if indexPath.row == 0 {
            cell.iconImageView.image = UIImage(named: "walk.jpeg")
            cell.titleLabel.text = "饭后散步是否有助于消化？"
        } else if indexPath.row == 1 {
            cell.iconImageView.image = UIImage(named: "apple.jpeg")
            cell.titleLabel.text = "一天一个苹果远离医生的说法…"
        } else {
            cell.iconImageView.image = UIImage(named: "water.jpg")
            cell.titleLabel.text = "起床一杯白开水有助于排毒的…"
        }
        cell.arrorImageView.image = UIImage(named: "content_icon_nextgray_normal")
        cell.selectionStyle = .none
        return cell
    }
}

extension HealthDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            openURLWithSafari(url: "https://www.baidu.com/sf?openapi=1&dspName=iphone&from_sf=1&pd=wenda_kg&resource_id=5243&word=%E9%A5%AD%E5%90%8E%E6%95%A3%E6%AD%A5%E6%9C%89%E5%8A%A9%E4%BA%8E%E6%B6%88%E5%8C%96%E5%90%97&dsp=iphone&title=%E9%A5%AD%E5%90%8E%E6%95%A3%E6%AD%A5%E6%9C%89%E5%8A%A9%E4%BA%8E%E6%B6%88%E5%8C%96%E5%90%97&aptstamp=1604826136&top=%7B%22sfhs%22%3A11%7D&alr=1&fromSite=pc&total_res_num=40&ms=1&frsrcid=5242&frorder=2&lid=15488310758445452662&pcEqid=d6f1889300008d76000000065fa7b4a7")
        } else if indexPath.row == 1 {
            openURLWithSafari(url: "https://www.baidu.com/sf?openapi=1&dspName=iphone&from_sf=1&pd=wenda_kg&resource_id=5243&word=%E4%B8%80%E5%A4%A9%E4%B8%80%E4%B8%AA%E8%8B%B9%E6%9E%9C%E5%AF%B9%E8%BA%AB%E4%BD%93%E6%9C%89%E4%BB%80%E4%B9%88%E5%A5%BD%E5%A4%84&dsp=iphone&title=%E4%B8%80%E5%A4%A9%E4%B8%80%E4%B8%AA%E8%8B%B9%E6%9E%9C%E5%AF%B9%E8%BA%AB%E4%BD%93%E6%9C%89%E4%BB%80%E4%B9%88%E5%A5%BD%E5%A4%84&aptstamp=1604826358&top=%7B%22sfhs%22%3A11%7D&alr=1&fromSite=pc&total_res_num=97&ms=1&frsrcid=5242&frorder=3&lid=10352777440170252320&pcEqid=8fac743b00069820000000065fa7b523")
        } else {
            openURLWithSafari(url: "https://www.baidu.com/sf?openapi=1&dspName=iphone&from_sf=1&pd=wenda_kg&resource_id=5243&word=%E8%B5%B7%E5%BA%8A%E4%B8%80%E6%9D%AF%E7%99%BD%E5%BC%80%E6%B0%B4%E6%9C%89%E5%8A%A9%E4%BA%8E&dsp=iphone&title=%E8%B5%B7%E5%BA%8A%E4%B8%80%E6%9D%AF%E7%99%BD%E5%BC%80%E6%B0%B4%E6%9C%89%E5%8A%A9%E4%BA%8E&aptstamp=1604828505&top=%7B%22sfhs%22%3A11%7D&alr=1&fromSite=pc&total_res_num=71&ms=1&frsrcid=5242&frorder=5&lid=9733609938258418419&pcEqid=8714baab001adaf3000000065fa7bd59")
        }
    }
}

extension HealthDetailViewController: ChartViewDelegate {
    
}

extension HealthDetailViewController: CommonCalendarViewProtocol {
    func callbackForHide(_ date: Date) {
        commonCalendarView?.isHidden = true
        mDate = date
        setData()
        let times = getTimes(date: mDate)
        dateLabel.text = changeTimeToWeek(times[6]) + "\(times[1])/\(times[2])"
    }
}

extension HealthDetailViewController {
    func changeTimeToWeek(_ value: Int) -> String {
        switch value {
        case 0:
            return "星期日"
        case 1:
            return "星期一"
        case 2:
            return "星期二"
        case 3:
            return "星期三"
        case 4:
            return "星期四"
        case 5:
            return "星期五"
        default:
            return "星期六"
        }
    }
}

extension HealthDetailViewController {
    func readDBStep() -> [DStepModel] {
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
        let times = getTimes(date: mDate)
        dateLabel.text = changeTimeToWeek(times[6]) + "\(times[1])/\(times[2])"
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


