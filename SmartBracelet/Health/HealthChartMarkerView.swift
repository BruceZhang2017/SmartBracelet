import UIKit
import Charts

final class HealthChartMarkerView: MarkerView {
    typealias MarkerDisplay = (title: String, value: String, detail: String?)

    private let contentInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
    private let chromeView = UIView()
    private let accentBarView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let detailLabel = UILabel()
    var formatter: ((ChartDataEntry) -> MarkerDisplay)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 8)

        chromeView.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        chromeView.layer.cornerRadius = 16
        chromeView.layer.cornerCurve = .continuous
        chromeView.layer.borderWidth = 1
        chromeView.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor

        accentBarView.backgroundColor = UIColor.brand.withAlphaComponent(0.92)
        accentBarView.layer.cornerRadius = 2
        
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor.text_secondary
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        subtitleLabel.textColor = UIColor.text_primary
        subtitleLabel.numberOfLines = 1

        detailLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        detailLabel.textColor = UIColor.text_secondary.withAlphaComponent(0.92)
        detailLabel.numberOfLines = 1
        
        [chromeView, accentBarView, titleLabel, subtitleLabel, detailLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(chromeView)
        chromeView.addSubview(accentBarView)
        chromeView.addSubview(titleLabel)
        chromeView.addSubview(subtitleLabel)
        chromeView.addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            chromeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chromeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chromeView.topAnchor.constraint(equalTo: topAnchor),
            chromeView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentBarView.leadingAnchor.constraint(equalTo: chromeView.leadingAnchor, constant: contentInsets.left),
            accentBarView.topAnchor.constraint(equalTo: chromeView.topAnchor, constant: 11),
            accentBarView.widthAnchor.constraint(equalToConstant: 28),
            accentBarView.heightAnchor.constraint(equalToConstant: 4),

            titleLabel.leadingAnchor.constraint(equalTo: chromeView.leadingAnchor, constant: contentInsets.left),
            titleLabel.trailingAnchor.constraint(equalTo: chromeView.trailingAnchor, constant: -contentInsets.right),
            titleLabel.topAnchor.constraint(equalTo: accentBarView.bottomAnchor, constant: 7),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 3),
            detailLabel.bottomAnchor.constraint(equalTo: chromeView.bottomAnchor, constant: -contentInsets.bottom)
        ])
        
        offset = CGPoint(x: -68, y: -78)
    }
    
    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let formatted = formatter?(entry) ?? ("", "\(Int(entry.y.rounded()))", nil)
        titleLabel.text = formatted.0
        subtitleLabel.text = formatted.1
        detailLabel.text = formatted.2
        detailLabel.isHidden = (formatted.2?.isEmpty ?? true)
        layoutIfNeeded()
        
        let titleSize = titleLabel.sizeThatFits(CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude))
        let subtitleSize = subtitleLabel.sizeThatFits(CGSize(width: 220, height: CGFloat.greatestFiniteMagnitude))
        let detailSize = detailLabel.isHidden ? .zero : detailLabel.sizeThatFits(CGSize(width: 220, height: CGFloat.greatestFiniteMagnitude))
        let width = max(titleSize.width, subtitleSize.width, detailSize.width) + contentInsets.left + contentInsets.right
        let height = titleSize.height + subtitleSize.height + detailSize.height + contentInsets.top + contentInsets.bottom + (detailLabel.isHidden ? 11 : 14)
        frame.size = CGSize(width: max(width, 122), height: max(height, detailLabel.isHidden ? 72 : 84))
    }
}
