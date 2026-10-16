# Installation Guide

Follow these steps to add `flutter_alarmkit` and set up a working Live Activity extension.

> **Note:** This plugin is still under development (beta). Installation steps are likely to evolve as AlarmKit and Flutter's iOS 26 support mature. If something doesn't work as described, please [open an issue](https://github.com/gdelataillade/flutter_alarmkit/issues).

## Using with Claude Code (optional)

This repo includes a Claude Code skill, **`flutter-alarmkit-setup`**, that automates the steps below: it runs the setup CLI, verifies the result, and tells you exactly when to do the one Xcode-GUI step by hand. Copy the skill folder into your app once:

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
| Widget Extension name (in the Xcode wizard) | `AlarmkitWidget` | Xcode derives the target `AlarmkitWidgetExtension` and the folder `ios/AlarmkitWidget/` from it; the setup checks reference the derived name |
| Minimum runtime | iOS 26.0 device | AlarmKit is an iOS 26 framework (the app itself may target lower iOS versions and gate alarm features at runtime) |
| Flutter | 3.38.0+ | The `AppDelegate.swift` patch implements `FlutterImplicitEngineDelegate`, introduced in Flutter 3.38 |
| Toolchain | Xcode 26+ | Works with both Swift Package Manager and CocoaPods — the Widget Extension needs no `Podfile` changes |

Only one step requires the Xcode GUI (marked 🖐 below): creating the Widget Extension target. No App Group or other capability is needed. Everything else is automated by the setup CLI and verifiable with `dart run flutter_alarmkit:setup --doctor`.

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

> **Do all your Xcode work now.** The setup command in step 3 must be the *last* thing to touch the project before you build — see the note there for why.

### 3. Quit Xcode, then run the setup command

**Quit Xcode first (⌘Q).** This matters: Xcode 26 re-upgrades the project format and re-orders build phases every time it saves the project — including when you create the target. Running setup *after* all Xcode work, with Xcode closed, makes its fixes the last thing to touch the project, so they survive into the build. (The project-format downgrade only matters if you use CocoaPods; the build-phase fix matters either way.)

```bash
dart run flutter_alarmkit:setup
```

This automatically:

- Patches `Info.plist` with the required AlarmKit keys
- Patches `AppDelegate.swift` with `FlutterImplicitEngineDelegate`
- Writes the plugin's widget files into `ios/AlarmkitWidget/` (replacing the placeholders Xcode created with the target or untouched copies from an earlier plugin version, and removing Xcode's extra generated files)
- Removes the `group.flutter-alarmkit` App Group that plugin versions ≤ 0.4.x added to your entitlements (no longer used; it breaks code signing)
- Downgrades the project format if Xcode upgraded it to one CocoaPods can't parse yet (`objectVersion` 70/77 → 60, [CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840))
- Reorders the Runner build phases so the embed phases run before Flutter's `Thin Binary` (prevents the "Cycle inside Runner" build error)

The command is idempotent and self-healing — re-run it any time something looks off (e.g. after any further Xcode change). If you intentionally customized the widget Swift files, setup keeps your version and tells you; use `--force` to overwrite with the plugin templates.

### 4. Build and run

With Xcode still closed (run `pod install` only if your app uses CocoaPods — skip it on Swift Package Manager):

```bash
cd ios && pod install && cd ..   # CocoaPods only
dart run flutter_alarmkit:setup --doctor
flutter run --release
```

`dart run flutter_alarmkit:setup --doctor` is a read-only check of every step above — it should report **all green**. If it flags **"Embed phases run after Thin Binary"** (creating the widget target or `pod install` can append a build phase in the wrong spot), run `dart run flutter_alarmkit:setup` once more to reorder them, then `flutter run --release`. (Paste the doctor output when filing an issue.)

If the build fails with `Cycle inside Runner`, run `dart run flutter_alarmkit:setup` once more (creating the widget target or `pod install` can append a build phase in the wrong position), then build again.

---

## Upgrading from 0.4.x or earlier

