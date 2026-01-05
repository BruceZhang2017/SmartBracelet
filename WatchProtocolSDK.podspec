Pod::Spec.new do |s|
  s.name             = 'WatchProtocolSDK'
  s.version          = '1.0.1'
  s.summary          = 'A Swift SDK for watch device protocol communication and health data management.'
  s.description      = <<-DESC
                       WatchProtocolSDK provides a comprehensive solution for communicating with smart watch devices via Bluetooth.
                       It includes:
                       - Bluetooth connection management
                       - Device command handling
                       - Health data synchronization (steps, sleep, heart rate, blood oxygen, blood pressure)
                       - Protocol-based data storage interface
                       - Modular architecture for easy integration
                       DESC

  s.homepage         = 'https://github.com/Xiaotengzxf/HuaXinSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Xiaotengzxf' => '315082431@qq.com' }
  s.source           = { :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'WatchProtocolSDK/**/*.swift'

  s.frameworks = 'Foundation', 'CoreBluetooth'

  # Dependencies
  s.dependency 'SwiftyJSON'
  s.dependency 'CryptoSwift'

end
