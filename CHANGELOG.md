## 0.2.0
* Add Swift Package Manager support alongside CocoaPods. iOS sources moved to `ios/flutter_alarmkit/Sources/flutter_alarmkit/` and a `Package.swift` was added, so Flutter no longer prints the "does not support Swift Package Manager" warning on `pub add`. The Widget Extension setup remains CocoaPods-based.

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