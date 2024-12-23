//
//  CustomOtaManager.swift
//  AB_FOTA
//
//  Created by Bluetrum on 2023/2/22.
//

import Foundation

public protocol ABOtaManagerDelegate: OtaManagerDelegate {
    func sendOtaData(_ data: Data) throws
}

open class ABOtaManager: OtaManager {
    
    private var abDelegate: ABOtaManagerDelegate! {
        didSet {
            super.delegate = abDelegate
        }
    }
    
    @available(*, unavailable, message: "Use customDelegate instead")
    public override var delegate: OtaManagerDelegate? {
        get {
            return super.delegate
        }
        set {
            super.delegate = newValue
        }
    }
    
    private var packetSize: UInt16 = OtaConstants.DEFAULT_PACKET_SIZE
    
    @available(*, unavailable, message: "Use init(_:) instead")
    public override init() {
        fatalError("Use init(_:) instead")
    }
    
    public init(delegate: ABOtaManagerDelegate) {
        super.init()
        defer {
            self.abDelegate = delegate
        }
    }
    
    // MARK: - Public API
    
    /// `OtaManager`内部使用
    public override func getPacketSize() -> UInt16 {
        return packetSize
    }
    
    /// 协商好MTU之后，使用`peripheral.maximumWriteValueLength(for: .withoutResponse)`获取
    open func setPacketSize(_ size: UInt16) {
        packetSize = size
    }
    
    /// `OtaManager`内部使用
    open override func send(_ data: Data) throws {
        // 如果来了暂停，就先不要发了
        guard !isUpdatePause else { return }
        
        try abDelegate.sendOtaData(data)
    }
    
    /// OTA数据包发送完成后，调用此方法继续下一包
    public func nextRun() {
        runDataSend()
    }
}
