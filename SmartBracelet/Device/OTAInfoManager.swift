//
//  OTAInfoManager.swift
//  SmartBracelet
//
//  Created by bruce on 2024/12/18.
//  Copyright © 2024 tjd. All rights reserved.
//


import Foundation
import Alamofire

struct OTAInfoResponse: Codable {
    let total: Int
    let rows: [OTARow]
    let code: Int
    let msg: String?
}

struct OTARow: Codable {
    let searchValue: String?
    let createBy: String?
    let createTime: String?
    let updateBy: String?
    let updateTime: String?
    let remark: String?
    let params: [String: String]
    let id: Int
    let otaModel: String
    let firmId: Int
    let firmName: String
    let otaVersion: String
    let resolutionRatio: String
    let appVersion: String
    let otaUrl: String
    let isPublish: String
    let mobileType: String
    let gmtCreate: String
    let gmtUpate: String
}

class OTAInfoManager {
    static let shared = OTAInfoManager()

    private init() {}

    func fetchOTAInfo(completion: @escaping (OTAInfoResponse?) -> Void) {
        let url = "https://u-watch.com.cn/api/app/ota/v2/list?pageSize=100&pageNum=1"
        let parameters: [String: String] = [
            "pageSize": "100",
            "pageNum": "1",
            "otaModel": "u-watch",
            "moreEqOtaVersion": "\(XGZTBlueToothManager.shared.device?.firmwareVersion ?? "0.1")",
            "isPublish": "Y"
        ]

        AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                if let data = value.data(using: .utf8) {
                    multipartFormData.append(data, withName: key)
                }
            }
        }, to: url, method: .post).response { response in
            debugPrint("Request: \((String(data: response.request?.httpBody ?? Data(), encoding: .utf8) ?? "")) Response: \(response.debugDescription)")
            guard let data = response.data else {
                completion(nil)
                return
            }
            XLogger.shared.log("返回的数据：\(data)")
            let model = try? JSONDecoder().decode(OTAInfoResponse.self, from: data)
            completion(model)
        }
    }

    func downloadOTAFile(from url: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("otaFile.bin")

            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download(url, to: destination).response { response in
            if response.error == nil, let filePath = response.fileURL {
                completion(.success(filePath))
            } else {
                completion(.failure(response.error!))
            }
        }
    }

    func readSavedOTAFile() -> Data? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("otaFile.bin")

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            XLogger.shared.log("Error reading saved OTA file: \(error)")
            return nil
        }
    }
}
