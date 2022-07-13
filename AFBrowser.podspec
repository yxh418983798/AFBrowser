#
# Be sure to run `pod lib lint AFBrowser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AFBrowser'
  s.version          = '2.0.5'
  s.summary          = '图片/视频浏览器'
  s.description      = <<-DESC
  1、视频播放器重构
                       DESC
  s.homepage         = 'https://github.com/yxh418983798/AFBrowser'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alfie' => '418983798@qq.com' }
  s.source           = { :git => 'https://github.com/yxh418983798/AFBrowser.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'AFBrowser/Classes/**/*'
  s.dependency 'SDWebImage'
  s.dependency 'YYImage'
  s.resource_bundles = {
   'AFBrowser' => ['AFBrowser/Assets/*']
  }
    
end
