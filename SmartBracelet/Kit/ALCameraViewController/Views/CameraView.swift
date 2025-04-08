//
//  CameraView.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2015/06/17.
//  Copyright (c) 2015 zero. All rights reserved.
//


import UIKit
import AVFoundation


public class CameraView: UIView {

    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var device: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var preview: AVCaptureVideoPreviewLayer!

    let cameraQueue = DispatchQueue(label: "com.zero.ALCameraViewController.Queue")


    public var currentPosition = CameraGlobals.shared.defaultCameraPosition

    public func startSession() {
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo


        device = cameraWithPosition(position: currentPosition)
        if let device = device , device.hasFlash {
            cameraQueue.async {
                do {
                    try device.lockForConfiguration()
                    device.flashMode = .auto
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting flash mode: \(error.localizedDescription)")
                }
            }
        }

        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

        cameraQueue.async {
            [weak self] in
            do {
                guard let self = self else { return }
                self.input = try AVCaptureDeviceInput(device: self.device)
            } catch let error as NSError {
                self?.input = nil
                print("Error: \(error.localizedDescription)")
                return
            }


            if let self = self, self.session.canAddInput(self.input) {
                self.session.addInput(self.input)
            }


            self?.imageOutput = AVCaptureStillImageOutput()
            self?.imageOutput.outputSettings = outputSettings

            if let self = self, self.session.canAddOutput(self.imageOutput) {
                self.session.addOutput(self.imageOutput)
            }

            self?.session.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.createPreview()
                self?.rotatePreview()
            }
        }
    }

    public func stopSession() {
        cameraQueue.sync {
            session?.stopRunning()
            preview?.removeFromSuperlayer()

            session = nil
            input = nil
            imageOutput = nil
            preview = nil
            device = nil
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = bounds
    }


    public func configureZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        addGestureRecognizer(pinchGesture)
    }


    @objc internal func pinch(gesture: UIPinchGestureRecognizer) {
        guard let device = device else { return }


        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
        }


        func update(scale factor: CGFloat) {
            cameraQueue.async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }
                    device.videoZoomFactor = factor
                } catch {
                    print("\(error.localizedDescription)")
                }
            }
        }


        let velocity = gesture.velocity
        let velocityFactor: CGFloat = 8.0
        let desiredZoomFactor = device.videoZoomFactor + atan2(velocity, velocityFactor)


        let newScaleFactor = minMaxZoom(desiredZoomFactor)
        switch gesture.state {
        case .began, .changed:
            update(scale: newScaleFactor)
        case _:
            break
        }
    }

    private func createPreview() {

        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.frame = bounds


        layer.addSublayer(preview)
    }

    private func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        return devices.filter { $0.position == position }.first
    }

    public func capturePhoto(completion: @escaping CameraShotCompletion) {
        cameraQueue.sync {
            [weak self] in
            guard let self = self, self.session.isRunning else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard self.session.isRunning, let output = self.imageOutput else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            self.isUserInteractionEnabled = false


            guard let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue),
                  let captureSession = self.session, captureSession.isRunning else {
                completion(nil)
                return
            }


            let size = self.frame.size
            
            guard let connection = output.connection(with: .video), connection.isEnabled, connection.isActive else {
                DispatchQueue.main.async { [weak self] in
                    self?.isUserInteractionEnabled = true
                    completion(nil)
                }
                return
            }
            connection.videoOrientation = orientation
            takePhoto(output, videoOrientation: orientation, cameraPosition: device.position, cropSize: size) { image in
                DispatchQueue.main.async() { [weak self] in
                    self?.isUserInteractionEnabled = true
                    completion(image)
                }
            }
        }
    }

    public func focusCamera(toPoint: CGPoint) -> Bool {

        guard let device = device, let preview = preview, device.isFocusModeSupported(.continuousAutoFocus) else {
            return false
        }

        cameraQueue.async {
            do { try device.lockForConfiguration() } catch {
                return
            }

            let focusPoint = preview.captureDevicePointConverted(fromLayerPoint: toPoint)


            device.focusPointOfInterest = focusPoint
            device.focusMode = .continuousAutoFocus


            device.exposurePointOfInterest = focusPoint
            device.exposureMode = .continuousAutoExposure


            device.unlockForConfiguration()
        }

        return true
    }

    public func cycleFlash() {
        guard let device = device, device.hasFlash else {
            return
        }

        cameraQueue.async {
            do {
                try device.lockForConfiguration()
                if device.flashMode == .on {
                    device.flashMode = .off
                } else if device.flashMode == .off {
                    device.flashMode = .auto
                } else {
                    device.flashMode = .on
                }
                device.unlockForConfiguration()
            } catch {
                print("Error cycling flash mode: \(error.localizedDescription)")
            }
        }
    }


    public func swapCameraInput() {

        guard let session = session, let currentInput = input else {
            return
        }

        cameraQueue.async {
            session.beginConfiguration()
            session.removeInput(currentInput)

            if currentInput.device.position == AVCaptureDevice.Position.back {
                self.currentPosition = AVCaptureDevice.Position.front
                self.device = self.cameraWithPosition(position: self.currentPosition)
            } else {
                self.currentPosition = AVCaptureDevice.Position.back
                self.device = self.cameraWithPosition(position: self.currentPosition)
            }

            guard let newInput = try? AVCaptureDeviceInput(device: self.device) else {
                return
            }

            self.input = newInput

            session.addInput(newInput)
            session.commitConfiguration()
        }
    }

    public func rotatePreview() {

        guard preview != nil else {
            return
        }
        DispatchQueue.main.async {
            switch UIApplication.shared.statusBarOrientation {
                case .portrait:
                  self.preview?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                case .portraitUpsideDown:
                  self.preview?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                case .landscapeRight:
                  self.preview?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                case .landscapeLeft:
                  self.preview?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                default: break
            }
        }
    }

}
