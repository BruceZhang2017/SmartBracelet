//
//  DetailViewController.swift
//  TJDWacthSDKDemo
//
//  Created by tjd on 2019/2/21.
//  Copyright © 2019年 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var table = UITableView()
    var sleepArray = [TJDSleepModel]()
    var textView = UITextView()
    
    var measureAsync: Async?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupNotify()
        
        self.view.backgroundColor = UIColor.white
        table.frame = CGRect.init(x: 0, y: 264, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 264)
        table.delegate = self
        table.dataSource = self
        view.addSubview(table)
        
        textView.frame = CGRect.init(x: 0, y: 64, width: UIScreen.main.bounds.width, height: 200)
        textView.backgroundColor = UIColor.red
        textView.textColor = UIColor.white
        textView.isEditable = false
        view.addSubview(textView)
        
        let rightBar = UIBarButtonItem.init(title: "清空", style: .done, target: self, action: #selector(pressRight(_:)))
        self.navigationItem.rightBarButtonItem = rightBar
        self.navigationItem.leftBarButtonItem?.title = "返回"
        self.navigationItem.title = bleSelf.bleModel.mac
    }
    
    @objc func pressLeft(_ sender: UIBarButtonItem) {

    }
    
    @objc func pressRight(_ sender: UIBarButtonItem) {
        self.textView.text = ""
    }
    
    func setupNotify() {
        
    }
    


    
    // MARK: - TableView
    private let titleArray = ["当前记步数据 current step","详细记步数据 detail step","详细睡眠数据 detail sleep","心率数据 heart history","血压数据 blood history"]
    private let titleArray1 = ["开始测量心率 start heart measure","开始测量血压 start blood measure","进入相机 enter camera","退出相机 exit camera","查找手环 find wristband","查找手机回复","开关功能","设置开关功能","久坐提醒","设置久坐提醒"]
    private let titleArray2 = ["发送时间 send time","发送语言 language","设备信息 wristband info"]
    private let titleArray3 = ["获取用户信息 get userinfo","设置用户信息 set userinfo","设置公英制和12小时制"]
    private let titleArray4 = ["功耗切换获取","功耗切换设置","获取短信中心号码","设置短信中心号码","GPS Total","GPS Info","GPS Detail","开始测量体温","获取体温","获取睡眠设置","设置睡眠设置","设置天气","获取E_sim（第一次获取时间比较长，请UI设置等待）"]
    func numberOfSections(in tableView: UITableView) -> Int {
        #if WeiZhongYun
        return 5
        #endif
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return titleArray.count
        }
        if section == 1 {
            return titleArray1.count
        }
        if section == 2 {
            return titleArray2.count
        }
        if section == 3 {
            return titleArray3.count
        }
        if section == 4 {
            return titleArray4.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description()) ?? UITableViewCell.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: UITableViewCell.description())
        if indexPath.section == 0 {
            cell.textLabel?.text = titleArray[indexPath.row]
        }
        if indexPath.section == 1 {
            cell.textLabel?.text = titleArray1[indexPath.row]
        }
        if indexPath.section == 2 {
            cell.textLabel?.text = titleArray2[indexPath.row]
        }
        if indexPath.section == 3 {
            cell.textLabel?.text = titleArray3[indexPath.row]
        }
        if indexPath.section == 4 {
            cell.textLabel?.text = titleArray4[indexPath.row]
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "数据同步"
        }
        
        if section == 1 {
            return "设备功能"
        }
        
        if section == 2 {
            return "设备信息"
        }
        
        if section == 3 {
            return "用户信息"
        }
        
        if section == 4 {
            return "为众云协议"
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                for i in 0..<7 {
                    bleSelf.aloneGetStep(with: i)
                }
            }
            
            if indexPath.row == 1 {
                bleSelf.aloneGetStep(with: 0)
            }
            
            if indexPath.row == 2 {
                bleSelf.aloneGetSleep(with: 0)
            }
            
            if indexPath.row == 3 {
                bleSelf.aloneGetMeasure(WristbandMeasureType.heart)
            }
            
            if indexPath.row == 4 {
                bleSelf.aloneGetMeasure(WristbandMeasureType.blood)
            }
        }
        
        //MARK: section == 1
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                // Measurement ends automatically, with a maximum measurement time of 45 seconds
                bleSelf.startMeasure(WristbandMeasureType.heart)
                measureAsync = Async.main(after: 45) {
                    // do something for update UI
                }
            }
            
            if indexPath.row == 1 {
                // Measurement ends automatically, with a maximum measurement time of 45 seconds
                bleSelf.startMeasure(WristbandMeasureType.blood)
                measureAsync = Async.main(after: 45) {
                    // do something for update UI
                }
            }
            
            
            if indexPath.row == 2 {
                bleSelf.setCameraForWristband(true)
            }
            
            if indexPath.row == 3 {
                bleSelf.setCameraForWristband(false)
            }
            
            if indexPath.row == 4 {
                bleSelf.findDeviceForWristband()
            }
            
            if indexPath.row == 5 {
//                bleSelf.respondsForSearchDevice()
            }
            
            if indexPath.row == 6 {
                bleSelf.getSwitchForWristband()
            }
            
            if indexPath.row == 7 {
                bleSelf.functionSwitchModel.isLongSit = true
                bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
            }
            
            if indexPath.row == 8 {
                bleSelf.getLongSitForWristband()
            }
            
            if indexPath.row == 9 {
                bleSelf.longSitModel.interval = 2
                bleSelf.setLongSitForWristband(bleSelf.longSitModel)
            }
        }
        
        //MARK: section == 2
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                bleSelf.setTimeForWristband()
            }
            
            if indexPath.row == 1 {
                bleSelf.setLanguageForWristband()
            }
            
            if indexPath.row == 2 {
                bleSelf.getDeviceInfoForWristband()
            }
            
        }
        
        //MARK: section == 3
        if indexPath.section == 3 {
            if indexPath.row == 0 {
                bleSelf.getUserinfoForWristband()
            }
            
            if indexPath.row == 1 {
                bleSelf.userInfo.height = 180
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
            }
//
            if indexPath.row == 2 {
                bleSelf.userInfo.timeUnit = 1
                bleSelf.setZhiShiForWristband(bleSelf.userInfo)
            }
        }
        
        #if WeiZhongYun_
        //MARK: section == 4
        if indexPath.section == 4 {
            if indexPath.row == 0 {
                bleSelf.getPowerSwitch()
            }
            
            if indexPath.row == 1 {
                bleSelf.setPowerSwitch(.high)
            }
            //
            if indexPath.row == 2 {
                bleSelf.getTelephoneSMS()
            }
            if indexPath.row == 3 {
                bleSelf.setTelephoneSMS("18820943008")
            }
            
            if indexPath.row == 4 {
                bleSelf.getGPSTotal(.all)
            }
            
            if indexPath.row == 5 {
                bleSelf.getGPSInfo(.all)
            }
            
            if indexPath.row == 6 {
                
            }
            
            if indexPath.row == 7 {
                bleSelf.startBodyTemperature()
            }
            
            if indexPath.row == 8 {
                bleSelf.getBodyTemperature()
            }
            
            if indexPath.row == 9 {
                bleSelf.getSleepSetting()
            }
            
            if indexPath.row == 10 {
                bleSelf.setSleepSetting(bleSelf.sleepSettingModel)
            }
            
            if indexPath.row == 11 {
                let model = WeatherModel()
                model.type = Int.random(in: 1..<8)
                model.avg_t = Int.random(in: 15...20)
                model.curr_t = Int.random(in: 15...20)
                model.max_t = Int.random(in: 20...25)
                model.min_t = Int.random(in: 10...15)
                model.cityName = ["深圳", "北京", "武汉", "上海"][Int.random(in: 0..<4)]
                bleSelf.setWeather(model)
            }
            
            if indexPath.row == 12 {
                bleSelf.getEsimCard()
            }
        }
        #endif
        //MARK: End
    }
    

    func didSetWristband(userinfo isSuccess: Bool) {
        print("delegate 执行了")
        if isSuccess {
            print("set userinfo successfully")
        }
    }
    
    func didSetWristband(camera isSuccess: Bool, isEnter: Bool) {
        //        if isSuccess {
        //            if isEnter {
        //                print("camera enter successfully")
        //            }
        //            else {
        //                print("camera exit successfully")
        //            }
        //        }
        print("delegate 执行了")
        print(#function, "isSuccess", isSuccess, "isEnter", isEnter)
    }
}
