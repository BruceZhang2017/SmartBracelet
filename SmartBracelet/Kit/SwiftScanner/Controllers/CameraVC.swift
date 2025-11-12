import UIKit
import AVFoundation

protocol CameraViewControllerDelegate: AnyObject {
    func didOutput(_ code: String)
    func didReceiveError(_ error: Error)
}

public class CameraVC: UIViewController {

    weak var delegate: CameraViewControllerDelegate?

    // 动画相关属性
    lazy var animationImage = UIImage()
    var animationStyle: ScanAnimationStyle = .default {
        didSet {
            animationImage = animationStyle == .default ? imageNamed("ScanLine") : imageNamed("ScanNet")
        }
    }
    lazy var scannerColor: UIColor = .red
    public lazy var flashBtn: UIButton = .init(type: .custom)

    // 手电筒模式
    private var torchMode: TorchMode = .off {
        didSet {
            guard let captureDevice = captureDevice,
                  captureDevice.hasTorch,
                  captureDevice.isTorchModeSupported(torchMode.captureTorchMode) else { return }

            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = torchMode.captureTorchMode
                captureDevice.unlockForConfiguration()
            } catch {
                XLogger.shared.log("Torch could not be used")
            }

            DispatchQueue.main.async {
                self.flashBtn.setImage(self.torchMode.image, for: .normal)
            }
        }
    }

    // 支持的元数据类型
    var metadata = [AVMetadataObject.ObjectType]()

    // MARK: - 捕获会话相关属性

    /// 专用的串行队列用于会话配置和控制
    private let sessionQueue = DispatchQueue(label: "com.yourapp.capturesession")
    private lazy var captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isSessionConfigured = false

    /// 视频捕获设备
    private lazy var captureDevice: AVCaptureDevice? = {
        guard let device = AVCaptureDevice.default(for: .video) else { return nil }

        do {
            try device.lockForConfiguration()
            // 自动白平衡
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            // 自动对焦
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            // 自动曝光
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            XLogger.shared.log("Device configuration error: \(error)")
        }

        return device
    }()

    // 扫描视图
    lazy var scanView = ScanView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))

    // MARK: - 生命周期方法

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCamera()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCapturing()
        scanView.startAnimation()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCapturing()
        scanView.stopAnimation()
    }

    // MARK: - 设置方法

    /// 设置UI界面
    func setupUI() {
        DispatchQueue.main.async {
            self.view.backgroundColor = .black
            self.scanView.scanAnimationImage = self.animationImage
            self.scanView.scanAnimationStyle = self.animationStyle
            self.scanView.cornerColor = self.scannerColor
            self.view.addSubview(self.scanView)
            self.setupTorch()
        }
    }

    /// 设置摄像头
    func setupCamera() {
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.setupPreviewLayer()
        }
    }

    /// 配置捕获会话
    private func configureSession() {
        guard let captureDevice = self.captureDevice else {
            DispatchQueue.main.async {
                let error = NSError(domain: "CameraVC", code: -1, userInfo: [NSLocalizedDescriptionKey: "摄像头不可用"])
                self.delegate?.didReceiveError(error)
            }
            return
        }

        do {
            self.captureSession.beginConfiguration()

            // 添加输入
            let videoInput = try AVCaptureDeviceInput(device: captureDevice)
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            }

            // 添加元数据输出
            let metadataOutput = AVCaptureMetadataOutput()
            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
                metadataOutput.metadataObjectTypes = self.metadata
            }

            // 添加视频数据输出
            let videoDataOutput = AVCaptureVideoDataOutput()
            if self.captureSession.canAddOutput(videoDataOutput) {
                self.captureSession.addOutput(videoDataOutput)
                videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            }

            self.captureSession.commitConfiguration()
            self.isSessionConfigured = true

        } catch {
            DispatchQueue.main.async {
                self.delegate?.didReceiveError(error)
            }
        }
    }

    /// 设置预览图层
    func setupPreviewLayer() {
        // 在 sessionQueue 上创建预览图层（因为它需要访问 session）
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        // 在主线程上更新 UI
        DispatchQueue.main.async {
            videoPreviewLayer.frame = self.view.layer.bounds
            self.view.layer.insertSublayer(videoPreviewLayer, at: 0)
            self.videoPreviewLayer = videoPreviewLayer
        }

    }

    /// 设置手电筒按钮
    func setupTorch() {
        let buttonSize: CGFloat = 37
        flashBtn.frame = CGRect(x: screenWidth - 20 - buttonSize, y: statusHeight + 44 + 20, width: buttonSize, height: buttonSize)
        flashBtn.addTarget(self, action: #selector(flashBtnClick), for: .touchUpInside)
        flashBtn.isHidden = true
        self.view.addSubview(flashBtn)
        self.view.bringSubviewToFront(flashBtn)
        torchMode = .off
    }

    // MARK: - 会话控制方法

    /// 开始捕获
    func startCapturing() {
        sessionQueue.async {
            guard self.isSessionConfigured else {
                XLogger.shared.log("Cannot start session: not configured yet")
                return
            }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    /// 停止捕获
    func stopCapturing() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    // MARK: - 按钮点击事件

    @objc func flashBtnClick(sender: UIButton) {
        torchMode = torchMode.next
    }

}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension CameraVC: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            let scannedValue = object.stringValue ?? ""

            // 停止捕获
            self.stopCapturing()

            // 将结果传递给代理
            DispatchQueue.main.async {
                self.delegate?.didOutput(scannedValue)
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        // 这里是在 sessionQueue 上执行的，需要更新 UI 时切换到主线程
        guard let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [String: Any],
              let exifMetadata = metadataDict[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? Double else {
            return
        }

        DispatchQueue.main.async {
            // 判断光线强弱，更新手电筒按钮的显示状态
            if brightnessValue < -1.0 {
                self.flashBtn.isHidden = false
            } else {
                self.flashBtn.isHidden = self.torchMode == .on ? false : true
            }
        }
    }
}


