source 'https://github.com/CocoaPods/Specs.git'
platform :ios,          '8.1'

# Networking and resources
pod 'AFNetworking',     '~> 2.6.0'
pod 'FLAnimatedImage', '~> 1.0'
pod 'SDWebImage', '~> 3.7'
pod 'PINRemoteImage', '~> 1.2',                  :inhibit_warnings => true
pod 'AWSS3', '~> 2.2',                  :inhibit_warnings => true

# GUI & Players
pod 'AFSoundManager',                   :inhibit_warnings => true
pod 'Toast', '~> 2.4'
pod 'JDFTooltips', '~> 1.0',            :inhibit_warnings => true
pod 'JGActionSheet', '~> 1.0'
pod 'SIAlertView', '~> 1.3',            :inhibit_warnings => true

# Reporting and experiments
pod 'Mixpanel', '~> 2.8.0',             :inhibit_warnings => true
pod 'Fabric'
pod 'Crashlytics'
pod 'Optimizely-iOS-SDK'

# General
pod 'RegExCategories', '~> 1.0'
pod 'iRate', '~> 1.11'

# Facebook
pod 'FBSDKCoreKit', '~> 4.6'
pod 'FBSDKMessengerShareKit', '~> 1.3'

# Debugging
pod 'NSLogger', '~> 1.5'
pod 'MBProgressHUD', '~> 0.9'

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end