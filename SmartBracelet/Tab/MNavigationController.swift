//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MNavigationController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/11/11.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class MNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.text_primary, // 设置颜色
            NSAttributedString.Key.font: UIFont.title() // 设置字体大小
        ]
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = textAttributes
            appearance.configureWithTransparentBackground()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.titleTextAttributes = textAttributes
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navigationController?.navigationBar.shadowImage = UIImage()
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
