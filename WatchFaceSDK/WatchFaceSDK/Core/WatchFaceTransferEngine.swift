//
//  WatchFaceTransferEngine.swift
//  WatchFaceSDK
//
//  Created by bruce on 2025/12/30.
//

import Foundation
import WatchProtocolSDK

// MARK: - 表盘传输引擎
public class WatchFaceTransferEngine {

    // MARK: - 属性
    private let dialProtocol: XGZTDialProtocol
    private let packetManager: PacketManager
    private weak var delegate: TransferDelegate?

    private var currentData: Data?
    private var currentPacketIndex: Int = 0
    private var transferState: TransferState = .idle
    private var config: TransferConfig?

    // MARK: - 初始化
    public init() {
        self.dialProtocol = XGZTDialProtocol.shared
        self.packetManager = PacketManager()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 公开方法

    /// 开始传输
    /// - Parameters:
    ///   - data: 要传输的数据
    ///   - dialType: 表盘类型
    ///   - timePosition: 时间位置（仅自定义表盘）
    ///   - color: 颜色（仅自定义表盘）
    ///   - delegate: 传输代理
    public func startTransfer(
        data: Data,
        dialType: DialType,
        timePosition: TimePosition = .none,
        color: DialColor = .white,
        delegate: TransferDelegate?
    ) {
        guard transferState.isIdle else {
            XLogger.shared.log("⚠️ 传输正在进行中，无法开始新的传输")
            return
        }

        self.delegate = delegate
        self.currentData = data
        self.currentPacketIndex = 0
        self.transferState = .preparing

        XLogger.shared.log("🚀 开始传输表盘 - 类型: \(dialType), 数据大小: \(data.count) bytes")

        // 如果是自定义表盘，先设置时间位置和颜色
        if dialType == .custom {
            XLogger.shared.log("🎨 设置自定义表盘时间位置和颜色: \(timePosition), \(color)")
            self.dialProtocol.setTimePositionAndColor(position: timePosition, color: color)
        }

        // 查询 MTU
        queryMTUAndStartTransfer(dialType: dialType, timePosition: timePosition, color: color)
    }

    /// 暂停传输
    public func pauseTransfer() {
        XLogger.shared.log("⏸ 暂停传输")
        transferState = .idle
    }

    /// 取消传输
    public func cancelTransfer() {
        XLogger.shared.log("❌ 取消传输")
        transferState = .cancelled
        delegate?.transferDidCancel()

        // ✅ 修复：传输取消后重置为空闲状态，允许开始新的传输
        transferState = .idle
        cleanup()
    }

    /// 重试传输
    public func retryTransfer() {
        guard let data = currentData, let config = config else {
            XLogger.shared.log("⚠️ 无法重试：缺少传输数据或配置")
            return
        }

        XLogger.shared.log("🔄 重试传输")
        currentPacketIndex = 0
        transferState = .preparing
        configureAndStartTransfer(data: data, config: config)
    }

    // MARK: - 私有方法

    private func queryMTUAndStartTransfer(
        dialType: DialType,
        timePosition: TimePosition,
        color: DialColor
    ) {
        transferState = .querying
        XLogger.shared.log("📡 查询设备 MTU...")

        self.dialProtocol.queryMTU { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let mtu):
                XLogger.shared.log("✅ MTU 查询成功: \(mtu)")
                self.prepareTransfer(mtu: mtu, dialType: dialType, timePosition: timePosition, color: color)

            case .failure(let error):
                XLogger.shared.log("❌ MTU 查询失败: \(error)")
                self.handleTransferError(error)
            }
        }
    }

    private func prepareTransfer(
        mtu: Int,
        dialType: DialType,
        timePosition: TimePosition,
        color: DialColor
    ) {
        guard let data = currentData else {
            handleTransferError(WatchFaceError.invalidConfiguration)
            return
        }

        let packageTotal = packetManager.calculatePackageCount(dataSize: data.count)

        let config = TransferConfig(
            packageTotal: packageTotal,
            binSize: data.count,
            mtu: mtu,
            dialType: dialType,
            timePosition: timePosition,
            color: color
        )

        self.config = config

        XLogger.shared.log("⚙️ 配置传输参数 - 总包数: \(packageTotal), MTU: \(mtu)")

        configureAndStartTransfer(data: data, config: config)
    }

    private func configureAndStartTransfer(data: Data, config: TransferConfig) {
        transferState = .configuring

        // 设置传输配置
        self.dialProtocol.setTransferConfig(config)

        // 开始传输
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startPacketTransfer()
        }
    }

    private func startPacketTransfer() {
        guard let data = currentData else {
            handleTransferError(WatchFaceError.invalidConfiguration)
            return
        }

        transferState = .transferring
        delegate?.transferDidStart()

        currentPacketIndex = 0
        sendNextPacket()
    }

    private func sendNextPacket() {
        guard let data = currentData else { return }
        guard transferState.isTransferring else { return }

        let (packetData, isLast) = packetManager.getPacketData(from: data, packetIndex: currentPacketIndex)

        if packetData.isEmpty {
            XLogger.shared.log("✅ 所有数据包已发送完成")
            handleTransferComplete()
            return
        }

        let packageNum = currentPacketIndex + 1  // 包序号从1开始
        let binNum = packetManager.getByteOffset(for: currentPacketIndex)
        let progress = Int(packetManager.calculateProgressByBytes(bytesTransferred: binNum, totalBytes: data.count) * 100)
        let control = isLast ? 1 : 0

        XLogger.shared.log("📤 发送数据包 \(packageNum)/\(config?.packageTotal ?? 0) - 偏移: \(binNum), 大小: \(packetData.count), 进度: \(progress)%")

        // 发送数据包
        self.dialProtocol.transferPacket(
            packageNum: packageNum,
            binNum: binNum,
            progress: progress,
            control: control,
            data: packetData
        )

        // 更新进度
        let transferProgress = TransferProgress(
            currentPacket: packageNum,
            totalPackets: config?.packageTotal ?? 0,
            bytesTransferred: binNum + packetData.count,
            totalBytes: data.count
        )

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.transferDidUpdateProgress(transferProgress)
        }

        currentPacketIndex += 1

        // 继续发送下一个包（添加短暂延迟避免拥塞）
        if !isLast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
                self?.sendNextPacket()
            }
        }
    }

    private func handleTransferComplete() {
        XLogger.shared.log("🎉 表盘传输完成")
        transferState = .completed

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.transferDidComplete()
        }

        // ✅ 修复：传输完成后重置为空闲状态，允许开始新的传输
        transferState = .idle
        cleanup()
    }

    private func handleTransferError(_ error: Error) {
        XLogger.shared.log("❌ 表盘传输失败: \(error.localizedDescription)")
        transferState = .failed(error)

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.transferDidFail(error: error)
        }

        // ✅ 修复：传输失败后重置为空闲状态，允许重试或开始新的传输
        transferState = .idle
        cleanup()
    }

    private func cleanup() {
        currentData = nil
        currentPacketIndex = 0
        config = nil
    }

    // MARK: - 通知观察
    private func setupNotificationObservers() {
        // 监听来自设备的响应通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransferNotification(_:)),
            name: Notification.Name("MyClockViewController"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransferNotification(_:)),
            name: Notification.Name("ClockUseViewController"),
            object: nil
        )
    }

    @objc private func handleTransferNotification(_ notification: Notification) {
        guard let obj = notification.object as? Int else { return }

        switch obj {
        case 4:
            // 配置完成，准备开始传输
            XLogger.shared.log("✅ 配置完成，开始传输")

        case 5:
            // 继续传输下一个包
            // 这个case在sendNextPacket中已经处理
            break

        case 6:
            // 传输成功
            XLogger.shared.log("✅ 收到传输成功通知")
            handleTransferComplete()

        case 7:
            // 传输失败
            XLogger.shared.log("❌ 收到传输失败通知")
            handleTransferError(WatchFaceError.transferFailed)

        default:
            break
        }
    }
}
