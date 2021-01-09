//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  FileCache.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/11/14.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import Foundation

class FileCache: NSObject {
    func saveData(_ value: Data, name: String) {
        let path = NSString(string: filePath())
        let filePath = path.appendingPathComponent(name)
        NSKeyedArchiver.archiveRootObject(value, toFile: filePath)
    }
    
    func readData(name: String) -> Data {
        let path = NSString(string: filePath())
        let filePath = path.appendingPathComponent(name)
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! Data
        return data
    }
    
    func filePath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return path
    }
    
    func fileIfExist(name: String) -> Bool {
        let path = NSString(string: filePath())
        let filePath = path.appendingPathComponent(name)
        let manager = FileManager()
        return manager.fileExists(atPath: filePath)
    }
}
