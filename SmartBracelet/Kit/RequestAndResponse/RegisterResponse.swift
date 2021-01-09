//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  RegisterResponse.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/11/10.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import Foundation

struct RegisterResponse: Codable {
    var err_code: Int?
    var message: String?
    var id: Int?
}
