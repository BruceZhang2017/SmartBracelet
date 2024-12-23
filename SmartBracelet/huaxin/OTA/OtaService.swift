//
//  OtaService.swift
//  AB_OTA Demo
//
//  Created by Bluetrum on 2023/2/24.
//

import Foundation
import CoreBluetooth

struct OTAService {
    public static let uuid        = CBUUID(string: "FF12")
    public static let dataInUuid  = CBUUID(string: "FF14")
    public static let dataOutUuid = CBUUID(string: "FF15")
    
    public static func matches(_ service: CBService) -> Bool {
        return service.isOTAService
    }
    
    private init() {}
}

extension CBService {
    
    var isOTAService: Bool {
        return uuid == OTAService.uuid
    }
    
}

extension CBCharacteristic {
    
    var isOTADataInCharacteristic: Bool {
        return uuid == OTAService.dataInUuid
    }
    
    var isOTADataOutCharacteristic: Bool {
        return uuid == OTAService.dataOutUuid
    }
    
}
