//
//  ABOtaViewController.swift
//  AB_OTA Demo
//
//  Created by Bluetrum on 2023/2/27.
//

import UIKit
import CoreBluetooth

class ABOtaViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var twsLabel: UILabel!
    @IBOutlet weak var twsConnectionLabel: UILabel!
    @IBOutlet weak var channelLabel: UILabel!
    
    @IBOutlet weak var timeLayout: UIStackView!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    var peripheral: CBPeripheral!
    
    private var abOta: ABOta!
    
    private let otaTimeRecord = TimeRecord()
    
    // MARK: -
    
    override func viewDidLoad() {
        XGZTBlueToothManager.shared.isOTAing = true
        self.abOta = ABOta()
        self.abOta.eventListener = self
        self.abOta.sendDelegate = XGZTBlueToothManager.shared
        XGZTBlueToothManager.shared.delegate = self 
        
        setupTimeLabelsFont()
        
        OTAInfoManager.shared.fetchOTAInfo { result in
            if let otaUrl = result?.rows.first?.otaUrl {
                OTAInfoManager.shared.downloadOTAFile(from: otaUrl) { [weak self] downloadResult in
                    switch downloadResult {
                    case .success(let fileURL):
                        print("File downloaded to: \(fileURL)")
                        if let data = OTAInfoManager.shared.readSavedOTAFile() {
                            print("Read saved OTA file with size: \(data.count) bytes")
                            self?.abOta.setOtaData(data)
                            
                        }
                    case .failure(let error):
                        print("Failed to download file: \(error)")
                    }
                }
            }
        }
        
        
        XGZTBlueToothManager.shared.isReadyOTA()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        XGZTBlueToothManager.shared.isOTAing = false 
    }
    
    private func setupTimeLabelsFont() {
        startTimeLabel.font = UIFont(descriptor: startTimeLabel.font.fontDescriptor.withSymbolicTraits(.traitMonoSpace)!, size: startTimeLabel.font.pointSize)
        endTimeLabel.font = UIFont(descriptor: endTimeLabel.font.fontDescriptor.withSymbolicTraits(.traitMonoSpace)!, size: endTimeLabel.font.pointSize)
        totalTimeLabel.font = UIFont(descriptor: totalTimeLabel.font.fontDescriptor.withSymbolicTraits(.traitMonoSpace)!, size: totalTimeLabel.font.pointSize)
    }
    
    private func checkIfOtaReady() {
        // If ready, enable button
        updateButton.isEnabled = isReadyToUpdate()
    }
    
    private func isReadyToUpdate() -> Bool {
        return abOta.isReady()
    }
    
    @IBAction func doUpdate(_ sender: Any) {
        guard isReadyToUpdate() else { return }
        
        abOta.startOTA()
    }
    
    private func startAndShowTime() {
        otaTimeRecord.startRecord(isNewRecord: true)
        startTimeLabel.text = otaTimeRecord.startTimeText
        endTimeLabel.text = "..."
        totalTimeLabel.text = "..."
    }
    
    private func stopAndShowTime() {
        otaTimeRecord.stopRecord()
        endTimeLabel.text = otaTimeRecord.endTimeText
        totalTimeLabel.text = otaTimeRecord.timeIntervalText
    }
    
    // MARK: -
    
    private func showErrorDescription(error: OTAError) {
        let errorDescription = "Error occurred: \(String(describing: error.errorDescription))"
        statusLabel.text = errorDescription
    }
    
    private func showProgress(_ progress: Float) {
        DispatchQueue.main.async { [weak self] in
            let normalizedProgress = progress / 100.0
            self?.progressView.progress = normalizedProgress
            self?.progressLabel.text = String(format: "%d%%", UInt(progress))
        }
    }
    
    private func refreshUpdateStatus() {
        // Pop back isn't allowed when it's in progress
        navigationItem.hidesBackButton = abOta.isUpdating()
        // Keep screen on
        UIApplication.shared.isIdleTimerDisabled = abOta.isUpdating()
    }
    
    // MARK: -
    
    func onReady() {
        checkIfOtaReady()
    }
    
    func onStart() {
        statusLabel.text = NSLocalizedString("Updating...", comment: "")
        updateButton.isEnabled = false
        refreshUpdateStatus()
        updateButton.backgroundColor = .yellow
        
        startAndShowTime()
        timeLayout.isHidden = false
    }
    
    func onProgress(_ progress: Float) {
        showProgress(progress)
    }
    
    func onPause() {
        otaTimeRecord.stopRecord()
        statusLabel.text = NSLocalizedString("Update pause", comment: "")
    }
    
    func onContinue() {
        otaTimeRecord.startRecord(isNewRecord: false)
        statusLabel.text = NSLocalizedString("Updating...", comment: "")
    }
    
    func onFinish() {
        stopAndShowTime()
        statusLabel.text = NSLocalizedString("Update is finished", comment: "")
        progressLabel.text = NSLocalizedString("Update is finished", comment: "")
        updateButton.backgroundColor = .green
        refreshUpdateStatus()
    }
    
    func onWaitFinish() {
        stopAndShowTime()
        statusLabel.text = NSLocalizedString("Please wait for the update to complete, and the device will reboot automatically", comment: "")
        progressLabel.text = NSLocalizedString("Data transmission is complete", comment: "")
        updateButton.backgroundColor = .blue
        refreshUpdateStatus()
    }
    
    func onError(errorCode: Int) {
        stopAndShowTime()
        refreshUpdateStatus()
        updateButton.backgroundColor = .red
        updateButton.isEnabled = false
        
        var errorReason: String = "Unknown Error"
        switch errorCode {
        case ABOta.ERROR_CODE_DEVICE_REFUSED:
            errorReason = "Device refused update"
        case ABOta.ERROR_CODE_NO_OTA_DATA:
            errorReason = "No OTA data"
        case ABOta.ERROR_CODE_TIMEOUT:
            errorReason = "Timeout"
        case ABOta.ERROR_CODE_TWS_DISCONNECTED:
            errorReason = "TWS disconnected, stop updating"
        case ABOta.ERROR_CODE_DATA_READER_ERROR:
            errorReason = "DataReader error"
            
        // Device Report
        case ABOta.ERROR_CODE_SAME_FIRMWARE:
            errorReason = "Same firmware"
        case ABOta.ERROR_CODE_KEY_MISMATCH:
            errorReason = "Key mismatch"
        case ABOta.ERROR_CODE_CRC_ERROR:
            errorReason = "CRC error"
        default:
            break
        }
        statusLabel.text = NSLocalizedString("Error occurred: ", comment: "") + errorReason
    }
}

