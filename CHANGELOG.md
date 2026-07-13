## 0.4.0
* **Breaking:** `pauseAlarm`/`resumeAlarm`/`countdownAlarm`/`cancelAlarm`/`stopAlarm` now throw on `UNSUPPORTED_VERSION` (iOS < 26), `BAD_ARGS`, and unexpected channel errors instead of returning `false`; `false` is reserved for an otherwise valid control operation that AlarmKit rejects (typically because the alarm doesn't exist or isn't in a controllable state). Wrap these in `try`/`catch` where iOS < 26 is possible.
* Fix custom alarm sounds not refreshing when the asset content changes, and same-named assets in different folders overwriting each other.
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
