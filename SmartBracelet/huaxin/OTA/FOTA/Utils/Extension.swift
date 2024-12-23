//
//  Extension.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/24.
//

import UIKit
import CommonCrypto

extension Data {
    func md5() ->Data {
        let length = Int(CommonCrypto.CC_MD5_DIGEST_LENGTH)
        let messageData = self
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                   let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CommonCrypto.CC_LONG(messageData.count)
                    CommonCrypto.CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
}

extension FixedWidthInteger {

    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: self))
    }

}

extension Data {
    
    /// Hex string to Data representation
    /// Inspired by https://stackoverflow.com/questions/26501276/converting-hex-string-to-nsdata-in-swift
    init?(hex: String) {
        guard hex.count % 2 == 0 else {
            return nil
        }
        let len = hex.count / 2
        var data = Data(capacity: len)
        
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    /// Hexadecimal string representation of `Data` object.
    var hex: String {
        return map { String(format: "%02X", $0) }.joined()
    }
    
}

// 同步调用
func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

extension String {
    func appendingPathComponent(path: String) -> String {
        let nsStr = self as NSString
        return nsStr.appendingPathComponent(path)
    }
}

extension UIViewController {
    
    func presentAlert(title: String?, message: String?, cancelable: Bool = false,
                      option action: UIAlertAction? = nil,
                      handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancelable ? "Cancel" : "OK", style: .cancel, handler: handler))
            if let action = action {
                alert.addAction(action)
            }
            self.present(alert, animated: true)
        }
    }
    
}

