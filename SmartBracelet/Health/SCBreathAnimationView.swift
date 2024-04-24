import UIKit

public class SCBreathAnimationView: UIView {

    // MARK: Public
    
    public class func viewFromNIB() -> SCBreathAnimationView {
        let views = Bundle.main.loadNibNamed("SCBreathAnimationView", owner: nil, options: nil)
        return views![0] as! SCBreathAnimationView
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        waterWaveViewWidthConstraint.constant = waterWaveWidth
        
        addWaterRipple()
    }
    
    public func startAnimation() {
        if waterWaveTimer == nil {
            waterWaveTimer = Timer.scheduledTimer(
                timeInterval: 1.51,
                target: self,
                selector: #selector(waterRippleAnimation),
                userInfo: nil,
                repeats: true)
            waterWaveTimer?.fire()
            RunLoop.main.add(waterWaveTimer!, forMode: RunLoop.Mode.common)
        }
    }
    
    public func stopAnimation() {
        waterWaveTimer?.invalidate()
        waterWaveTimer = nil
    }

    // MARK: Internal

    @IBOutlet weak var waterWaveView: UIView!
    @IBOutlet weak var waveView: UIView!
    @IBOutlet weak var waterWaveViewWidthConstraint: NSLayoutConstraint!
    
    var waterWaveTimer: Timer?
    
    var waterRippleView1: UIView!
    var waterRippleView2: UIView!
    var waterRippleView3: UIView!

    // MARK: Private

    private let waterWaveWidth: CGFloat = 160
    private let wavePreWidth: CGFloat = 85
    private let waterRippleView1PreWidth: CGFloat = 150
    private let waterRippleView2PreWidth: CGFloat = 233
    private let waterRippleView3PreWidth: CGFloat = 361
    private let waveWidth: CGFloat = 230
    private let waterRippleView1Width: CGFloat = 270
    private let waterRippleView2Width: CGFloat = 410
    private let waterRippleView3Width: CGFloat = 590
    private let waveSufWidth: CGFloat = 262
    private let waterRippleView1SufWidth: CGFloat = 370
    private let waterRippleView2SufWidth: CGFloat = 560
    private let waterRippleView3SufWidth: CGFloat = 770
    
    private let waterWaveRadius = 80

    
    private func addWaterRipple() {
        waterRippleView1 = UIView(frame: CGRect(
            x: -(waterRippleView1Width - waterWaveWidth) / 2,
            y: -(waterRippleView1Width - waterWaveWidth) / 2,
            width: waterRippleView1Width,
            height: waterRippleView1Width))
        waterRippleView1?.layer.cornerRadius = CGFloat(waterRippleView1Width / 2)
        waterRippleView1?.layer.borderWidth = 2
        waterRippleView1?.layer.borderColor = UIColor.brand.cgColor
        waterWaveView.insertSubview(waterRippleView1!, belowSubview: waveView)
        
        waterRippleView2 = UIView(frame: CGRect(
            x: -(waterRippleView2Width - waterWaveWidth) / 2,
            y: -(waterRippleView2Width - waterWaveWidth) / 2,
            width: waterRippleView2Width,
            height: waterRippleView2Width))
        waterRippleView2?.layer.cornerRadius = CGFloat(waterRippleView2Width / 2)
        waterRippleView2?.layer.borderWidth = 2
        waterRippleView2?.layer.borderColor = UIColor.brand.cgColor
        waterWaveView.insertSubview(waterRippleView2!, belowSubview: waterRippleView1!)
        
        waterRippleView3 = UIView(frame: CGRect(
            x: -(waterRippleView3Width - waterWaveWidth) / 2,
            y: -(waterRippleView3Width - waterWaveWidth) / 2,
            width: waterRippleView3Width,
            height: waterRippleView3Width))
        waterRippleView3?.layer.cornerRadius = CGFloat(waterRippleView3Width / 2)
        waterRippleView3?.layer.borderWidth = 2
        waterRippleView3?.layer.borderColor = UIColor.brand.cgColor
        waterWaveView.insertSubview(waterRippleView3!, belowSubview: waterRippleView2!)
        
        waterRippleView1.alpha = 0
        waterRippleView2.alpha = 0
        waterRippleView3.alpha = 0
        
        backgroundColor = .clear
        waveView.backgroundColor = .brand
        waterWaveView.backgroundColor = .clear
    }
    
    // 设置水波纹动画
    @objc
    private func waterRippleAnimation() {
        waterRippleView1.transform = CGAffineTransform(
            scaleX: waterRippleView1PreWidth / waterRippleView1Width,
            y: waterRippleView1PreWidth / waterRippleView1Width)
        waterRippleView2.transform = CGAffineTransform(
            scaleX: waterRippleView1PreWidth / waterRippleView1Width,
            y: waterRippleView1PreWidth / waterRippleView1Width)
        waterRippleView3.transform = CGAffineTransform(
            scaleX: waterRippleView1PreWidth / waterRippleView1Width,
            y: waterRippleView1PreWidth / waterRippleView1Width)
        isHidden = false
        
        UIView.animate(withDuration: 0.9, delay: 0, options: .curveEaseIn, animations: {
            [weak self] in
                self?.waterRippleView1?.transform = CGAffineTransform.identity
                self?.waterRippleView2?.transform = CGAffineTransform.identity
                self?.waterRippleView3?.transform = CGAffineTransform.identity
                self?.waterRippleView1?.alpha = 0.8
                self?.waterRippleView2?.alpha = 0.5
                self?.waterRippleView3?.alpha = 0.2
        }) { [weak self] (_) in
            self?.hideWaterView()
        }
    }
    
    private func hideWaterView() {
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut, animations: {
            [weak self] in
                self?.waterRippleView1?.transform = CGAffineTransform(
                    scaleX: self!.waterRippleView1SufWidth / self!.waterRippleView1Width,
                    y: self!.waterRippleView1SufWidth / self!.waterRippleView1Width)
                self?.waterRippleView2?.transform = CGAffineTransform(
                    scaleX: self!.waterRippleView2SufWidth / self!.waterRippleView2Width,
                    y: self!.waterRippleView2SufWidth / self!.waterRippleView2Width)
                self?.waterRippleView3?.transform = CGAffineTransform(
                    scaleX: self!.waterRippleView3SufWidth / self!.waterRippleView3Width,
                    y: self!.waterRippleView3SufWidth / self!.waterRippleView3Width)
                self?.waterRippleView1?.alpha = 0.0
                self?.waterRippleView2?.alpha = 0.0
                self?.waterRippleView3?.alpha = 0.0
        }) { [weak self] (_) in
            self?.waterRippleView1?.transform = CGAffineTransform.identity
            self?.waterRippleView2?.transform = CGAffineTransform.identity
            self?.waterRippleView3?.transform = CGAffineTransform.identity
        }
    }
}
