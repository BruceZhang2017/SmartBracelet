//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  SCImageReviewView.swift
//  SoundCore
//
//  Created by ANKER on 2019/10/29.
//  Copyright © 2019 team. All rights reserved.
//

import Kingfisher
import UIKit

class SCImageReviewView: SCReviewView {

    // MARK: Internal

    var cancelButton: UIButton!
    var eventButton: UIButton!

    override func initializeUI() {
        backgroundColor = .black.withAlphaComponent(0.01)

        panelView = UIView()
        
        imageView = UIImageView().then {
            let imageUrl = viewInfo.title
            if imageUrl.hasPrefix("http") {
                guard let url = URL(string: imageUrl) else {
                    return
                }
                $0.kf.setImage(with: url) { (result) in
                    switch result {
                    case .success(let value):
                        print("图片下载成功 \(value)")
                        self.isHidden = false
                    case .failure(let error):
                        print("图片下载失败 \(error)")
                    }
                }
                
            }
        }
        
        cancelButton = UIButton().then {
            $0.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        }
        eventButton = UIButton().then {
            $0.addTarget(self, action: #selector(handleEvent), for: .touchUpInside)
        }
    }
    
    override func initializeLayout() {
        panelView.do {
            addSubview($0)
            $0.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.left.equalTo(30)
                $0.right.equalTo(-30)
            }
        }
        
        cancelButton.do {
            panelView.addSubview($0)
            $0.snp.makeConstraints {
                $0.left.right.top.equalToSuperview()
                $0.height.equalTo(44)
            }
        }
        
        eventButton.do {
            panelView.addSubview($0)
            $0.snp.makeConstraints {
                $0.left.right.bottom.equalToSuperview()
                $0.top.equalTo(cancelButton.snp.bottom)
            }
        }
        
        imageView.do {
            panelView.addSubview($0)
            $0.snp.makeConstraints {
                $0.top.bottom.left.right.equalToSuperview()
                $0.height.equalTo(calculateImageHeight())
            }
        }
    }

    @objc
    func handleCancel() {
        if let closure = didClickedClosure {
            closure(0)
        }
    }
    
    @objc
    func handleEvent() {
        if let closure = didClickedClosure {
            closure(1)
        }
    }

    // MARK: Private

    /// 计算图片高度
    private func calculateImageHeight() -> CGFloat {
        let size = viewInfo.imageSize
        if size.width == 0 || size.height == 0 {
            return 200
        }
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let height = (screenWidth - 60) * size.height / size.width
        return min(screenHeight - 100, height)
    }

}
