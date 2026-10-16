## 0.5.0
* **Breaking (setup):** the plugin no longer uses an App Group, so setup has one Xcode GUI step instead of two (#21). App Group IDs are unique across Apple developer accounts, so the hardcoded `group.flutter-alarmkit` failed code signing for every team but one ("An Application Group with Identifier 'group.flutter-alarmkit' is not available"), and custom button tint colors never reached the widget for anyone else.
  * Button tint colors now travel to the widget in the alarm's metadata. **Re-run `dart run flutter_alarmkit:setup`** after upgrading so `ios/AlarmkitWidget/` gets the new widget template; if you customized the widget files, port your changes onto it (`--force` resets them first). An outdated widget still works but shows the default button colors.
  * Setup now removes `group.flutter-alarmkit` from every entitlements file the Xcode project signs with (`Runner.entitlements`, flavor/per-configuration files, and the widget extension's), and `--doctor` fails if it is still there. You can also remove the App Groups capability from both targets if nothing else in your app uses it.
  * Setup now recognizes widget files that are untouched copies of an earlier plugin template and updates them without `--force`; customized files are still kept. `--doctor` fails on a customized widget file that still reads the removed App Group.
  * `getAlarms()` label/tint/metadata now live in the app's own `UserDefaults`; existing entries are migrated once from the old suite. Alarms scheduled before upgrading keep the default button colors until rescheduled.
* Privacy manifests: the plugin now declares `CA92.1` (app-only user defaults) instead of `1C8F.1` (App Group), and the widget no longer accesses `UserDefaults`.
* Fix the Live Activity stop button ignoring a custom `stopButton` text, icon and text color on iOS 26.1+ (it showed "Stop" with a plain X). AlarmKit deprecated `AlarmPresentation.Alert.stopButton` in iOS 26.1 and no longer delivers it to the widget, so the stop button now travels in the alarm's metadata like the tints, and the plugin uses the non-deprecated `Alert` initializer on 26.1+. Needs the new widget template (re-run setup, as above). On iOS 26.1+ the system's own alarm alert draws its own stop control, so `stopButton` customizes the Live Activity only.

## 0.4.1
* Treat Mac Catalyst as unsupported instead of declaring AlarmKit available there, and add a native compiler check for the iOS and Catalyst availability paths.

## 0.4.0
* **Breaking:** `pauseAlarm`/`resumeAlarm`/`countdownAlarm`/`cancelAlarm`/`stopAlarm` now throw on `UNSUPPORTED_VERSION` (iOS < 26), `BAD_ARGS`, and unexpected channel errors instead of returning `false`; `false` is reserved for an otherwise valid control operation that AlarmKit rejects (typically because the alarm doesn't exist or isn't in a controllable state). Wrap these in `try`/`catch` where iOS < 26 is possible.
* Fix custom alarm sounds not refreshing when the asset content changes, and same-named assets in different folders overwriting each other.
* Fix Swift Package Manager consumers failing to resolve the plugin because its manifest referenced a nonexistent local `FlutterFramework` package.
* Fix button/alarm tint colors being off by one step (now rounded, not truncated).
* Require Flutter 3.38.0+ (the setup's `AppDelegate` patch relies on `FlutterImplicitEngineDelegate`).

## 0.3.1
* Fix `setCountdownAlarm` crashing (AlarmKit precondition trap) when `repeatDurationInSeconds` is `0`.
* Declare the shared `UserDefaults` (App Group) access in the privacy manifests (plugin + widget) for App Store Required Reason API compliance.

## 0.3.0
* **Breaking:** `getAlarms()` → `Future<List<Alarm>>` and `alarmUpdates()` → `Stream<AlarmUpdateEvent>`, reporting full state (scheduled/countdown/paused/alerting).
* Custom alarm metadata (`AlarmMetadata`: SF Symbol icon + subtitle) — rendered in the Live Activity and returned by `getAlarms()`.
* One-time and daily relative alarms (empty weekdays / `Weekday.everyday`); `cancelAll()`.
* **Breaking:** `getAuthorizationState()` → `AlarmAuthorizationState` (was `int`).
* Fix Live Activity action buttons clipping their labels (e.g. "Stop" → "St…") — buttons now size to fit their text instead of a fixed width.
* Fix unreadable default button text colors — pause/resume defaulted to green (invisible on the green resume tint) and are now white.

## 0.2.0
* Add **Swift Package Manager** support alongside CocoaPods.
* The Live Activity Widget Extension no longer requires CocoaPods — it is a standalone WidgetKit target with no plugin dependency.

## 0.1.0
* Add per-alarm Live Activity UI customization via `AlarmUIConfig` / `AlarmButtonConfig` (button text, SF Symbol, colors, and countdown/paused titles).
* Add a `dart run flutter_alarmkit:setup` CLI (with a `--doctor` check) and a `flutter-alarmkit-setup` Claude Code skill to automate iOS setup; reworked `InstallationSteps.md`.
* Expose `countdownAlarm()` to restart an existing countdown alarm.
* **Breaking:** `alarmUpdates()` is now an instance method (`FlutterAlarmkit().alarmUpdates()`).
* Native & setup hardening: platform-thread replies, graceful iOS < 26 failure, value equality on config classes, and assorted CLI robustness fixes.

## 0.0.10
* Add `getAuthorizationState` method.

## 0.0.9
* Add support for custom alarm sound with `soundPath` parameter.

## 0.0.8
* Add `alarmUpdates` method.

## 0.0.7
* Add `getAlarms` method.
* Add `countdownAlarm` method.
* Add `pauseAlarm` method.
* Add `resumeAlarm` method.

## 0.0.6
* Add Live Activity support.
* Add installation guide.

## 0.0.5
* Add `scheduleRecurrentAlarm` method.
* Add `cancelAlarm` method.

## 0.0.4
* Update README.md.

## 0.0.3
* Add `scheduleCountdownAlarm` method.
* Add `stopAlarm` method.
* Improve example app.

## 0.0.2
* Fix `requestAuthorization` method return value.

## 0.0.1
* Add `requestAuthorization` method.
* Add `scheduleOneShotAlarm` method.
