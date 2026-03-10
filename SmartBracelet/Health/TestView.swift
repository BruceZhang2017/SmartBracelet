//
//  TestView.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class TestView: UIView {
    private var breathAnimationView: SCBreathAnimationView?
    let startTestButton = UIButton(type: .custom)
    weak var delegate: TestViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    public func setupView() {
        addSearchView()
        
        startTestButton.setTitleColor(UIColor.white, for: .normal)
        startTestButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .black)
        startTestButton.addTarget(self, action: #selector(handleStartTest), for: .touchUpInside)
        breathAnimationView?.addSubview(startTestButton)
        startTestButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        startTestButton.setTitle("health_start_test".localized(), for: .normal)
    }
    
    /// 添加搜索视图
    private func addSearchView() {
        breathAnimationView = SCBreathAnimationView.viewFromNIB()
        breathAnimationView?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(breathAnimationView!)
        
        breathAnimationView?.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(160)
        }
    }
    
    @objc func handleStartTest() {
        delegate?.handleStartTest()
    }
    
    public func testing() {
        startTestButton.setTitle("health_testing".localized(), for: .normal)
        startTestButton.isUserInteractionEnabled = false
        breathAnimationView?.startAnimation()
    }
    
    public func stop() {
        startTestButton.setTitle("health_start_test".localized(), for: .normal)
        startTestButton.isUserInteractionEnabled = true
        breathAnimationView?.stopAnimation()
    }
}

// 自定义UIView的协议
protocol TestViewDelegate: AnyObject {
    func handleStartTest()
}
