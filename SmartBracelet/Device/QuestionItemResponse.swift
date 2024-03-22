//
//  QuestionItemResponse.swift
//  SmartBracelet
//
//  Created by anker on 2022/12/7.
//  Copyright © 2022 tjd. All rights reserved.
//

import UIKit

class QuestionItemResponse: Codable {
    var id: Int?
    var title: String?
    var content: String?
    var answer: String?
}


class QuestionResponse: Codable {
    var total: Int?
    var rows: [QuestionItemResponse]?
}
