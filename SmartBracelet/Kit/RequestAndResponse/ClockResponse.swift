//
//  ClockResponse.swift
//  SmartBracelet
//
//  Created by anker on 2022/9/3.
//  Copyright © 2022 tjd. All rights reserved.
//

import UIKit

struct ClockResponse: Codable {
    var previewPic: String?
    var resourcesUrl: String?
    var resolutionRatio: String?
    var isPublish: String?
}

struct MarketClockResponse: Codable {
    var total: Int?
    var rows: [ClockResponse]?
}
