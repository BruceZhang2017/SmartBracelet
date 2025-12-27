Pod::Spec.new do |spec|
  # 基本信息
  spec.name         = "WatchProtocolSDK"
  spec.version      = "1.0.0"
  spec.summary      = "自研手表蓝牙通信协议 SDK"
  spec.description  = <<-DESC
    WatchProtocolSDK 是一个用于自研手表设备的蓝牙通信协议 SDK。
    提供设备扫描、连接、数据同步、健康数据管理等功能。

    主要特性：
    - 蓝牙设备扫描和连接
    - 设备数据同步
    - 健康数据管理（步数、心率、血氧、血压、睡眠）
    - 线程安全的状态管理
    - 自动持久化
    - OTA 固件升级支持
  DESC

  # 主页和许可
  spec.homepage     = "https://github.com/yourcompany/WatchProtocolSDK"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  # 作者信息
  spec.author       = { "Your Company" => "developer@yourcompany.com" }

  # 平台要求
  spec.platform     = :ios, "12.0"
  spec.ios.deployment_target = "12.0"

  # 源代码位置
  spec.source       = {
    :git => "https://github.com/yourcompany/WatchProtocolSDK.git",
    :tag => "#{spec.version}"
  }

  # Swift 版本
  spec.swift_version = "5.0"

  # 源文件
  spec.source_files  = "WatchProtocolSDK/**/*.{swift,h,m}"
  spec.public_header_files = "WatchProtocolSDK/WatchProtocolSDK.h"

  # 资源文件（如果有）
  # spec.resources = "WatchProtocolSDK/Resources/**/*"

  # 系统框架依赖
  spec.frameworks = "Foundation", "CoreBluetooth", "UIKit"

  # 第三方库依赖
  spec.dependency "RealmSwift", "~> 10.0"

  # 其他设置
  spec.requires_arc = true
  spec.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }

  # 子模块（可选，如果要分模块发布）
  # spec.subspec 'Core' do |core|
  #   core.source_files = 'WatchProtocolSDK/Core/**/*.swift'
  # end

  # spec.subspec 'Models' do |models|
  #   models.source_files = 'WatchProtocolSDK/Models/**/*.swift'
  #   models.dependency 'WatchProtocolSDK/Core'
  # end

  # spec.subspec 'Utils' do |utils|
  #   utils.source_files = 'WatchProtocolSDK/Utils/**/*.swift'
  # end
end
