//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  GradeViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/15.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit

class GradeViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    var preColor: UIColor!
    @IBOutlet weak var starLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var progressImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerView.bounds = CGRect(x: 0, y: 0, width: ScreenWidth, height: 216)
        headerView.addVGradientLayer(at: CGRect(x: 0, y: 0, width: ScreenWidth, height: 216), colors: [UIColor.k64F2B4, UIColor.k08CCCC])
        automaticallyAdjustsScrollViewInsets = false
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 44)).then {
            $0.textColor = UIColor.white
            $0.font = UIFont.systemFont(ofSize: 18)
            $0.text = "等级"
            $0.textAlignment = .center
        }
        navigationItem.titleView = label
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 65))
        path.addLine(to: CGPoint(x: ScreenWidth / 2, y: 115))
        path.addLine(to: CGPoint(x: ScreenWidth, y: 65))
        path.addLine(to: CGPoint(x: ScreenWidth, y: 216))
        path.addLine(to: CGPoint(x: 0, y: 216))
        path.close()
        let mLayer = CAShapeLayer()
        mLayer.path = path.cgPath
        mLayer.fillColor = UIColor.white.cgColor
        mLayer.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: 216)
        headerView.layer.insertSublayer(mLayer, at: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preColor = navigationController?.navigationBar.tintColor
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = preColor
        navigationController?.navigationBar.isTranslucent = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GradeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! GradeTableViewCell
        cell.selectionStyle = .none
        return cell
    }
}

extension GradeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
