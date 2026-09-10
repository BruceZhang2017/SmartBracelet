import UIKit

/// 对应 Android EcgWaveformGenerator.kt
final class EcgWaveformGenerator {
    static let samplesPerSecond = 125.0
    static let sampleIntervalSeconds = 1.0 / samplesPerSecond

    private var timeInCycle: Double = 0.0

    func reset() {
        timeInCycle = 0.0
    }

    func nextSample(heartRate: Int) -> Float {
        if heartRate <= 0 {
            reset()
            return 0
        }
        let hr = Double(heartRate)
        timeInCycle = (timeInCycle + Self.sampleIntervalSeconds).truncatingRemainder(dividingBy: 60.0 / hr)
        let scale = 0.52 + ((min(max(hr, 55.0), 125.0) - 55.0) / 65.0) * 0.88
        let compression = min(1.0, (60.0 / hr) / 0.82)

        func wave(center: Double, amplitude: Double, sigma: Double) -> Double {
            let difference = timeInCycle - center * compression
            let width = sigma * compression
            return amplitude * scale * exp(-difference * difference / (2.0 * width * width))
        }
        let sample = wave(center: 0.12, amplitude: 8.5, sigma: 0.022)
            + wave(center: 0.20, amplitude: -6.5, sigma: 0.009)
            + wave(center: 0.23, amplitude: 65.0, sigma: 0.013)
            + wave(center: 0.26, amplitude: -18.0, sigma: 0.011)
            + wave(center: 0.42, amplitude: 18.0, sigma: 0.040)
        return Float(sample)
    }
}

/// 对应 Android EcgWaveformView.kt
final class EcgWaveformView: UIView {

    private let generator = EcgWaveformGenerator()
    private var samples: [Float] = [0]
    private var nextSampleIndex = 0
    private var heartRate = 0
    private var running = false
    private var lastFrameTime: CFTimeInterval = 0
    private var pendingSeconds: Double = 0
    private var displayLink: CADisplayLink?
    private let density: CGFloat = 1.0

    private static let gridColor = UIColor(red: 253 / 255.0, green: 232 / 255.0, blue: 235 / 255.0, alpha: 1.0)
    private static let majorGridColor = UIColor(red: 244 / 255.0, green: 165 / 255.0, blue: 178 / 255.0, alpha: 1.0)
    private static let baselineColor = UIColor(red: 232 / 255.0, green: 112 / 255.0, blue: 130 / 255.0, alpha: 1.0)
    private static let waveformColor = UIColor(red: 15 / 255.0, green: 23 / 255.0, blue: 42 / 255.0, alpha: 1.0)
    private static let rulerColor = UIColor(red: 148 / 255.0, green: 163 / 255.0, blue: 184 / 255.0, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
    }

    func start(initialHeartRate: Int = 0) {
        heartRate = max(0, initialHeartRate)
        reset()
        running = true
        lastFrameTime = 0
        startDisplayLink()
    }

    func updateHeartRate(_ value: Int) {
        heartRate = max(0, value)
        if heartRate == 0 {
            generator.reset()
        }
    }

    func resume() {
        if running { return }
        lastFrameTime = 0
        pendingSeconds = 0
        running = true
        startDisplayLink()
    }

    func stop() {
        running = false
        lastFrameTime = 0
        stopDisplayLink()
    }

    func reset() {
        samples = Array(repeating: 0, count: max(Int(ceil(bounds.width / density)), 1) + 1)
        nextSampleIndex = 0
        generator.reset()
        lastFrameTime = 0
        pendingSeconds = 0
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let newCount = max(Int(ceil(bounds.width / density)), 1) + 1
        guard samples.count != newCount else { return }
        var resized = Array(repeating: Float(0), count: newCount)
        let kept = min(samples.count, resized.count)
        if kept > 0 {
            for i in 0..<kept {
                resized[resized.count - kept + i] = samples[(nextSampleIndex + samples.count - kept + i) % samples.count]
            }
        }
        samples = resized
        nextSampleIndex = 0
    }

    deinit {
        stopDisplayLink()
    }

    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(frameTick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func frameTick(_ link: CADisplayLink) {
        guard running else { return }
        let now = CACurrentMediaTime()
        let elapsedSeconds = now - lastFrameTime
        if lastFrameTime != 0 && window != nil && elapsedSeconds >= 0 && elapsedSeconds <= 0.25 {
            pendingSeconds += elapsedSeconds
            let interval = EcgWaveformGenerator.sampleIntervalSeconds
            while pendingSeconds >= interval {
                samples[nextSampleIndex] = generator.nextSample(heartRate: heartRate)
                nextSampleIndex = (nextSampleIndex + 1) % samples.count
                pendingSeconds -= interval
            }
        }
        lastFrameTime = now
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        drawGrid(in: rect)
        drawWaveform(in: rect)
        var second = 0
        while CGFloat(second) * 125 * density + 6 * density < bounds.width {
            let text = "\(second)s" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10 * density),
                .foregroundColor: Self.rulerColor
            ]
            text.draw(at: CGPoint(x: CGFloat(second) * 125 * density + 6 * density, y: bounds.height - 8 * density),
                      withAttributes: attributes)
            second += 1
        }
    }

    private func drawGrid(in rect: CGRect) {
        let spacing = 5 * density
        var index = 0
        while CGFloat(index) * spacing <= bounds.width {
            let x = CGFloat(index) * spacing
            let isMajor = index % 5 == 0
            drawLine(from: CGPoint(x: x, y: 0),
                     to: CGPoint(x: x, y: bounds.height),
                     color: isMajor ? Self.majorGridColor : Self.gridColor,
                     width: isMajor ? 0.75 * density : 0.5 * density)
            index += 1
        }
        index = 0
        while CGFloat(index) * spacing <= bounds.height {
            let y = CGFloat(index) * spacing
            let isMajor = index % 5 == 0
            drawLine(from: CGPoint(x: 0, y: y),
                     to: CGPoint(x: bounds.width, y: y),
                     color: isMajor ? Self.majorGridColor : Self.gridColor,
                     width: isMajor ? 0.75 * density : 0.5 * density)
            index += 1
        }
        let baseline = bounds.height * 105 / 160
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: baseline))
        path.addLine(to: CGPoint(x: bounds.width, y: baseline))
        path.setLineDash([4 * density, 2 * density], count: 2, phase: 0)
        Self.baselineColor.setStroke()
        path.lineWidth = 0.75 * density
        path.stroke()
    }

    private func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor, width: CGFloat) {
        color.setStroke()
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = width
        path.stroke()
    }

    private func drawWaveform(in rect: CGRect) {
        let scale = bounds.height / 160
        let baseline = 105 * scale
        let path = UIBezierPath()
        for (position, _) in samples.enumerated() {
            let sampleIndex = (nextSampleIndex + position) % samples.count
            let x = bounds.width - CGFloat(samples.count - 1 - position) * density
            let y = min(max(baseline - CGFloat(samples[sampleIndex]) * scale, 8 * scale), bounds.height - 8 * scale)
            if position == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        Self.waveformColor.setStroke()
        path.lineWidth = 2.2 * density
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.stroke()
    }
}