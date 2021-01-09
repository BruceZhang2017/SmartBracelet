//
//  OSSRootViewController.swift
//  OSSSwiftDemo
//
//  Created by huaixu on 2018/1/2.
//  Copyright © 2018年 aliyun. All rights reserved.
//

import Foundation

class OSS: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    static let sharedInstance = OSS()
    var mProvider: OSSAuthCredentialProvider!
    var mClient: OSSClient!
    
    func setupOSSClient() {
        mProvider = OSSAuthCredentialProvider(authServerUrl: OSS_STSTOKEN_URL)
        mClient = OSSClient(endpoint: OSS_ENDPOINT, credentialProvider: mProvider)
    }
    
    func getObject(key: String, callback: @escaping (Data?) -> ()) {
        let getObjectReq: OSSGetObjectRequest = OSSGetObjectRequest()
        getObjectReq.bucketName = "bracelet-user-head-images"
        getObjectReq.objectKey = key
        getObjectReq.downloadProgress = { (bytesWritten: Int64,totalBytesWritten : Int64, totalBytesExpectedToWrite: Int64) -> Void in
            print("bytesWritten:\(bytesWritten),totalBytesWritten:\(totalBytesWritten),totalBytesExpectedToWrite:\(totalBytesExpectedToWrite)");
        }
        let task: OSSTask = mClient.getObject(getObjectReq)
        task.continue({(task) -> OSSTask<AnyObject>? in
            if (task.error != nil) {
                callback(nil)
            } else {
                let result = task.result
                callback(result?.downloadedData)
            }
            return nil
        })
        task.waitUntilFinished()
    }

    func getImage(name: String) {
        let getObjectReq: OSSGetObjectRequest = OSSGetObjectRequest()
        getObjectReq.bucketName = "bracelet-user-head-images";
        getObjectReq.objectKey = name
        getObjectReq.xOssProcess = "image/resize,m_lfit,w_100,h_100";
        getObjectReq.downloadProgress = { (bytesWritten: Int64,totalBytesWritten : Int64, totalBytesExpectedToWrite: Int64) -> Void in
            print("bytesWritten:\(bytesWritten),totalBytesWritten:\(totalBytesWritten),totalBytesExpectedToWrite:\(totalBytesExpectedToWrite)");
        };
        let task: OSSTask = mClient.getObject(getObjectReq)
        task.continue({(t) -> OSSTask<AnyObject>? in
            self.showResult(task: t)
            return nil
        })
        task.waitUntilFinished()
        
        print("Error:\(String(describing: task.error))")
    }
    
    
    func showResult(task: OSSTask<AnyObject>?) -> Void {
        if (task?.error != nil) {
            let error: NSError = (task?.error)! as NSError
            print(error.description)
        } else {
            let result = task?.result
            print(result?.description ?? "")
        }
    }
    
    func putObject(image: UIImage, key: String, callback: @escaping (Bool) -> ()) {
        let request = OSSPutObjectRequest()
        request.uploadingData = image.pngData()!
        request.bucketName = "bracelet-user-head-images"
        request.objectKey = key
        request.uploadProgress = { (bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            print("bytesSent:\(bytesSent),totalBytesSent:\(totalBytesSent),totalBytesExpectedToSend:\(totalBytesExpectedToSend)");
        };
        let task = mClient.putObject(request)
        task.continue({ (task) -> Any? in
            if task.error != nil {
                callback(false)
            } else {
                callback(true)
            }
            return nil 
        }).waitUntilFinished()
    }
}

