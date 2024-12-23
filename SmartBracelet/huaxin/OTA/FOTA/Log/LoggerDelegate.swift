//
//  LoggerDelegate.swift
//  Project
//
//  Created by Bluetrum on 2020/12/28.
//

import Foundation
import os.log

public protocol LoggerDelegate {
    func log(message: String, ofCategory category: String, withType type: OSLogType)
}
