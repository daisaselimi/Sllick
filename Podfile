# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'xChat' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for xChat
  
   pod 'Firebase/Database'
  #pod 'Firebase/Core'
   pod 'FirebaseCore'
   pod 'Firebase/Auth'
   pod 'Firebase/Storage'
   pod 'Firebase/Firestore'
  
  pod 'ProgressHUD'
  pod 'MBProgressHUD'
  pod 'IQAudioRecorderController'
  
  pod 'JSQMessagesViewController', '7.3.3'
  pod 'IDMPhotoBrowser'
  pod 'RNCryptor'
  pod 'ImagePicker'
  pod 'TextFieldEffects'
  pod 'SKPhotoBrowser'
  pod 'AMPopTip'
  pod 'FlagPhoneNumber'
  
  pod 'OneSignal'
  pod 'SinchRTC'
  pod 'DZNEmptyDataSet'

  pod 'NVActivityIndicatorView'
pod 'GradientLoadingBar', '~> 2.0'
pod 'GSMessages'
pod 'ReachabilitySwift'

target 'OneSignalNotificationServiceExtension' do
use_frameworks!
  pod 'OneSignal', '>= 2.11.2', '< 3.0'
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
     end
  end
end

end
