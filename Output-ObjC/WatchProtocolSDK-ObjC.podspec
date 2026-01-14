Pod::Spec.new do |s|
  s.name             = 'WatchProtocolSDK-ObjC'
  s.version          = '1.0.0'
  s.summary          = 'An Objective-C SDK for watch device protocol communication and health data management.'
  s.description      = <<-DESC
                       WatchProtocolSDK-ObjC provides a comprehensive solution for communicating with smart watch devices via Bluetooth.
                       It includes:
                       - Bluetooth connection management
                       - Device command handling
                       - Health data synchronization (steps, sleep, heart rate, blood oxygen, blood pressure)
                       - Protocol-based data storage interface
                       - Modular architecture for easy integration
                       - Pure Objective-C implementation for maximum compatibility
                       DESC

  s.homepage         = 'https://github.com/Xiaotengzxf/HuaXinSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Xiaotengzxf' => '315082431@qq.com' }
  s.source           = { :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'

  # 源文件
  s.source_files = 'WatchProtocolSDK-ObjC/**/*.{h,m}'

  # 公开头文件
  s.public_header_files = 'WatchProtocolSDK-ObjC/**/*.h'

  # 系统框架依赖
  s.frameworks = 'Foundation', 'CoreBluetooth'

  # 编译选项
  s.requires_arc = YES

  # 模块名称
  s.module_name = 'WatchProtocolSDK'
end
