platform:ios,'10.0'

use_frameworks!

target 'SmartBracelet' do
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/aliyun/aliyun-specs.git'
pod 'AFNetworking'
pod 'AMap2DMap'
pod 'AMapLocation'
pod 'SnapKit','5.0.1'
pod 'Segmentio'
pod 'Then'
pod 'ProgressHUD'
pod 'Toaster', :git => 'https://github.com/devxoul/Toaster.git', :branch => 'master'
pod 'CountryPickerView'
pod 'IQKeyboardManagerSwift', '6.3.0'
#pod 'NVActivityIndicatorView'
pod 'Alamofire', '~> 5.4.4'
pod 'Kingfisher'
pod 'XCGLogger'
pod 'RealmSwift', '~> 10.13.0'
pod 'Realm', '~> 10.13.0'
pod 'Toast'
pod 'MJRefresh'
pod 'AMapSearch'
pod 'YYImage'
pod 'TZImagePickerController'
pod 'Bugly'
pod 'HandyJSON'
pod 'Moya'
pod 'SDWebImage'
#pod 'FLAnimatedImage'

pod 'SwiftyBeaver'
pod 'SwiftyJSON'
pod 'RxSwift'

pod 'CryptoSwift'
pod 'IotLinkKit', '1.2.1'
pod 'RxBluetoothKit'

  post_install do |installer|
    #调用移除函数
    remove_swift_ui()
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] ='NO'
        config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'NO'
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end

end


# 添加以下函数
def remove_swift_ui
  system("rm -rf ./Pods/Kingfisher/Sources/SwiftUI")
  code_file = "./Pods/Kingfisher/Sources/General/KFOptionsSetter.swift"
  code_text = File.read(code_file)
  code_text.gsub!(/#if canImport\(SwiftUI\) \&\& canImport\(Combine\)(.|\n)+#endif/,'')
  system("rm -rf " + code_file)
  aFile = File.new(code_file, 'w+')
  aFile.syswrite(code_text)
  aFile.close()
end
