//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SetTargetBViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/7/29.
//  Copyright © 2020 tjd. All rights reserved.
//
	
import Segmentio
import UIKit

class SetTargetBViewController: BaseViewController {
    @IBOutlet weak var segmentio: Segmentio!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var startRunButton: UIButton!
    @IBOutlet weak var targetValueLabel: UILabel!
    @IBOutlet weak var targetTitleLabel: UILabel!
    @IBOutlet weak var customButton: UIButton!
    private var selectedIndex = 0 // 当前被选择的项目
    public var target: TargetModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.kSetTarget
        
        let distance = SegmentioItem(title: "距离", image: nil)
        let cal = SegmentioItem(title: "热量", image: nil)
        let duration = SegmentioItem(title: "时长", image: nil)
        let rate = SegmentioItem(title: "配速", image: nil)
        let state = SegmentioStates(
                    defaultState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.systemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    ),
                    selectedState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.systemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    ),
                    highlightedState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.boldSystemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    )
        )
        let options = SegmentioOptions(
                    backgroundColor: .white,
                    segmentPosition: SegmentioPosition.fixed(maxVisibleItems: 4),
                    scrollEnabled: true,
                    indicatorOptions: SegmentioIndicatorOptions(type: .bottom, ratio: 0.3, height: 2, color: .k3ACF95),
                    horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(type: .none, height: 0, color: .clear),
                    verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(ratio: 0, color: .clear),
                    imageContentMode: .center,
                    labelTextAlignment: .center,
                    segmentStates: state
        )
        targetTitleLabel.isHidden = true
        segmentio.setup(
            content: [distance, cal, duration, rate],
            style: .onlyLabel,
            options: options
        )
        segmentio.selectedSegmentioIndex = 0
        segmentio.valueDidChange = {
            [weak self] segmentio, segmentIndex in
            self?.targetTitleLabel.isHidden = segmentIndex == 0
            self?.customButton.isHidden = segmentIndex != 0
            self?.selectedIndex = segmentIndex
            self?.pickerView.reloadAllComponents()
            self?.pickerView.selectRow(0, inComponent: 0, animated: false)
            
            if segmentIndex == 0 {
                let title = NSMutableAttributedString()
                title.append(NSAttributedString(string: "\(String(format: "%.2f", Float(self!.target.distance) / 1000))", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
                title.append(NSAttributedString(string: "  公里", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
                self?.targetValueLabel.attributedText = title
            } else if segmentIndex == 1 {
                let title = NSMutableAttributedString()
                title.append(NSAttributedString(string: "\(self!.target.cal)", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
                title.append(NSAttributedString(string: "  千卡", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
                self?.targetValueLabel.attributedText = title
            }  else if segmentIndex == 2 {
                let title = NSMutableAttributedString()
                let time = self!.target.time
                let h = time / 60 / 60
                let m = time % 3600 / 60
                let s = time % 60
                let t = "\(String(format: "%02d", h)):\(String(format: "%02d", m)):\(String(format: "%02d", s))"
                title.append(NSAttributedString(string: t, attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
                self?.targetValueLabel.attributedText = title
            } else if segmentIndex == 3 {
                let title = NSMutableAttributedString()
                let speed = self!.target.speed
                let chi = speed / 12
                let cun = speed % 12
                title.append(NSAttributedString(string: "\(chi)'\(String(format: "%02d", cun))\"", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
                self?.targetValueLabel.attributedText = title
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let title = NSMutableAttributedString()
        title.append(NSAttributedString(string: "\(String(format: "%.2f", Float(target.distance) / 1000))", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
        title.append(NSAttributedString(string: "  公里", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
        targetValueLabel.attributedText = title
    }
    
    @IBAction func startRun(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("SportViewController"), object: target)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func pushToCustom(_ sender: Any) {
        let storyboard = UIStoryboard(name: .kSport, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: .kSetTargetViewController) as! SetTargetViewController
        vc.target = target
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SetTargetBViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if selectedIndex == 0 {
            return distances.count
        }
        if selectedIndex == 1 {
            return heats.count
        }
        if selectedIndex == 2 {
            return times.count
        }
        return 100
    }
}

extension SetTargetBViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return ScreenWidth
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 54
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var temView: UIView!
        if view != nil {
            temView = view
        } else {
            temView = UIView()
            let label = UILabel()
            label.tag = 1
            temView.addSubview(label)
            label.snp.makeConstraints {
                $0.center.equalToSuperview()
            }
        }
        let label = temView.viewWithTag(1) as! UILabel
        let title = NSMutableAttributedString()
        if selectedIndex == 0 {
            title.append(NSAttributedString(string: "\(distances[row]).00", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
            title.append(NSAttributedString(string: "  公里", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
        }
        if selectedIndex == 1 {
            title.append(NSAttributedString(string: "\(heats[row])", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
            title.append(NSAttributedString(string: "  千卡", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
        }
        if selectedIndex == 2 {
            title.append(NSAttributedString(string: "\(times[row])", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
        }
        if selectedIndex == 3 {
            let speed = 5 * 12 + row
            let chi = speed / 12
            let cun = speed % 12
            title.append(NSAttributedString(string: "\(chi)'\(String(format: "%02d", cun))\"", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
        }
        label.attributedText = title
        return temView
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let title = NSMutableAttributedString()
        if selectedIndex == 0 {
            title.append(NSAttributedString(string: "\(distances[row]).00", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
            title.append(NSAttributedString(string: "  公里", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
            target.distance = distances[row] * 1000
        }
        if selectedIndex == 1 {
            title.append(NSAttributedString(string: "\(heats[row])", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
            title.append(NSAttributedString(string: "  千卡", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k9A9A9A]))
            target.cal = heats[row]
        }
        if selectedIndex == 2 {
            title.append(NSAttributedString(string: "\(times[row])", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
            let array = times[row].components(separatedBy: ":")
            let h = (Int(array[0]) ?? 0) * 3600
            let m = (Int(array[1]) ?? 0) * 60
            let s = (Int(array[2]) ?? 0)
            target.time = h + m + s
        }
        if selectedIndex == 3 {
            let speed = 5 * 12 + row
            let chi = speed / 12
            let cun = speed % 12
            title.append(NSAttributedString(string: "\(chi)'\(String(format: "%02d", cun))\"", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k343434]))
            target.speed = speed
        }
        targetValueLabel.attributedText = title
    }
}

extension SetTargetBViewController {
    var distances: [Int] {
        return [1,2,3,5,10,15,20,25,30,40,50,60,70,80,90,100]
    }
    var heats: [Int] {
        return [100,200,300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500]
    }
    var times: [String] {
        return ["00:10:00", "00:20:00", "00:30:00", "00:40:00", "00:50:00", "01:00:00", "01:10:00", "01:20:00", "01:30:00", "01:40:00", "01:50:00", "02:00:00"]
    }
}
