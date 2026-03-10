//
//  HNavigationController.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/14.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

class HNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white, // 设置颜色
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
