//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UserManager.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/19.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class UserManager: NSObject {
    static let sharedInstall = UserManager()
    public var user: UserModel?
    
    override init() {
        super.init()
        user = UserModel.read()
    }
    
    func saveUser() {
        user?.save()
    }
    
    func deleteUser() {
        user?.delete()
        user = nil 
    }
}
