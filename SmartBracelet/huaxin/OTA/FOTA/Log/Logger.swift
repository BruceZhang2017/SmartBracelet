//
//  Logger.swift
//  AB_FOTA
//
//  Created by Bluetrum on 2023/7/12.
//

import Foundation
import os.log

public class Logger {
    
    public static var logger: LoggerDelegate?
    public static var logLevel: OSLogType = .default
    
    public static func log(message: String, ofCategory category: String, withType type: OSLogType) {
        guard type >= logLevel else { return }
        guard let logger = logger else { return }
        
        logger.log(message: message, ofCategory: category, withType: type)
    }
    
    public static func d(_ category: String, _ message: String) {
        log(message: message, ofCategory: category, withType: .debug)
    }
    
    public static func d(_ categoryClass: Any, _ message: String) {
        log(message: message, ofCategory: String(describing: type(of: categoryClass)), withType: .debug)
    }
    
    public static func i(_ categoryClass: Any, _ message: String) {
        log(message: message, ofCategory: String(describing: type(of: categoryClass)), withType: .info)
    }
    
    public static func i(_ category: String, _ message: String) {
        log(message: message, ofCategory: category, withType: .info)
    }
    
    public static func n(_ category: String, _ message: String) {
        log(message: message, ofCategory: category, withType: .default)
    }
    
    public static func n(_ categoryClass: Any, _ message: String) {
        log(message: message, ofCategory: String(describing: type(of: categoryClass)), withType: .default)
    }
    
    public static func e(_ category: String, _ message: String) {
        log(message: message, ofCategory: category, withType: .error)
    }
    
    public static func e(_ categoryClass: Any, _ message: String) {
        log(message: message, ofCategory: String(describing: type(of: categoryClass)), withType: .error)
    }
    
    public static func e(_ category: String, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: category, withType: .error)
    }
    
    public static func e(_ categoryClass: Any, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: String(describing: type(of: categoryClass)), withType: .error)
    }
    
    public static func f(_ category: String, _ message: String) {
        log(message: message, ofCategory: category, withType: .fault)
    }
    
    public static func f(_ categoryClass: Any, _ message: String) {
        log(message: message, ofCategory: String(describing: type(of: categoryClass)), withType: .fault)
    }
    
    public static func f(_ category: String, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: category, withType: .fault)
    }
    
    public static func f(_ categoryClass: Any, _ error: Error) {
        log(message: error.localizedDescription, ofCategory: String(describing: type(of: categoryClass)), withType: .fault)
    }
}

fileprivate extension OSLogType {
    var logLevel: Int {
        switch self {
        case .debug:    return 2
        case .info:     return 3
        case .default:  return 4
        case .error:    return 5
        case .fault:    return 6
        default:        return 4 // never happen
        }
    }
}

fileprivate extension OSLogType {
    
    static func < (lhs: OSLogType, rhs: OSLogType) -> Bool {
        return lhs.logLevel < rhs.logLevel
    }
    
    static func <= (lhs: OSLogType, rhs: OSLogType) -> Bool {
        return lhs.logLevel <= rhs.logLevel
    }
    
    static func >= (lhs: OSLogType, rhs: OSLogType) -> Bool {
        return lhs.logLevel >= rhs.logLevel
    }
    
    static func > (lhs: OSLogType, rhs: OSLogType) -> Bool {
        return lhs.logLevel > rhs.logLevel
    }
}
