//
//  ViewController.swift
//  Clip
//
//  Created by anker_bruce on 2025/7/20.
//  Copyright © 2025 tjd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDownloadButton()
    }
    
    private func setupDownloadButton() {
        let downloadButton = UIButton(type: .system)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.backgroundColor = .white
        downloadButton.setTitle(NSLocalizedString("app_download", comment: "App Download"), for: .normal)
        downloadButton.setTitleColor(.black, for: .normal)
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        downloadButton.layer.cornerRadius = 22
        downloadButton.layer.masksToBounds = true
        downloadButton.addTarget(self, action: #selector(openAppStore), for: .touchUpInside)
        
        view.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            downloadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            downloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            downloadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            downloadButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "icon_uwatch")
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: downloadButton.topAnchor, constant: -100),
            imageView.widthAnchor.constraint(equalToConstant: 180),
            imageView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }
    
    @objc private func openAppStore() {
        guard let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id6444815466") else { return }
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
}

