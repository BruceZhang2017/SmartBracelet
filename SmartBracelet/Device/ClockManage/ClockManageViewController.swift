import UIKit
import Segmentio
import SnapKit
import WatchProtocolSDK

class ClockManageViewController: BaseViewController {
    @IBOutlet weak var segmentio: Segmentio!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bleSelf.getImagePushSettings()
        title = "dial_management".localized()
        
        // 配置Segmentio
        let market = SegmentioItem(title: "device_dial_mall".localized(), image: nil)
        let mine = SegmentioItem(title: "custom_watch_face".localized(), image: nil)
        
        let state = SegmentioStates(
            defaultState: SegmentioState(
                backgroundColor: .clear,
                titleFont: UIFont.systemFont(ofSize: 13),
                titleTextColor: UIColor(hex: 0x333333)
            ),
            selectedState: SegmentioState(
                backgroundColor: .clear,
                titleFont: UIFont.systemFont(ofSize: 13),
                titleTextColor: UIColor(hex: 0x333333)
            ),
            highlightedState: SegmentioState(
                backgroundColor: .clear,
                titleFont: UIFont.boldSystemFont(ofSize: 13),
                titleTextColor: UIColor(hex: 0x333333)
            )
        )
        
        let options = SegmentioOptions(
            backgroundColor: .clear,
            segmentPosition: SegmentioPosition.fixed(maxVisibleItems: 4),
            scrollEnabled: true,
            indicatorOptions: SegmentioIndicatorOptions(type: .bottom, ratio: 0.1, height: 2, color: .brand),
            horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(type: .none, height: 0, color: .clear),
            verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(ratio: 0, color: .clear),
            imageContentMode: .center,
            labelTextAlignment: .center,
            segmentStates: state
        )
        
        segmentio.setup(
            content: [market, mine],
            style: .onlyLabel,
            options: options
        )
        
        segmentio.selectedSegmentioIndex = 0
        segmentio.valueDidChange = { [weak self] _, segmentIndex in
            self?.switchToPage(segmentIndex)
        }
        
        // 配置ScrollView
        automaticallyAdjustsScrollViewInsets = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bounces = false
        scrollView.isScrollEnabled = false // 禁用手动滑动
        scrollView.delegate = self
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleStop), name: Notification.Name("UploadImageViewController"), object: nil)
        needStop = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleStop() {
        needStop = true
    }
    
    private func setupUI() {
        if contentView.subviews.count >= 2 {
            return
        }
        
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        var vc: UIViewController?
        
        if isXGZT {
            let controller = TripleTableViewController()
            controller.current = index
            contentView.addSubview(controller.view)
            addChild(controller)
            controller.view.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.width.equalTo(ScreenWidth)
                $0.top.bottom.equalToSuperview()
            }
            vc = controller
        } else {
            let marketClockVC = storyboard.instantiateViewController(withIdentifier: "MarketClockViewController") as! MarketClockViewController
            marketClockVC.current = index
            contentView.addSubview(marketClockVC.view)
            marketClockVC.bShowDetail = true
            addChild(marketClockVC)
            marketClockVC.view.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.width.equalTo(ScreenWidth)
                $0.top.bottom.equalToSuperview()
            }
            vc = marketClockVC
        }
        
        let myClockVC = storyboard.instantiateViewController(withIdentifier: "MyClockViewController") as! MyClockViewController
        myClockVC.index = index
        contentView.addSubview(myClockVC.view)
        addChild(myClockVC)
        myClockVC.view.snp.makeConstraints {
            $0.left.equalTo(vc!.view.snp.right)
            $0.width.equalTo(ScreenWidth)
            $0.top.bottom.equalToSuperview()
        }
        
        contentViewWidthConstraint.constant = ScreenWidth * 2
    }
    
    // 新增：切换页面的方法
    private func switchToPage(_ index: Int) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = CGPoint(x: ScreenWidth * CGFloat(index), y: 0)
        }
    }
}

extension ClockManageViewController: UIScrollViewDelegate {
    // 由于禁用了滑动，这些方法可以为空或移除
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}
}
