//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MRGCDTimer.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

typealias ActionBlock = () -> ()

class MRGCDTimer: NSObject {
  
  static let share = MRGCDTimer()
  
  lazy var timerContainer = [String : DispatchSourceTimer]()
  
  
  /// 创建一个名字为name的定时
  ///
  /// - Parameters:
  ///  - name: 定时器的名字
  ///  - timeInterval: 时间间隔
  ///  - queue: 线程
  ///  - repeats: 是否重复
  ///  - action: 执行的操作
  func scheduledDispatchTimer(withName name:String?, timeInterval:Double, queue:DispatchQueue, repeats:Bool, action:@escaping ActionBlock ) {
    if name == nil {
      return
    }
    var timer = timerContainer[name!]
    if timer==nil {
      timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
      timer?.resume()
      timerContainer[name!] = timer
    }
    timer?.schedule(deadline: .now(), repeating: timeInterval, leeway: .milliseconds(100))
    timer?.setEventHandler(handler: { [weak self] in
      action()
      if repeats==false {
        self?.destoryTimer(withName: name!)
      }
    })
    
  }
  
  
  /// 销毁名字为name的计时器
  ///
  /// - Parameter name: 计时器的名字
  func destoryTimer(withName name:String?) {
    let timer = timerContainer[name!]
    if timer == nil {
      return
    }
    timerContainer.removeValue(forKey: name!)
    timer?.cancel()
  }
  
  
  /// 检测是否已经存在名字为name的计时器
  ///
  /// - Parameter name: 计时器的名字
  /// - Returns: 返回bool值
  func isExistTimer(withName name:String?) -> Bool {
    if timerContainer[name!] != nil {
      return true
    }
    return false
  }

}

/*
 MRGCDTimer.share.scheduledDispatchTimer(withName: "name", timeInterval: 1, queue: .main, repeats: true) {
  //code
   self.updateCounter()
}
 MRGCDTimer.share.destoryTimer(withName: "name")
 */
