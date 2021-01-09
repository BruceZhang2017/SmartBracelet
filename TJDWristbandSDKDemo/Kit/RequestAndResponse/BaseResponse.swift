//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BaseResponse.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/11/14.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import Foundation

struct BaseResponse: Codable {
    var err_code: Int?
    var message: String?
}
