//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UserModel.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/9/19.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class UserModel: NSObject, Codable {
    var id: Int = 0
    var username: String?
    var token: String?
    var headUrl: String?
    var country: String?
    var sex: Int = 0 // 0: 男，1:女
    var nickname: String?
    var birthday: String?
    var height: Int = 0
    var weight: Int = 0
    var area: String?
    var mobile: String?
    var email: String?
    
    public func save() {
        let data = try? JSONEncoder().encode(self)
        try? data?.write(to: URL(fileURLWithPath: UserModel.filepath()), options: .atomic)
    }
    
    public static func read() -> UserModel? {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: UserModel.filepath())) {
            return try? JSONDecoder().decode(UserModel.self, from: data)
        }
        return nil
    }
    
    private static func filepath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        return path?.appending("/user.data") ?? ""
    }
    
    public func delete() {
        let manager = FileManager.default
        let path = UserModel.filepath()
        if manager.fileExists(atPath: path) {
            try? manager.removeItem(atPath: path)
        }
    }
}