extension ABOtaViewController: BleManagerDelegate {
    
    func onBleReady() {
        // 设备准备好之后，通知ABOta准备升级
        abOta.prepareToUpdate()
    }
    
    func receiveData(_ data: Data) {
        abOta.handleData(data)
    }
    
    func sentData() {
        abOta.nextRun()
    }
}

extension ABOtaViewController: ABOtaEventListener {
    
    func onStatusChanged(_ status: OtaStatus) {
        switch status {
        case .OtaStatusReady:                       onReady()
        case .OtaStatusStart:                       onStart()
        case .OtaStatusUpdating(let progress):      onProgress(Float(progress))
        case .OtaStatusPause:                       onPause()
        case .OtaStatusContinue:                    onContinue()
        case .OtaStatuSuccess:                      onFinish()
        case .OtaStatusWaitFinish:                  onWaitFinish()
        case .OtaStatusFail(let code):              onError(errorCode: code)
        }
    }
    
    func onReceiveVersion(_ version: UInt16) {
        let v1 = (version >> 12) & 0x0F
        let v2 = (version >> 8 ) & 0x0F
        let v3 = (version >> 4 ) & 0x0F
        let v4 = (version >> 0 ) & 0x0F
        let versionString = "\(v1).\(v2).\(v3).\(v4)"
        Logger.i(self, "Device firmware version: \(versionString)");
        versionLabel.text = versionString
    }
    
    func onReceiveTWSInfo(isTWS: Bool, isTWSConnected: Bool) {
        if isTWS {
            twsLabel.isHidden = false
            twsConnectionLabel.isHidden = false

            if isTWSConnected {
                twsConnectionLabel.text = NSLocalizedString("Connected", comment: "")
            } else {
                twsConnectionLabel.text = NSLocalizedString("Disconnected", comment: "")
                updateButton.isEnabled = false
            }
        }
    }
    
    func onReceiveChannel(_ isLeftChannel: Bool) {
        channelLabel.text = isLeftChannel ? NSLocalizedString("Left", comment: "") : NSLocalizedString("Right", comment: "")
    }
}
