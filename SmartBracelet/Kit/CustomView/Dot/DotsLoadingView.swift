//
//  DotsLoadingView.swift
//  Dots 
//
//  Created by 母利睦人 on 2017/05/11.
//  Copyright © 2017年 makomori. All rights reserved.
//

import UIKit

public class DotsLoadingView: UIView {
    private let delay = 0.25
    private let length = 6
    
    public let loadingViewBackgroundColor = UIColor.white
    
    private let color1 = UIColor.hexStr(hexStr: "#EAEAEA", alpha: 1.0)
    private let color2 = UIColor.hexStr(hexStr: "#CBE6DA", alpha: 1.0)
    private let color3 = UIColor.hexStr(hexStr: "#AEE1CB", alpha: 1.0)
    private let color4 = UIColor.hexStr(hexStr: "#92DCBB", alpha: 1.0)
    private let color5 = UIColor.hexStr(hexStr: "#77D6AD", alpha: 1.0)
    private let color6 = UIColor.hexStr(hexStr: "#5ED29E", alpha: 1.0)
    private let color7 = UIColor.hexStr(hexStr: "#48CD91", alpha: 1.0)
    private let color8 = UIColor.hexStr(hexStr: "#34D282", alpha: 1.0)
    public var colors: [UIColor] = []
    private var dots: [DotView] = []
    
    public init(colors: [UIColor]?) {
        super.init(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        self.backgroundColor = UIColor.clear
        self.colors = [color1, color2, color3, color4, color5, color6, color7, color8]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        startAnimation()
    }
    
    public func stop() {
        if #available(iOS 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                for dot in self.dots {
                    dot.alpha = 0
                }
            }
            animator.startAnimation()
            animator.addCompletion { _ in
                self.removeFromSuperview()
            }
        } else {
            // Fallback on earlier versions
            print("It's only availabel from iOS 10")
        }
    }
    
    private func startAnimation() {
        for i in 0..<colors.count {
            let dotFrame = CGRect(x: 0, y: 0, width: CGFloat(length), height: CGFloat(length))
            let dot = DotView(color: colors[i], delay: self.delay*Double(i), frame: dotFrame)
            dot.center = CGPoint(x: self.frame.width/16 + CGFloat(i)*self.frame.width/8, y: self.frame.height/2)
            dots.append(dot)
            self.addSubview(dot)
        }
    }
}
