//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceSearchViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/19.
//  Copyright © 2020 tjd. All rights reserved.
//
	
import UIKit

class DeviceSearchViewController: BaseViewController {
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var scanCodeTipLabel: UILabel!
    @IBOutlet weak var scanLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var btScanTipLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    var dotLoadingView: DotsLoadingView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dotLoadingView = DotsLoadingView(colors: nil)
        loadingView.addSubview(dotLoadingView)
        dotLoadingView.show()
        tableView.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DeviceSearchViewController"), object: nil)
        BLEManager.shared.startScan()
    }
    
    deinit {
        dotLoadingView.stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "scan" {
            tableView.isHidden = bleSelf.bleModels.count == 0
            tableView.reloadData()
        }
        if objc == "connected" {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension DeviceSearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bleSelf.bleModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSearchTableViewCell
        cell.deviceNameLabel.text = bleSelf.bleModels[indexPath.row].name + ""
        cell.deviceMacLabel.text = bleSelf.bleModels[indexPath.row].mac
        cell.deviceImageView.image = UIImage(named: "produce_image_no.2")
        return cell
    }
}

extension DeviceSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        bleSelf.connectBleDevice(model: bleSelf.bleModels[indexPath.row])
    }
}
