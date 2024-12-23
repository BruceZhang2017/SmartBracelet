//
//  Utils.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/24.
//

import Foundation

class Utils {
    
    // MARK: - 获取FOT文件列表
    
    static let OTA_FILE_EXTENSION = "bin"
    
    static func fotFileList() -> [URL]? {
        if let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: documentUrl, includingPropertiesForKeys: nil)
                // Filter
                let fotUrls = files.filter { $0.pathExtension == OTA_FILE_EXTENSION }
                return fotUrls
            } catch {
                return nil
            }
        }
        return nil
    }
    
}
