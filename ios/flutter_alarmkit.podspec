#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_alarmkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_alarmkit'
  s.version          = '0.3.0'
  s.summary          = 'Flutter plugin wrapping Apple AlarmKit (iOS 26+) with Live Activity alarms.'
  s.description      = <<-DESC
Schedule one-shot, countdown, and recurrent AlarmKit alarms that present as Live
Activities on the Lock Screen and Dynamic Island, with customizable buttons and titles.
                       DESC
  s.homepage         = 'https://github.com/gdelataillade/flutter_alarmkit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Gautier de Lataillade' => 'gautier@levinriegner.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_alarmkit/Sources/flutter_alarmkit/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # The plugin reads/writes shared UserDefaults (a required-reason API) to pass button
  # tint colors to the Live Activity widget, so it ships a privacy manifest. For more
  # information, see
  # https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'flutter_alarmkit_privacy' => ['flutter_alarmkit/Sources/flutter_alarmkit/PrivacyInfo.xcprivacy']}
end
