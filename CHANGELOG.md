## 0.0.11
* Add Live Activity UI customization via `AlarmUIConfig` / `AlarmButtonConfig`: custom stop/pause/resume/repeat buttons (text, SF Symbol, text color, tint color) and countdown/paused titles on all schedule methods.
* Add `dart run flutter_alarmkit:setup` CLI: automated iOS project configuration, self-healing widget file sync, and a `--doctor` mode that verifies every installation step.
* Fix installation on Xcode 16.3+/26: the CLI repairs the CocoaPods-incompatible project format (`objectVersion` 70/77, CocoaPods #12840) and the build-phase order causing "Cycle inside Runner".
* Rework `InstallationSteps.md`: corrected step order (do all Xcode GUI work — target creation and App Groups — first, then **quit Xcode and run the setup command last** so its `objectVersion` downgrade isn't undone by an Xcode re-save before `pod install`), filesystem-synchronized folder instructions, and a verified Troubleshooting section.
* Add a `flutter-alarmkit-setup` Claude Code skill that automates the install.
* **Breaking:** `alarmUpdates()` is now an instance method (`FlutterAlarmkit().alarmUpdates()`), making the whole public API instance-based.
* Expose `countdownAlarm()` on the public API (restarts an existing countdown alarm); previously it was reachable only through the platform interface.
* Add value equality (`==`/`hashCode`/`toString`) to `AlarmUIConfig` and `AlarmButtonConfig`, document the `#RRGGBB` hex-color format, and validate that recurrent alarms specify at least one weekday.
* Native hardening: reply to method calls on the platform thread, fix the alarm-updates stream handler (cancel on re-listen, no cross-thread shared state), and remove dead widget/extension code.
* Register the plugin without an availability gate so iOS < 26 fails calls gracefully with `UNSUPPORTED_VERSION` instead of risking a launch-time trap (the iOS 26 implementation now lives in `AlarmkitPluginImpl`, reached through a runtime `#available` check). This makes the documented "iOS 26.0+ required" behavior real.
* Setup-CLI robustness: Podfile/AppDelegate/entitlements patching now handles extra `do`/`end` blocks, trailing extensions, and self-closed `<array/>`; `--doctor` no longer fails on intentionally-customized widget files.

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