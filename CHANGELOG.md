## 0.3.0
* **Typed alarm reads.** `getAlarms()` now returns `List<Alarm>` and `alarmUpdates()` emits `AlarmUpdateEvent`s, exposing each alarm's state, schedule (including recurrence weekdays), countdown durations, and persisted label/tint color.
* Report **all** alarm states, including `countdown` and `alerting` (previously surfaced as `unknown`). Alarms with an unrecognized state or schedule are now kept (as `unknown`) instead of being silently dropped from `getAlarms()`.
* `alarmUpdates()` now emits `update` events only when an alarm's state, schedule, or countdown duration actually changes.
* Persisted alarm metadata (label/tint) is cleaned up on cancel and removal, so the App Group no longer accumulates orphaned entries.
* **Breaking:** `getAlarms()` returns `Future<List<Alarm>>` (was `Future<List<Map<String, dynamic>>>`) and `alarmUpdates()` returns `Stream<AlarmUpdateEvent>` (was `Stream<dynamic>`).

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