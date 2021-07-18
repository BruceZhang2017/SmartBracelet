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
    @IBOutlet weak var gradentView: UIView!
    @IBOutlet weak var goalView: UIView!
    @IBOutlet weak var dateLabel: UILabel! // 日期
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var unitBLabel: UILabel!
    @IBOutlet weak var kmLabel: UILabel!
    @IBOutlet weak var goalBLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    public var colors: [UIColor]!
    var commonCalendarView: CommonCalendarView?
    var type = 0 // 0 步数 1 热量 2 心率 3 睡眠
    var mDate: Date = Date()
    var totalValue = 0 // 总步数
    var totalKM = 0 // 总公里
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChart()
        setData()
        setupProperty()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type == 0 {
            goalLabel.text = "目标 \(bleSelf.userInfo.stepGoal)"
            goalBLabel.text = "\(bleSelf.userInfo.stepGoal)"
        }
        kmLabel.isHidden = type != 0
        if type == 0 {
            
        } else if type == 1 {
            
        } else if type == 2 {
            goalLabel.isHidden = true
        }
        unitBLabel.text = type == 0 ? "步" : "千卡"
        tipLabel.text = type == 0 ? "每日步数目标" : "每日热量目标"
        goalView.isHidden = type > 1
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
        lineChartView.xAxis.axisMaximum = Double(4)
        lineChartView.xAxis.setLabelCount(5, force: true)
        lineChartView.xAxis.gridColor = UIColor.clear
        lineChartView.xAxis.drawGridLinesEnabled = true
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.valueFormatter = DefaultAxisValueFormatter(block: { (value, axis) -> String in
            if value == 0 {
                return "00:00"
            } else if value == 1 {
                return "06:00"
            } else if value == 2 {
                return "12:00"
            } else if value == 3 {
                return "18:00"
            } else {
                return "00:00"
            }
        })
        
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
            lineChartView.rightAxis.axisMaximum = 40000
        } else if type == 2 {
            lineChartView.rightAxis.axisMaximum = 200
        } else if type == 3 {
            lineChartView.rightAxis.axisMaximum = 5
        }
        lineChartView.rightAxis.setLabelCount(6, force: true)
        lineChartView.rightAxis.gridColor = UIColor.white
        lineChartView.rightAxis.drawGridLinesEnabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.legend.form = .none
        if type == 3 {
            lineChartView.rightAxis.valueFormatter = DefaultAxisValueFormatter(block: { (value, axis) -> String in
                if value == 1 {
                    return "清醒"
                } else if value == 3 {
                    return "浅睡"
                } else if value == 5 {
                    return "深睡"
                }
                return ""
            })
        }
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
    
    private func initializeData() -> [ChartDataEntry] {
        var values: [ChartDataEntry] = []
        if type == 0 { // 步数
            totalValue = 0
            totalKM = 0
            let array = readDBStep()
            if array.count > 0 {
                values.append(ChartDataEntry(x: Double(-0.2), y: Double(0)))
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].step
                    totalValue += value
                    totalKM += array[i].distance
                    let x = Double(array[i].timeStamp - Int(zero)) / Double(3660 * 6)
                    values.append(ChartDataEntry(x: x, y: Double(value) / Double(1000)))
                }
                values.append(ChartDataEntry(x: Double(4.2), y: Double(0)))
                print("获取到数据的数量为：\(values.count)")
            }
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "\(totalValue)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
            arrStr.append(NSAttributedString(string: "步", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
            valueLabel.attributedText = arrStr
            kmLabel.text = "\(String(format: "%.2f", Float(totalKM) / Float(1000))) 公里"
        } else if type == 1 { // 热量 卡路里
            totalValue = 0
            let array = readDBStep()
            if array.count > 0 {
                values.append(ChartDataEntry(x: Double(-0.2), y: Double(0)))
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].cal // 热量
                    totalValue += value
                    let x = Double(array[i].timeStamp - Int(zero)) / Double(3660 * 6)
                    values.append(ChartDataEntry(x: x, y: Double(value) / Double(8000)))
                }
                values.append(ChartDataEntry(x: Double(4.2), y: Double(0)))
                print("获取到数据的数量为：\(values.count)")
            }
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "\(String(format: "%.2f", Float(totalValue) / Float(1000)))", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
            arrStr.append(NSAttributedString(string: "千卡", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
            valueLabel.attributedText = arrStr
        } else if type == 2 { // 心率
            var count = 0
            let array = readDBHeart()
            if array.count > 0 {
                count = array.count
                values.append(ChartDataEntry(x: Double(-0.2), y: Double(0)))
                let zero = mDate.zeroTimeStamp()
                for i in 0..<array.count {
                    let value = array[i].heartRate
                    let x = Double(array[i].timeStamp - Int(zero)) / Double(3660 * 6)
                    values.append(ChartDataEntry(x: x, y: Double(value) / Double(40)))
                }
                values.append(ChartDataEntry(x: Double(4.2), y: Double(0)))
                print("获取到数据的数量为：\(values.count)")
            }
            if count > 0 {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "\(array.last!.heartRate)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "次/分", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "次/分", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
            }
        } else if type == 3 { // 睡眠
            let array = readDBSleep()
            if array.count > 0 {
                values.append(ChartDataEntry(x: Double(-0.2), y: Double(0)))
                let zero = mDate.zeroTimeStamp()
                let sort = array.sorted{ $0.timeStamp < $1.timeStamp}
                for i in 0..<sort.count {
                    if sort[i].timeStamp < Int(zero) || sort[i].timeStamp > Int(zero + 24 * 60 * 60) {
                        continue
                    }
                    let value = sort[i].state // 1, 2, 3 清醒，浅睡，深睡
                    var y = 0
                    if value == 1 {
                        y = 1
                    } else if value == 2 {
                        y = 3
                    } else if value == 3 {
                        y = 5
                    }
                    let x = Double(sort[i].timeStamp - Int(zero)) / Double(3660 * 6)
                    values.append(ChartDataEntry(x: x, y: Double(y)))
                }
                values.append(ChartDataEntry(x: Double(4.2), y: Double(0)))
                print("获取到数据的数量为：\(values.count)")
            }
            if array.count > 0 {
                let a = array.map { item -> TJDSleepModel in
                    let model = TJDSleepModel()
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
                arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
                if arr.count == 3 {
                    let h1 = arr[2] / 60
                    let m1 = arr[2] % 60
                    let h2 = arr[1] / 60
                    let m2 = arr[1] % 60
                    let h3 = arr[0] / 60
                    let m3 = arr[0] % 60
                    goalLabel.text = "深睡\(h1)小时\(m1)分 浅睡\(h2)小时\(m2)分 清醒\(h3)小时\(m3)分"
                }
            } else {
                let arrStr = NSMutableAttributedString()
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]))
                arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white]))
                valueLabel.attributedText = arrStr
                goalLabel.text = "深睡0小时0分 浅睡0小时0分 清醒0小时0分"
            }
            
        }
        return values
    }

    private func setupProperty() {
        goalView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.3)
        gradentView.addGradientLayer(at: CGRect(x: 0, y: 0, width: ScreenWidth, height: 322), colors: colors)
        dateLabel.isUserInteractionEnabled = true
        let times = getTimes(date: mDate)
        dateLabel.text = changeTimeToWeek(times[6]) + "\(times[1])月\(times[2])日"
    }
    
    /// 选择日期
    @IBAction func chooseDate(_ sender: Any) {
        if commonCalendarView != nil {
            commonCalendarView?.isHidden = !commonCalendarView!.isHidden
            return
        }
        commonCalendarView = Bundle.main.loadNibNamed("CommonCalendarView", owner: nil, options: nil)?.first as? CommonCalendarView
        commonCalendarView?.delegate = self
        view.addSubview(commonCalendarView!)
        commonCalendarView?.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(dateLabel.snp.bottom)
            $0.bottom.equalToSuperview()
        }
    }
    
    @IBAction func pushToGoal(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Sport", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SetTargetCViewController")
        navigationController?.pushViewController(vc, animated: true)
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
        dateLabel.text = changeTimeToWeek(times[6]) + "\(times[1])月\(times[2])日"
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
        let models = try? DSleepModel.er.array("timeStamp>\(stamp - 2 * 60 * 60) AND timeStamp<\(stamp + 10 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        return models?.sorted { $0.timeStamp < $1.timeStamp } ?? []
        
    }
}
