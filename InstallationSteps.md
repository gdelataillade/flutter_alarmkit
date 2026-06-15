# Installation Guide

Follow these steps to add `flutter_alarmkit` and set up a working Live Activity extension.

> **Note:** This plugin is still under development (beta). Installation steps are likely to evolve as AlarmKit and Flutter's iOS 26 support mature. If something doesn't work as described, please [open an issue](https://github.com/gdelataillade/flutter_alarmkit/issues).

## Using with Claude Code (optional)

This repo includes a Claude Code skill, **`flutter-alarmkit-setup`**, that automates the steps below: it runs the setup CLI, verifies the result, and tells you exactly when to do the two Xcode-GUI steps by hand. Copy the skill folder into your app once:

```bash
# from your Flutter app root
mkdir -p .claude/skills
git clone --depth 1 https://github.com/gdelataillade/flutter_alarmkit /tmp/flutter_alarmkit-skill
cp -R /tmp/flutter_alarmkit-skill/.claude/skills/flutter-alarmkit-setup .claude/skills/
rm -rf /tmp/flutter_alarmkit-skill
```

(If you already use a git or path dependency, copy `.claude/skills/flutter-alarmkit-setup/` straight from that checkout. Note it isn't inside the pub.dev package — pub omits dotfiles — so grab it from the repo.) Then open Claude Code in your project and say something like *"set up flutter_alarmkit"* — the skill takes it from there. The manual steps below remain the source of truth if you'd rather do it yourself.

## Names and versions that must match exactly

These values are load-bearing — the plugin's code and setup tooling reference them literally:

| What | Value | Why |
|---|---|---|
| Widget Extension name (in the Xcode wizard) | `AlarmkitWidget` | Xcode derives the target `AlarmkitWidgetExtension` and the folder `ios/AlarmkitWidget/` from it; the Podfile block and entitlements reference the derived name |
| App Group | `group.flutter-alarmkit` | Hardcoded in the plugin's Swift code; used to pass custom button colors to the widget via shared `UserDefaults` |
| Minimum runtime | iOS 26.0 device | AlarmKit is an iOS 26 framework (the app itself may target lower iOS versions and gate alarm features at runtime) |
| Toolchain | Xcode 26+, CocoaPods | The plugin supports Swift Package Manager too, but the Widget Extension setup below is CocoaPods-based |

Only two steps require the Xcode GUI (marked 🖐 below): creating the Widget Extension target and adding the App Groups capability. Everything else is automated by the setup CLI and verifiable with `dart run flutter_alarmkit:setup --doctor`.

---

## Quick Setup (Recommended)

### 1. Add the dependency

```bash
flutter pub add flutter_alarmkit
```

### 2. Create the Widget Extension target — 🖐 requires Xcode GUI

Open `ios/Runner.xcworkspace` in Xcode:

1. **File** > **New** > **Target**
2. Select **Widget Extension**
3. Name it exactly `AlarmkitWidget`
4. Check only **Live Activity** (uncheck any other options)
5. Click **Finish**, then confirm by clicking **Activate** if prompted

Don't worry about the Swift files Xcode generates (including extras like `AlarmkitWidgetControl.swift` or `AppIntent.swift` that some Xcode versions add anyway) — the next step replaces them with the plugin's files. With Xcode 16+ the target is a filesystem-synchronized folder, so files changed on disk appear in Xcode automatically; no dragging or manual file references are ever needed.

### 3. Configure App Groups — 🖐 requires Xcode GUI

While you're still in Xcode, for **both** the Runner and AlarmkitWidgetExtension targets:

1. Go to **Signing & Capabilities** > **+ Capability** > **App Groups**
2. Add `group.flutter-alarmkit`

This is required for custom button tint colors to work in the Live Activity. Adding the capability also wires the entitlements files into the build settings automatically.

> **Do all your Xcode work now** (steps 2 and 3). The setup command in step 4 must be the *last* thing to touch the project before `pod install` — see the note there for why.

### 4. Quit Xcode, then run the setup command

**Quit Xcode first (⌘Q).** This matters: Xcode 26 re-upgrades the project format (`objectVersion`) every time it saves the project — including when you create the target or add the App Groups capability — and CocoaPods can't parse the upgraded format. Running setup *after* all Xcode work, with Xcode closed, makes its fixes the last thing to touch the project, so they survive into `pod install`.

```bash
dart run flutter_alarmkit:setup
```

This automatically:

- Patches `Info.plist` with the required AlarmKit keys
- Patches `AppDelegate.swift` with `FlutterImplicitEngineDelegate`
- Patches `Podfile` with the widget extension target
- Writes the plugin's widget files into `ios/AlarmkitWidget/` (replacing the placeholders Xcode created with the target, and removing its extra generated files)
- Ensures `Runner.entitlements` contains the App Group
- Downgrades the project format if Xcode upgraded it to one CocoaPods can't parse yet (`objectVersion` 70/77 → 60, [CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840))
- Reorders the Runner build phases so the embed phases run before Flutter's `Thin Binary` (prevents the "Cycle inside Runner" build error)

The command is idempotent and self-healing — re-run it any time something looks off (e.g. after any further Xcode change). If you intentionally customized the widget Swift files, setup keeps your version and tells you; use `--force` to overwrite with the plugin templates.

### 5. Build and run

With Xcode still closed:

```bash
cd ios && pod install && cd ..
dart run flutter_alarmkit:setup --doctor
flutter run --release
```

`dart run flutter_alarmkit:setup --doctor` is a read-only check of every step above — it should report **all green**. If it flags **"Embed phases run after Thin Binary"** (`pod install` can append a build phase in the wrong spot), run `dart run flutter_alarmkit:setup` once more to reorder them, then `flutter run --release`. (Paste the doctor output when filing an issue.)

If the build fails with `Cycle inside Runner`, run `dart run flutter_alarmkit:setup` once more (`pod install` can append a build phase in the wrong position on its first run), then build again.

---

## Manual Setup

If you prefer to configure everything manually, follow these steps:

### 1. Add the dependency

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

### 3. Add a Live Activity Widget Extension — 🖐 requires Xcode GUI

In Xcode:
1. **File** > **New** > **Target**
2. Select **Widget Extension**
3. Name it exactly `AlarmkitWidget`
4. Check only **Live Activity** (uncheck any other options)
5. Click **Finish**, then confirm by clicking **Activate** if prompted

Some Xcode versions generate extra files anyway (`AlarmkitWidgetControl.swift`, `AppIntent.swift`) — delete those in the next step.

---

### 4. Add the Widget UI Code

Replace the content of the generated files in `ios/AlarmkitWidget/` **on disk** with the plugin's versions (the canonical sources live in the plugin repo under `ios/WidgetTemplates/`):

- [`AlarmkitWidget.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/ios/WidgetTemplates/AlarmkitWidget.swift)
- [`AlarmkitWidgetLiveActivity.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/ios/WidgetTemplates/AlarmkitWidgetLiveActivity.swift)
- [`AlarmkitWidgetBundle.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/ios/WidgetTemplates/AlarmkitWidgetBundle.swift)
- [`AppIntents.swift`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/ios/WidgetTemplates/AppIntents.swift) (new file)

Delete `AlarmkitWidgetControl.swift` and `AppIntent.swift` (singular) if Xcode generated them.

With Xcode 16+ the extension folder is filesystem-synchronized: editing files on disk is enough, no dragging into the project or target-membership changes needed. These files define how the alarm appears on the Lock Screen and Dynamic Island.

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

Optional: `pod install` warns "Automatically assigning platform iOS 13.0" when the Podfile's `platform :ios` line is commented out. You can uncomment it and set the minimum iOS your app supports to silence the warning (AlarmKit features need an iOS 26 device at runtime either way).

Here's the example app's [Podfile](https://github.com/gdelataillade/flutter_alarmkit/blob/main/example/ios/Podfile).

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

### 7. Configure App Groups — 🖐 requires Xcode GUI

For **both** the Runner and AlarmkitWidgetExtension targets:
1. Go to **Signing & Capabilities** > **+ Capability** > **App Groups**
2. Add `group.flutter-alarmkit`

This enables the main app to pass custom button tint colors to the widget extension via shared `UserDefaults`. Adding the capability also wires the entitlements files into the build settings automatically — if a build complains about missing entitlements, check **Build Settings** > **Code Signing Entitlements** points at them.

---

### 8. Fix the project format for CocoaPods

Creating the widget target in Xcode 16.3+/26 silently upgrades `ios/Runner.xcodeproj/project.pbxproj` to a format released CocoaPods versions can't parse, and `pod install` fails with:

```
ArgumentError - [Xcodeproj] Unable to find compatibility version string for object version `70`.
```

Open `ios/Runner.xcodeproj/project.pbxproj` and change `objectVersion = 70;` (or `77`) to `objectVersion = 60;`. Xcode still opens the project fine, but may re-upgrade the value on a later save — repeat the edit if the error returns ([CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840)).

---

### 9. Reorder build phases (required with Xcode 16.3+/26)

Xcode appends the extension's embed phase **after** Flutter's `Thin Binary` phase when it creates the widget target, which makes release builds fail with `Cycle inside Runner`. In Xcode:

- Select the **Runner** target
- Go to **Build Phases**
- Drag `[CP] Embed Pods Frameworks` and `Embed Foundation Extensions` **above** `Thin Binary`

(`[CP] Embed Pods Frameworks` only appears after the first `pod install`.)

### 10. Build and Run

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run --release
```

---

## Troubleshooting

Every entry below is a real error hit during installation testing, with the verified fix. The fastest path for most of them is:

```bash
dart run flutter_alarmkit:setup --doctor   # tells you what's broken
dart run flutter_alarmkit:setup            # fixes everything it can
```

**`pod install` fails with `Unable to find compatibility version string for object version '70'`**
Xcode 16.3+/26 upgraded the project format when you created the widget target, and released CocoaPods versions can't read it yet ([CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840)). `dart run flutter_alarmkit:setup` patches `objectVersion` back down to 60 — **but only on disk**. Xcode rewrites it to 70 every time it *saves* the project, so if you run setup and then do anything in Xcode (most commonly: adding the App Groups capability), the fix is undone before `pod install` runs. The reliable fix: do all Xcode work first, then **quit Xcode**, then run `dart run flutter_alarmkit:setup`, then `pod install` — all with Xcode closed. If the error returns, an Xcode save snuck in; quit it and re-run setup before `pod install`.

**Build fails with `Error (Xcode): Cycle inside Runner`**
Xcode added the extension's embed phases after Flutter's `Thin Binary` phase. Run `dart run flutter_alarmkit:setup` (it reorders the phases automatically), then build again. Manual alternative: Runner target > Build Phases > drag `Embed Foundation Extensions` and `[CP] Embed Pods Frameworks` **above** `Thin Binary`.

**The files in `ios/AlarmkitWidget/` look like Xcode sample code (emoji timer)**
Creating the widget target overwrote the plugin's widget files with Xcode placeholders. Run `dart run flutter_alarmkit:setup` — it detects the placeholders and restores the plugin's files, and removes Xcode's extra `AlarmkitWidgetControl.swift` / `AppIntent.swift`.

**`flutter run --release` says `Could not run build/ios/iphoneos/Runner.app`**
Usually the iPhone is locked — unlock it and retry. (The underlying `devicectl` error, "device was not, or could not be, unlocked", is hidden by Flutter.)

**Alarm fires but the Live Activity shows no custom colors/titles**
Check that the `group.flutter-alarmkit` App Group is enabled on **both** the Runner and AlarmkitWidgetExtension targets — the configuration travels via shared `UserDefaults`. `dart run flutter_alarmkit:setup --doctor` checks both entitlements files.

**Something else**
[Open an issue](https://github.com/gdelataillade/flutter_alarmkit/issues) and include: Flutter/Xcode/iOS versions, device model, steps to reproduce, error messages, and the output of `dart run flutter_alarmkit:setup --doctor`.

---

## Notes for AI agents

If you are an AI assistant setting this plugin up in a user's app:

- **Mental model:** `dart run flutter_alarmkit:setup` patches all config files, syncs the widget Swift files, and repairs known Xcode/CocoaPods breakage. It is idempotent — when in doubt, run it again. Verify state with `dart run flutter_alarmkit:setup --doctor` instead of inspecting Xcode.
- **Only two steps need a human in the Xcode GUI:** creating the `AlarmkitWidget` Widget Extension target (step 2) and adding the App Groups capability to both targets (step 4). Stop and hand off for those; do not attempt to create targets or add capabilities by editing `project.pbxproj`.
- **Never hand-write the widget Swift files** — they must match the plugin's `ios/WidgetTemplates/`; the setup command syncs them.
- The only `project.pbxproj` edits that are safe to script are the two the setup command already performs (`objectVersion` downgrade, build-phase reorder).
- Errors you may see and their one-command fix are in the Troubleshooting section above; match on the quoted error strings.
