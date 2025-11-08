//
//  KRLShimmerView.swift
//  滑动解锁
//
//  Created by karl on 2017/07/31.
//  Copyright © 2017年 Karl. All rights reserved.
//

import UIKit

private let KRLShimmerViewAnimationKey = "locations"

class KRLShimmerView: UIView {

  var text = "" {
    didSet {
      label.text = text
    }
  }
  
  var font = UIFont.systemFont(ofSize: 12) {
    didSet {
      label.font = font
    }
  }
  
  var textColor = UIColor.black {
    didSet {
      contentLayer.backgroundColor = textColor.cgColor
    }
  }
  
  var shimmerColors = [UIColor.white, UIColor.white] {  // 最少两个元素, 跟 `shimmerImage` 只能设置一个
    didSet {
      shimmerLayer.contents = nil
      shimmerLayer.colors = shimmerColors.map({ $0.cgColor })
    }
  }
  
  var shimmerImage = UIImage(named: "gradient") {  // 跟 `shimmerColors` 只能设置一个
    didSet {
      shimmerLayer.colors = nil
      shimmerLayer.contents = shimmerImage?.cgImage
    }
  }
  
  var duration: CFTimeInterval = 2.5 {
    didSet {
      createAnimation()
    }
  }
  
  private lazy var contentLayer: CALayer = {
    let layer = CALayer()
    layer.backgroundColor = self.textColor.cgColor
    layer.bounds = self.bounds
    layer.anchorPoint = CGPoint.zero
    self.layer.addSublayer(layer)
    layer.mask = self.label.layer
    return layer
  }()
  
  private lazy var shimmerLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    layer.bounds = self.bounds
    layer.colors = self.shimmerColors.map({ $0.cgColor })
    layer.anchorPoint = CGPoint.zero
    layer.startPoint = CGPoint(x: 0, y: 0.5)
    layer.endPoint = CGPoint(x: 1, y: 0.5)
    self.contentLayer.addSublayer(layer)
    return layer
  }()
  
  private lazy var label: UILabel = {
    let label = UILabel(frame: self.bounds)
    label.text = "> 向右滑动解锁"
    label.font = UIFont.boldSystemFont(ofSize: 25)
    label.textAlignment = .center
    self.addSubview(label)
    return label
  }()
  
  private let gradientLayer = CAGradientLayer()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    create()
  }
  
  private func create() {
    gradientLayer.bounds = bounds
    gradientLayer.anchorPoint = CGPoint.zero
    gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    gradientLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
    gradientLayer.locations = [0.2, 0.5, 0.8]
    contentLayer.addSublayer(gradientLayer)
    shimmerLayer.mask = gradientLayer
    // ---
    createAnimation()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()

    // 更新所有layer和label的bounds
    label.frame = bounds
    contentLayer.bounds = bounds
    shimmerLayer.bounds = bounds
    gradientLayer.bounds = bounds

    // 如果view显示中且bounds有效，自动创建/更新动画
    if !isHidden && bounds.width > 0 && bounds.height > 0 {
      createAnimation()
    }
  }

  func createAnimation() {
    // 只有在bounds有效时才创建动画
    guard bounds.width > 0 && bounds.height > 0 else { return }

    gradientLayer.removeAllAnimations()
    let animation = CABasicAnimation(keyPath: KRLShimmerViewAnimationKey)
    animation.fromValue = [0, 0, 0.2]
    animation.toValue = [0.8, 1, 1]
    animation.duration = duration
    animation.repeatCount = HUGE
    gradientLayer.add(animation, forKey: nil)
  }

    func removreAnimation() {
        gradientLayer.removeAllAnimations()
    }

  private init() {
    super.init(frame: CGRect.zero)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
