//
//  TimeRecord.swift
//  AB_OTA Demo
//
//  Created by Bluetrum on 2023/7/31.
//

import Foundation

class TimeRecord {
    
    private static let dateFormat = {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "HH:mm:ss.SSS"
        return dateFormat
    }()
    
    public private(set) var startTime: Date?
    private var tempTime: Date?
    public private(set) var endTime: Date?
    public private(set) var timeInterval: TimeInterval = 0
    
    public var timeIntervalText: String {
        return formatTimeInterval(interval: timeInterval)
    }
    
    private func formatTimeInterval(interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.maximumUnitCount = 3
        
        let formattedDate = formatter.string(from: interval) ?? "00:00:00"
        let millis = UInt(timeInterval * 1000) % 1000;
        
        return String(format: "%@.%03d", formattedDate, millis)
    }
    
    public var startTimeText: String? {
        guard let startTime = startTime else { return nil }
        return TimeRecord.dateFormat.string(from: startTime)
    }
    
    public var endTimeText: String? {
        guard let endTime = endTime else { return nil }
        return TimeRecord.dateFormat.string(from: endTime)
    }
    
    public func startRecord(isNewRecord: Bool) {
        tempTime = Date()
        if isNewRecord {
            startTime = tempTime
        }
    }
    
    public func stopRecord() {
        guard let tempTime = tempTime else { return }
        
        endTime = Date()
        let diffTime = endTime!.timeIntervalSince(tempTime)
        timeInterval += diffTime
    }
}