0.5.0 removes the App Group requirement ([#21](https://github.com/gdelataillade/flutter_alarmkit/issues/21)): button tint colors and the stop button now travel to the widget in the alarm's metadata, so the widget template changed.

1. Upgrade the package (`flutter pub upgrade flutter_alarmkit`, or bump the constraint to `^0.5.0`).
2. Quit Xcode, then run `dart run flutter_alarmkit:setup`. It:
   - updates every file in `ios/AlarmkitWidget/` that is an untouched copy of an earlier plugin template;
   - keeps files you customized, and warns if one still reads the old App Group. Port your changes onto the new template; `--force` resets the files first;
   - removes `group.flutter-alarmkit` from `Runner.entitlements` and the widget extension's entitlements.
3. Optional: in Xcode, delete the **App Groups** capability from both targets if nothing else in your app uses it. Then quit Xcode and run setup once more, since saving the project in Xcode can undo its project-file fixes.
4. Run `dart run flutter_alarmkit:setup --doctor`, then rebuild (`pod install` first on CocoaPods).

Alarms scheduled before the upgrade keep the default button colors and stop button until they are rescheduled. Their `getAlarms()` label, tint and metadata are migrated automatically.

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
- [`PrivacyInfo.xcprivacy`](https://github.com/gdelataillade/flutter_alarmkit/blob/main/ios/WidgetTemplates/PrivacyInfo.xcprivacy) (new file — the widget's privacy manifest)

Delete `AlarmkitWidgetControl.swift` and `AppIntent.swift` (singular) if Xcode generated them.

With Xcode 16+ the extension folder is filesystem-synchronized: editing files on disk is enough, no dragging into the project or target-membership changes needed. These files define how the alarm appears on the Lock Screen and Dynamic Island.

---

### 5. Podfile — no changes needed

The Widget Extension is a standalone WidgetKit target with no plugin dependency, so it needs no `Podfile` entry. If your app uses CocoaPods, the standard Flutter `Podfile` is enough — run `pod install` as usual. If your app uses Swift Package Manager, you don't need a `Podfile` at all.

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

### 7. Fix the project format for CocoaPods

Creating the widget target in Xcode 16.3+/26 silently upgrades `ios/Runner.xcodeproj/project.pbxproj` to a format released CocoaPods versions can't parse, and `pod install` fails with:

```
ArgumentError - [Xcodeproj] Unable to find compatibility version string for object version `70`.
```

Open `ios/Runner.xcodeproj/project.pbxproj` and change `objectVersion = 70;` (or `77`) to `objectVersion = 60;`. Xcode still opens the project fine, but may re-upgrade the value on a later save — repeat the edit if the error returns ([CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840)).

---

### 8. Reorder build phases (required with Xcode 16.3+/26)

Xcode appends the extension's embed phase **after** Flutter's `Thin Binary` phase when it creates the widget target, which makes release builds fail with `Cycle inside Runner`. In Xcode:

- Select the **Runner** target
- Go to **Build Phases**
- Drag `[CP] Embed Pods Frameworks` and `Embed Foundation Extensions` **above** `Thin Binary`

(`[CP] Embed Pods Frameworks` only appears after the first `pod install`.)

### 9. Build and Run

```bash
flutter clean
flutter pub get
cd ios
pod install   # CocoaPods only — skip on Swift Package Manager
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
Xcode 16.3+/26 upgraded the project format when you created the widget target, and released CocoaPods versions can't read it yet ([CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840)). `dart run flutter_alarmkit:setup` patches `objectVersion` back down to 60 — **but only on disk**. Xcode rewrites it to 70 every time it *saves* the project, so if you run setup and then do anything in Xcode, the fix is undone before `pod install` runs. The reliable fix: do all Xcode work first, then **quit Xcode**, then run `dart run flutter_alarmkit:setup`, then `pod install` — all with Xcode closed. If the error returns, an Xcode save snuck in; quit it and re-run setup before `pod install`.

**Build fails with `Error (Xcode): Cycle inside Runner`**
Xcode added the extension's embed phases after Flutter's `Thin Binary` phase. Run `dart run flutter_alarmkit:setup` (it reorders the phases automatically), then build again. Manual alternative: Runner target > Build Phases > drag `Embed Foundation Extensions` and `[CP] Embed Pods Frameworks` **above** `Thin Binary`.

**The files in `ios/AlarmkitWidget/` look like Xcode sample code (emoji timer)**
Creating the widget target overwrote the plugin's widget files with Xcode placeholders. Run `dart run flutter_alarmkit:setup` — it detects the placeholders and restores the plugin's files, and removes Xcode's extra `AlarmkitWidgetControl.swift` / `AppIntent.swift`.

**`flutter run --release` says `Could not run build/ios/iphoneos/Runner.app`**
Usually the iPhone is locked — unlock it and retry. (The underlying `devicectl` error, "device was not, or could not be, unlocked", is hidden by Flutter.)

**Signing fails with `An Application Group with Identifier 'group.flutter-alarmkit' is not available`**
Plugin versions ≤ 0.4.x required that App Group. App Group IDs are unique across all Apple developer accounts, so only one team could ever register it. The plugin no longer uses an App Group: run `dart run flutter_alarmkit:setup` to remove it from your entitlements files, or delete it under **Signing & Capabilities** > **App Groups** on both targets. You can also remove the App Groups capability entirely if nothing else in your app uses it.

**Alarm fires but the Live Activity shows default button colors, or a plain "Stop" button**
The button tint colors and the stop button's text/icon travel in the alarm's metadata, which only the current widget template reads. Run `dart run flutter_alarmkit:setup` (add `--force` if you customized the widget files) so `ios/AlarmkitWidget/` matches the plugin, then reschedule the alarm — alarms scheduled before upgrading keep the defaults.

**Something else**
[Open an issue](https://github.com/gdelataillade/flutter_alarmkit/issues) and include: Flutter/Xcode/iOS versions, device model, steps to reproduce, error messages, and the output of `dart run flutter_alarmkit:setup --doctor`.

---

## Notes for AI agents

If you are an AI assistant setting this plugin up in a user's app:

- **Mental model:** `dart run flutter_alarmkit:setup` patches all config files, syncs the widget Swift files, and repairs known Xcode/CocoaPods breakage. It is idempotent — when in doubt, run it again. Verify state with `dart run flutter_alarmkit:setup --doctor` instead of inspecting Xcode.
- **Only one step needs a human in the Xcode GUI:** creating the `AlarmkitWidget` Widget Extension target (step 2). Stop and hand off for it; do not attempt to create targets by editing `project.pbxproj`. No App Group or other capability is needed — don't add one.
- **Never hand-write the widget Swift files** — they must match the plugin's `ios/WidgetTemplates/`; the setup command syncs them.
- **Upgrading an existing install** (from 0.4.x or earlier): have the user quit Xcode, then run `dart run flutter_alarmkit:setup` and `--doctor`. Setup updates untouched widget files and strips the legacy `group.flutter-alarmkit` App Group. If the doctor reports a customized widget file that still reads the App Group, the user's edits need porting onto the new template; don't overwrite them with `--force` without asking.
- The only `project.pbxproj` edits that are safe to script are the two the setup command already performs (`objectVersion` downgrade, build-phase reorder).
- Errors you may see and their one-command fix are in the Troubleshooting section above; match on the quoted error strings.
