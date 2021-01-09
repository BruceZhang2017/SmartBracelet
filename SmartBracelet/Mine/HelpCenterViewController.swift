//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  HelpCenterViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/6.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class HelpCenterViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var questionRemarkLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "帮助中心"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func submit(_ sender: Any) {
        let content = contentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.count <= 0 {
            Toast(text: "请输入内容").show()
            return
        }
        Toast(text: "提交成功").show()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension HelpCenterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath)
        let label = cell.viewWithTag(1) as! UILabel
        if indexPath.row == 0 {
            label.text = "常见问题一"
        } else if indexPath.row == 1 {
            label.text = "常见问题二"
        } else if indexPath.row == 2 {
            label.text = "常见问题三"
        } else if indexPath.row == 3 {
            label.text = "常见问题四"
        }
        return cell
    }
}

extension HelpCenterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openURLWithSafari(url: "\(UrlPrefix)questions.html")
    }
}
