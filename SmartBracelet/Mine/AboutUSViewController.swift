//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AboutUSViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import WatchProtocolSDK

class AboutUSViewController: BaseViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var appnameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_about".localized()
        // Do any additional setup after loading the view.
        var localVersion = ""
        if let v:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            localVersion = v
        }
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        versionLabel.text = "v\(localVersion)  \("mine_version".localized()) - build\(build)"
        ownerLabel.text = "＠ VPI6  \("mine_about_desc".localized())"
        ownerLabel.textColor = UIColor.text_third
        ownerLabel.font = UIFont.body2()
        appnameLabel.textColor = UIColor.text_primary
        appnameLabel.font = UIFont.title()
        versionLabel.textColor = UIColor.text_third
        versionLabel.font = UIFont.body2()
        addPrivacyPolicyLabel()
        addCheckUpdateButton()
    }

    private func addPrivacyPolicyLabel() {
        let pp = "privacy_protection".localized()
        let up = "user_agreement".localized()

        let Txt:UITextView = UITextView(frame:CGRect(x: 0, y: 0, width: 100, height: 50))
        Txt.font = UIFont.body1()
        Txt.textAlignment = .center
        Txt.backgroundColor = UIColor.clear
        Txt.isEditable = false
        Txt.dataDetectorTypes = UIDataDetectorTypes.link
        Txt.textColor = UIColor.brand
        let attributedString = NSMutableAttributedString(string:"\(pp) | \(up)")
        attributedString.SetAsLink(textToFind: pp, linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=185#")
        attributedString.SetAsLink(textToFind: up, linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=188")
        attributedString.addAttribute(.font, value: UIFont.body1(), range:  NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: UIColor.brand, range: NSMakeRange(0, attributedString.length))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: NSMakeRange(0, attributedString.length))
        Txt.attributedText = attributedString
        view.addSubview(Txt)

        Txt.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalTo(ownerLabel.snp.top).offset(0)
            $0.height.equalTo(50)
        }
    }

    private func addCheckUpdateButton() {
        let checkUpdateButton = UIButton(type: .system)
        checkUpdateButton.setTitle(NSLocalizedString("Check for Updates", comment: "Title for the check update button"), for: .normal)
        checkUpdateButton.addTarget(self, action: #selector(checkForUpdates), for: .touchUpInside)
        view.addSubview(checkUpdateButton)

        checkUpdateButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(versionLabel.snp.bottom).offset(30)
        }
    }

    @objc private func checkForUpdates() {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(Bundle.main.bundleIdentifier!)") else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String {
                    DispatchQueue.main.async {
                        self.compareVersions(appStoreVersion: appStoreVersion)
                    }
                }
            } catch {
                XLogger.shared.log("Error parsing JSON: \(error)")
            }
        }
        task.resume()
    }

    private func compareVersions(appStoreVersion: String) {
        if let localVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            if localVersion != appStoreVersion {
                let alert = UIAlertController(
                    title: NSLocalizedString("Update Available", comment: "Title for update available alert"),
                    message: String(format: NSLocalizedString("A new version (%@) is available on the App Store.", comment: "Message for update available alert"), appStoreVersion),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("Update", comment: "Update button title"), style: .default, handler: { _ in
                    if let url = URL(string: "https://apps.apple.com/app/6444815466") {
                        UIApplication.shared.open(url)
                    }
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(
                    title: NSLocalizedString("No Update Available", comment: "Title for no update available alert"),
                    message: NSLocalizedString("You are using the latest version.", comment: "Message for no update available alert"),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button title"), style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
}
