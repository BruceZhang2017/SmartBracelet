//
//  RecentCityTableViewCell.swift
//  SoolyWeather
//
//  Created by SoolyChristina on 2017/3/10.
//  Copyright © 2017年 SoolyChristina. All rights reserved.
//

import UIKit

class RecentCitiesTableViewCell: UITableViewCell {
    
    // 使用tableView.dequeueReusableCell会自动调用这个方法
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let btn = UIButton(frame: CGRect(x: 15, y: 15, width: (ScreenWidth - 90) / 3, height: 36))
        btn.setTitle("北京", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.backgroundColor = UIColor.white
        btn.layer.cornerRadius = 1
        btn .addTarget(self, action: #selector(btnClick(btn:)), for: .touchUpInside)
        self.addSubview(btn)

    }
    
    @objc private func btnClick(btn: UIButton) {
        print(btn.titleLabel?.text!)
    }



}
