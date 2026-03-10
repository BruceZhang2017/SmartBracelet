//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  HelpCenterViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/10/6.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import Alamofire
import ProgressHUD
import WatchProtocolSDK

class HelpCenterViewController: BaseViewController {
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_help_center".localized()
        submitButton.setTitle("mine_help_center_submit".localized(), for: .normal)
        submitButton.layer.cornerRadius = 22
        submitButton.clipsToBounds = true
        submitButton.backgroundColor = UIColor.brand
        
        contentTextView.layer.cornerRadius = 12
        contentTextView.clipsToBounds = true
        contentTextView.placeholder = "mine_help_center_feedback".localized()
        
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
        var localVersion = ""
        if let v:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            localVersion = v
        }
        ProgressHUD.animate(nil, .activityIndicator, interaction: false)
        let parameters = ["title": "iOS-\(localVersion)", "content": "\(content)---\(XGZTDeviceManager.shared.connectFailMessage)" , "byCountry": getLocaleCountryCode()]
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
            XGZTDeviceManager.shared.clearFailMessages()
        }
    }
    
    public func getLocaleCountryCode() -> String {
        let locale: NSLocale = NSLocale.current as NSLocale
        let country: String? = locale.countryCode
        return country ?? ""
    }
}
