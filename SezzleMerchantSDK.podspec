Pod::Spec.new do |s|
  s.name             = 'SezzleMerchantSDK'
  s.version          = '1.2.0'
  s.summary          = 'Sezzle checkout SDK for iOS merchant apps.'
  s.description      = <<-DESC
    Native iOS SDK that lets merchant apps offer Sezzle buy-now-pay-later
    at checkout. Configure with your public key, present checkout, and
    receive an order UUID on completion. Includes promotional messaging
    widgets for product and cart pages.
  DESC

  s.homepage         = 'https://github.com/sezzle/sezzle-merchant-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sezzle' => 'dev@sezzle.com' }
  s.source           = { :git => 'https://github.com/sezzle/sezzle-merchant-sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version    = '6.2'

  s.source_files     = 'Sources/SezzleMerchantSDK/**/*.swift'
  s.resource_bundles = { 'SezzleMerchantSDK' => ['Sources/SezzleMerchantSDK/Resources/**/*'] }

  s.frameworks       = 'UIKit', 'AuthenticationServices'
end
