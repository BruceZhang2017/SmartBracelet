//
//  EcgHistoryDetailViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2026/09/06.
//  Copyright © 2026 tjd. All rights reserved.
//

import UIKit
import SnapKit

/// Android 对齐：ECG 历史回放页（对应 EcgHistoryDetailActivity + activity_ecg.xml）
/// 渐变 header + 顶部圆角白卡；EcgWaveformView 自绘 P-Q-R-S-T 波形；
/// 16ms anchor 计时回放，支持播放/暂停/继续/重播，离开页面自动暂停、返回自动恢复。
final class EcgHistoryDetailViewController: BaseViewController {

    var recordId: String = ""

    private var points: [EcgPoint] = []
    private var duration: Int64 = 0
    private var position: Int64 = 0
    private var anchor: TimeInterval = 0
    private var nextPoint = 0
    private var playing = false
    private var visible = false
    private var loaded = false
    private var resumeOnStart = false
    private var recordDate = ""
    private var playbackTimer: Timer?

    private let waveformView: EcgWaveformView = EcgWaveformView()

    private let rateLabel: UILabel = {
        let label = UILabel()
        label.text = "ecg_recorded_rate".localized()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.text = "health_value_p_minute".localized()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        return label
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hex: 0x64748B)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("ecg_loading".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.backgroundColor = UIColor.brand
        button.layer.cornerRadius = 22
        button.isEnabled = false
        return button
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.brand.cgColor, UIColor.white.cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    override func viewDidLoad() {
        bStyle = 0
        super.viewDidLoad()
        title = "ecg_history_detail".localized()
        view.backgroundColor = .clear

        setupNavigationBar()
        setupUI()
        loadRecord()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .medium)
        ]
        if let backButton = navigationItem.leftBarButtonItem {
            backButton.tintColor = .white
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupUI() {
        view.layer.insertSublayer(gradientLayer, at: 0)

        view.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
        }

        view.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-16)
            make.top.equalTo(rateLabel.snp.bottom).offset(0)
        }

        view.addSubview(unitLabel)
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(6)
            make.bottom.equalTo(valueLabel).offset(-7)
        }

        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(valueLabel.snp.bottom).offset(24)
        }

        cardView.addSubview(waveformView)
        waveformView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(28)
            make.height.equalTo(180)
        }

        cardView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(waveformView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        cardView.addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
            make.top.equalTo(infoLabel.snp.bottom).offset(20)
        }
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }

    private func loadRecord() {
        DatabaseManager.shared.getEcgHistoryObj(byId: recordId) { [weak self] record in
            guard let self = self else { return }
            guard let record = record else {
                self.showLoadError()
                return
            }
            let decoded = DatabaseManager.decodeEcgPoints(record.samplesJson)
            guard !decoded.isEmpty, record.durationMillis > 0 else {
                self.showLoadError()
                return
            }
            self.points = decoded
            self.duration = Int64(record.durationMillis)
            let date = Date(timeIntervalSince1970: record.startedAt / 1000)
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            self.recordDate = formatter.string(from: date)
            self.loaded = true
            self.playButton.isEnabled = true
            self.playButton.alpha = 1.0
            self.updateInfo()
            if self.visible {
                self.play()
            } else {
                self.resumeOnStart = true
            }
        }
    }

    private func showLoadError() {
        infoLabel.text = "ecg_history_error".localized()
        playButton.isHidden = true
    }

    private func updateInfo() {
        let totalSeconds = (duration + 999) / 1000
        let elapsedSeconds = position >= duration ? totalSeconds : position / 1000
        infoLabel.text = recordDate + "\n" +
            "ecg_playback_time".localized(with: Int32(elapsedSeconds), Int32(totalSeconds)) +
            "\n" + "ecg_waveform_note".localized()
    }

    @objc private func playButtonTapped() {
        if playing {
            pause()
        } else {
            play()
        }
    }

    private func play() {
        guard loaded, !playing else { return }
        if position >= duration || position == 0 {
            position = 0
            nextPoint = 0
            valueLabel.text = "--"
            waveformView.start(initialHeartRate: 0)
        } else {
            waveformView.resume()
        }
        anchor = CACurrentMediaTime() * 1000 - Double(position)
        playing = true
        playButton.setTitle("ecg_pause".localized(), for: .normal)
        startPlaybackTimer()
    }

    private func pause() {
        if playing {
            position = min(Int64(CACurrentMediaTime() * 1000 - anchor), duration)
        }
        playing = false
        playbackTimer?.invalidate()
        playbackTimer = nil
        waveformView.stop()
        if loaded {
            updateInfo()
        }
        playButton.setTitle(position >= duration ? "ecg_replay".localized() : "ecg_resume".localized(), for: .normal)
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        let timer = Timer(timeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.tickPlayback()
        }
        RunLoop.main.add(timer, forMode: .common)
        playbackTimer = timer
    }

    private func tickPlayback() {
        guard playing else { return }
        position = min(Int64(CACurrentMediaTime() * 1000 - anchor), duration)
        while nextPoint < points.count && points[nextPoint].offsetMillis <= position {
            let rate = points[nextPoint].heartRate
            nextPoint += 1
            waveformView.updateHeartRate(rate)
            valueLabel.text = rate > 0 ? "\(rate)" : "--"
        }
        updateInfo()
        if position >= duration {
            pause()
            playButton.setTitle("ecg_replay".localized(), for: .normal)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visible = true
        if resumeOnStart {
            resumeOnStart = false
            play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        visible = false
        resumeOnStart = playing
        pause()
    }

    deinit {
        playbackTimer?.invalidate()
        playbackTimer = nil
        waveformView.stop()
    }
}