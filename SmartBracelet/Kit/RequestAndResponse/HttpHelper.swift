//
//  HttpHelper.swift
//  TJDWristbandSDKDemo
//
//  Created by apple on 2021/4/9.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

typealias successBlock = (Any) -> ()
typealias failureBlock = (Error) -> ()
typealias progressBlock = (Progress) -> ()

let kTimeOutDuration = 10.0

class HttpHelper: NSObject {
    static let shared = HttpHelper()
    
//    func dialList(_ model: WUBleModel, success: @escaping successBlock, failure:@escaping failureBlock) {
//        wuPrint(#function, wuClassName())
////        dump(model)
////        model.internalNumberASCII = "4D313602"
////        model.vendorNumberASCII = "544A4450"
//        var devSCode = "123456"
//        if model.screenType > 0 {
//            devSCode = "type" + model.screenType.description.addHorizontalline() + "dpi" + model.screenWidth.description + "x" + model.screenHeight.description.addHorizontalline()
//            devSCode = devSCode + "size" + model.maxSize.description
//        }
//        let parameters = ["devType":model.internalNumberASCII, "HVer":model.hardwareVersion, "Vendor":model.vendorNumberASCII, "SVer":model.firmwareVersion, "OpName":"TypeList", "devSCode":devSCode]  as [String : Any]
//        let url = baseUrl + "/api/dialpush/0.1/brlt/dat/list/json"
//        wuPrint(parameters)
//        postWith(url: url, parameters: parameters, success: success, failure: failure)
//    }
    
    func postWith(url:String, parameters: [String: Any]?, success:@escaping successBlock, failure:@escaping failureBlock) {
        let manager = AFHTTPSessionManager()
        manager.requestSerializer.timeoutInterval = kTimeOutDuration
        manager.responseSerializer.acceptableContentTypes = ["text/html", "text/plain", "text/json", "application/json", "application/octet-stream", "text/javascript"]
        manager.post(url, parameters: parameters, headers: nil, progress: nil, success: { (_, result:Any?) in
            if let value = result {
                success(value)
            }
        }) { (_, error: Error) in
            print(error)
            failure(error)
        }
    }
    
    func getWith(url:String, parameters:[String: Any]?, success:@escaping successBlock, failure: @escaping failureBlock, progess: @escaping progressBlock) {
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.requestSerializer.timeoutInterval = kTimeOutDuration
        manager.responseSerializer.acceptableContentTypes = ["text/html", "text/plain", "text/json", "application/json", "application/octet-stream", "text/javascript"]
        manager.get(url, parameters: parameters, headers: nil, progress: { (value) in
        }, success: { (_, result:Any?) in
            if let value = result {
                success(value)
            }
        }) { (_, error: Error) in
            print(error)
            failure(error)
        }
    }
    
}
