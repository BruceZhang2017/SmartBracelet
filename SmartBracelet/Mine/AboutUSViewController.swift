//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AboutUSViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class AboutUSViewController: BaseViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_about".localized()
        // Do any additional setup after loading the view.
        versionLabel.text = "v1.0.0  \("mine_version".localized())"
        ownerLabel.text = "＠ VPI6  \("mine_about_desc".localized())"
        
        addPrivacyPolicyLabel()
    }
    
    private func addPrivacyPolicyLabel() {
        let Txt:UITextView = UITextView(frame:CGRect(x: 0, y: 0, width: 100, height: 50))
        Txt.font = UIFont.systemFont(ofSize: 20)
        Txt.textAlignment = .center
        Txt.backgroundColor = UIColor.clear
        Txt.isEditable = false
        Txt.dataDetectorTypes = UIDataDetectorTypes.link
        let attributedString = NSMutableAttributedString(string:"《隐私保护》 《用户协议》")
        attributedString.SetAsLink(textToFind: "《隐私保护》", linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=185#")
        attributedString.SetAsLink(textToFind: "《用户协议》", linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=188")
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20), range:  NSMakeRange(0, attributedString.length))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: NSMakeRange(0, attributedString.length))
        Txt.attributedText = attributedString
        view.addSubview(Txt)
        
        Txt.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalTo(ownerLabel.snp.top).offset(-30)
            $0.height.equalTo(50)
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

}
