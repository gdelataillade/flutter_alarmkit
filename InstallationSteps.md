# Installation Guide

Follow these steps to add `flutter_alarmkit` and set up a working Live Activity extension:

---

### 1. Add the dependency

Run in your project root:

```bash
flutter pub add flutter_alarmkit
```

---

### 2. Configure Info.plist

Open `ios/Runner/Info.plist` and add the following keys inside the `<dict>` element:

```xml
<!-- Required: AlarmKit usage description -->
<key>NSAlarmKitUsageDescription</key>
<string>This app uses alarms to notify you even when your device is locked.</string>

<!-- Required: Enable Live Activities -->
<key>NSSupportsLiveActivities</key>
<true/>

<!-- Required for AlarmKit local network communication -->
<key>NSBonjourServices</key>
<array>
    <string>_alarmkit._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to the local network to discover and connect to alarm devices.</string>

<!-- Required for iOS 26 scene-based lifecycle -->
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>UIWindowScene</string>
                <key>UISceneConfigurationName</key>
                <string>flutter</string>
                <key>UISceneDelegateClassName</key>
                <string>FlutterSceneDelegate</string>
                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

See the full example: [Info.plist](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/Runner/Info.plist)

---

### 3. Add a Live Activity Widget Extension

In Xcode:
1. **File** > **New** > **Target**
2. Select **Widget Extension**
3. Name it `AlarmkitWidget`
4. Check only **Live Activity**
5. Click **Finish**, then confirm by clicking **Activate** if prompted

---

### 4. Add the Widget UI Code

Replace the generated files with the following files provided by the plugin:
- [`AlarmkitWidget.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/AlarmkitWidget/AlarmkitWidget.swift)
- [`AlarmkitWidgetLiveActivity.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/AlarmkitWidget/AlarmkitWidgetLiveActivity.swift)
- [`AlarmkitWidgetBundle.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/AlarmkitWidget/AlarmkitWidgetBundle.swift)

Also add [`AppIntents.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/AlarmkitWidget/AppIntents.swift) to the same `AlarmkitWidget` folder.

These files define how the alarm appears on the Lock Screen and Dynamic Island.

---

### 5. Update Podfile

Open `ios/Podfile` and make sure it contains:

```ruby
target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Add this block
  target 'AlarmkitWidgetExtension' do
    inherit! :search_paths
    use_frameworks!
    pod 'flutter_alarmkit', :path => '.symlinks/plugins/flutter_alarmkit/ios'
  end
end
```

Here's example app's [Podfile](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/Podfile).

### 6. Update AppDelegate.swift

Open `ios/Runner/AppDelegate.swift` and update it to implement `FlutterImplicitEngineDelegate`. This is required for iOS 26 to properly register plugins when the app is launched implicitly by the system (e.g., when an alarm fires):

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

---

### 7. Reorder build phases (might not be needed)

In Xcode:
- Select the **Runner** target
- Go to **Build Phases**
- `[CP] Embed Pods Frameworks` and `Embed Foundation Extensions` should be above `Thin Binary`.


### 8. Build and Run

Then run:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run --release
```

## Troubleshooting

Open an issue if you encounter any problems. Please provide the following information:

- Flutter version
- Xcode version
- iOS version
- Device model
- Steps to reproduce the issue
- Error messages
- Any relevant logs
