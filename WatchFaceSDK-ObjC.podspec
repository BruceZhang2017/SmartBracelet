Pod::Spec.new do |s|
  s.name             = 'WatchFaceSDK-ObjC'
  s.version          = '1.0.0'
  s.summary          = 'XGZT 协议智能手表表盘管理 SDK - Objective-C 版本'
  s.description      = <<-DESC
                       WatchFaceSDK-ObjC 是 WatchFaceSDK 的 Objective-C 兼容层,为 Objective-C 项目提供完整的表盘管理功能。

                       主要功能:
                       - 市场表盘上传
                       - 自定义表盘制作和上传
                       - 智能图片处理(裁剪、压缩、PAR 转换)
                       - 圆形/方形屏幕自动适配
                       - 实时传输进度监控
                       DESC

  s.homepage         = 'https://github.com/BruceZhang2017/SmartBracelet'
  s.license          = { :type => 'Copyright', :text => 'Copyright © 2026 bruce Innovations. All rights reserved.' }
  s.author           = { 'bruce' => '315082431@qq.com' }
  s.source           = { :git => 'https://github.com/BruceZhang2017/SmartBracelet.git', :tag => "WatchFaceSDK-ObjC-#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.9'

  # 源文件
  s.source_files = 'WatchFaceSDK-ObjC/**/*.{h,m,swift}'
  s.public_header_files = [
    'WatchFaceSDK-ObjC/WatchFaceSDK-ObjC.h',
    'WatchFaceSDK-ObjC/Models/*.h',
    'WatchFaceSDK-ObjC/Protocols/*.h',
    'WatchFaceSDK-ObjC/Core/WFManager.h'
  ]

  # 排除示例代码
  s.exclude_files = 'WatchFaceSDK-ObjC/Examples/**/*'

  # 框架依赖
  s.frameworks = 'Foundation', 'UIKit', 'CoreGraphics', 'CoreBluetooth'

  # SDK 依赖
  s.dependency 'WatchProtocolSDK-ObjC', '~> 1.0'

  # 注意: WatchFaceSDK 和 ABParTool 需要手动添加
  # s.dependency 'WatchFaceSDK', '~> 1.0'
  # s.vendored_frameworks = 'ABParTool.xcframework'

  # 编译设置
  s.requires_arc = true
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.9',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }

end
