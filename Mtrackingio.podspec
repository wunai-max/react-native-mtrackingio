require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "Mtrackingio"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/wunai-max/react-native-mtrackingio.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm}"
  s.vendored_frameworks = "ios/TrackingIOSDK.xcframework"

  # 热云 TrackingIO iOS SDK 必需系统依赖
  # 强链接：所有支持 iOS 版本均存在的系统 framework
  s.frameworks = [
    "Security",
    "CoreTelephony",
    "AdSupport",
    "SystemConfiguration",
    "CoreMotion",
    "AVFoundation",
    "CFNetwork",
    "WebKit"
  ]
  # 弱链接：AdServices 仅在 iOS 14.3+ 提供（Apple Search Ads 归因）
  s.weak_frameworks = ["AdServices"]
  # 动态库 / TBD（podspec 用名字，去掉 lib 前缀和扩展名）
  s.libraries = ["sqlite3", "z", "resolv", "resolv.9", "c++"]

  s.dependency "React-Core"
end
