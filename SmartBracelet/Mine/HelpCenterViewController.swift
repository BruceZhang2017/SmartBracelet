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
import Alamofire
import ProgressHUD

class HelpCenterViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var questionRemarkLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var response: QuestionResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_help_center".localized()
        questionRemarkLabel.text = "mine_help_center_feedback".localized()
        submitButton.setTitle("mine_help_center_submit".localized(), for: .normal)
        cancelButton.setTitle("mine_cancel".localized(), for: .normal)
        
        
        AF.request("https://u-watch.com.cn/api/app/question?title=&byCountry=\(getLocaleCountryCode())", method: .get, parameters: nil).response { [weak self] (response) in
            debugPrint("Response: \(response.debugDescription)")
            guard let data = response.value as? Data else {
                return
            }
            let model = try? JSONDecoder().decode(QuestionResponse.self, from: data)
            if model == nil {
                Toast(text: "help_center_data_parse_fail".localized()).show()
                return
            }
            if model?.total ?? 0 > 0 {
                self?.response = model
                self?.tableView.reloadData()
            }
        }
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
            Toast(text: "help_center_text_tip".localized()).show()
            return
        }
        
        ProgressHUD.show()
        let parameters = ["title": content, "content": content, "byCountry": getLocaleCountryCode()]
        AF.request("https://u-watch.com.cn/api/app/question", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).response { [weak self] (response) in
            debugPrint("Response: \(response.debugDescription)")
            ProgressHUD.dismiss()
            guard let data = response.value as? Data else {
                return
            }
            let model = try? JSONDecoder().decode(CommonResponse.self, from: data)
            if model == nil {
                Toast(text: "help_center_data_parse_fail".localized()).show()
                return
            }
            if model?.code == 0 {
                Toast(text: "help_center_submit_success".localized()).show()
                self?.navigationController?.popViewController(animated: true)
            } else {
                Toast(text: "help_center_submit_fail".localized()).show()
            }
        }
    }
    
    public func getLocaleCountryCode() -> String {
        let locale: NSLocale = NSLocale.current as NSLocale
        let country: String? = locale.countryCode
        return country ?? ""
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension HelpCenterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return response?.rows?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath)
        let label = cell.viewWithTag(1) as! UILabel
        label.text = response?.rows?[indexPath.row].title
        return cell
    }
}

extension HelpCenterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let answer = response?.rows?[indexPath.row].answer else {
            return
        }
        let webViewController = JXWebViewController()
        webViewController.webView.loadHTMLString(answer, baseURL: nil)
        navigationController?.pushViewController(webViewController, animated: true)
    }
}
