import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_alarmkit/flutter_alarmkit_method_channel.dart';

import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_alarmkit/src/alarm.dart';
import 'package:flutter_alarmkit/src/alarm_ui_config.dart';
import 'package:flutter_alarmkit/src/alarm_update_event.dart';
import 'package:flutter_alarmkit/src/weekday.dart' show Weekday;

export 'src/alarm.dart'
    show
        Alarm,
        AlarmCountdownDuration,
        AlarmSchedule,
        AlarmState,
        FixedAlarmSchedule,
        RelativeAlarmSchedule,
        UnknownAlarmSchedule;
export 'src/alarm_button_config.dart' show AlarmButtonConfig;
export 'src/alarm_ui_config.dart' show AlarmUIConfig;
export 'src/alarm_update_event.dart' show AlarmUpdateEvent, AlarmUpdateKind;
export 'src/weekday.dart' show Weekday;

/// A plugin for scheduling alarms using AlarmKit on iOS.
///
/// This plugin provides a platform interface for scheduling alarms
/// using AlarmKit on iOS.
/// It allows you to schedule one-time, countdown, and recurrent alarms,
/// as well as pause, resume, countdown, cancel, and stop alarms.
///
/// The plugin uses the [MethodChannelFlutterAlarmkit] class to interact
/// with the native platform.
class FlutterAlarmkit {
  /// Returns the platform version of the plugin.
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0).
  Future<String?> getPlatformVersion() {
    return FlutterAlarmkitPlatform.instance.getPlatformVersion();
  }

  /// Requests authorization to schedule alarms using AlarmKit.
  ///
  /// Returns a [Future<bool>] that completes with `true`
  /// if authorization was granted, `false` otherwise.
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0).
  Future<bool> requestAuthorization() {
    return FlutterAlarmkitPlatform.instance.requestAuthorization();
  }

  /// Gets the current authorization state of AlarmKit.
  ///
  /// Returns a [Future<int>] that completes with the raw value of the
  /// authorization state:
  /// - 0: notDetermined
  /// - 1: restricted
  /// - 2: denied
  /// - 3: authorized
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0)
  Future<int> getAuthorizationState() {
    return FlutterAlarmkitPlatform.instance.getAuthorizationState();
  }

  /// A stream of alarm updates.
  ///
  /// Emits an [AlarmUpdateEvent] whenever an alarm is added, updated, or
  /// removed. `updated` events fire only when an alarm's state, schedule, or
  /// countdown duration actually changes.
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0)
  Stream<AlarmUpdateEvent> alarmUpdates() {
    return FlutterAlarmkitPlatform.instance.alarmUpdates();
  }

  /// Schedules a one-time alarm for the specified timestamp.
  ///
  /// [timestamp] should be a Unix timestamp in milliseconds since epoch.
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users
  /// associate the alarm with your app. Must be in the form `#RRGGBB`
  /// (6 hex digits, leading `#` optional); invalid values are ignored.
  /// This color is used throughout the alarm presentation:
  /// - In the alert presentation, it sets the fill color of the
  /// secondary button
  /// - On the lock screen, it tints the symbol in the secondary button,
  /// the alarm title, and the countdown
  /// - In the Dynamic Island, it's used for visual consistency
  ///
  /// [soundPath] is an optional string specifying the path to a custom audio file
  /// in your Flutter assets (e.g., "assets/sounds/alarm.caf").
  ///
  /// **Audio File Requirements:**
  /// - **Formats**: The file must be in a format supported by iOS system sounds,
  ///   such as `.caf` (Core Audio Format), `.aiff`, or `.wav`. MP3 is NOT supported
  ///   for this purpose.
  /// - **Duration**: The sound must be **under 30 seconds**. If it exceeds this
  ///   limit, the system will play the default sound instead.
  /// - **Asset Configuration**: Ensure the file is listed in your `pubspec.yaml`
  ///   under `assets`.
  ///
  /// **How to convert MP3 to CAF:**
  /// You can use `ffmpeg` or `afconvert` (built-in on macOS):
  /// ```bash
  /// afconvert -f caff -d LEI16 input.mp3 output.caf
  /// ```
  ///
  /// Returns a [Future<String>] that completes with the UUID of the scheduled
  /// alarm.
  ///
  /// Throws a [PlatformException] if:
  /// - The platform version is not supported (iOS < 26.0)
  /// - The timestamp is invalid
  /// - The alarm scheduling fails
  /// - The app is not authorized to schedule alarms
  Future<String> scheduleOneShotAlarm({
    required double timestamp,
    String? label,
    String? tintColor,
    String? soundPath,
    AlarmUIConfig? uiConfig,
  }) {
    return FlutterAlarmkitPlatform.instance.scheduleOneShotAlarm(
      timestamp: timestamp,
      label: label,
      tintColor: tintColor,
      soundPath: soundPath,
      uiConfig: uiConfig?.toMap(),
    );
  }

  /// Schedules a countdown alarm for the specified duration.
  ///
  /// [countdownDurationInSeconds] is the duration of the countdown in seconds.
  /// [repeatDurationInSeconds] is the duration of the repeat in seconds.
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users
  /// associate the alarm with your app. Must be in the form `#RRGGBB`
  /// (6 hex digits, leading `#` optional); invalid values are ignored.
  /// This color is used throughout the alarm presentation:
  /// - In the alert presentation, it sets the fill color of the
  /// secondary button
  /// - On the lock screen, it tints the symbol in the secondary button,
  /// the alarm title, and the countdown
  /// - In the Dynamic Island, it's used for visual consistency
  ///
  /// [soundPath] is an optional string specifying the path to a custom audio file
  /// in your Flutter assets (e.g., "assets/sounds/alarm.caf").
  ///
  /// **Audio File Requirements:**
  /// - **Formats**: The file must be in a format supported by iOS system sounds,
  ///   such as `.caf` (Core Audio Format), `.aiff`, or `.wav`. MP3 is NOT supported
  ///   for this purpose.
  /// - **Duration**: The sound must be **under 30 seconds**. If it exceeds this
  ///   limit, the system will play the default sound instead.
  /// - **Asset Configuration**: Ensure the file is listed in your `pubspec.yaml`
  ///   under `assets`.
  ///
  /// **How to convert MP3 to CAF:**
  /// You can use `ffmpeg` or `afconvert` (built-in on macOS):
  /// ```bash
  /// afconvert -f caff -d LEI16 input.mp3 output.caf
  /// ```
  ///
  /// Returns a [Future<String>] that completes with the UUID of the scheduled
  /// alarm.
  ///
  /// Throws a [PlatformException] if:
  /// - The platform version is not supported (iOS < 26.0)
  /// - The duration parameters are invalid
  /// - The alarm scheduling fails
  /// - The app is not authorized to schedule alarms
  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
    String? soundPath,
    AlarmUIConfig? uiConfig,
  }) {
    return FlutterAlarmkitPlatform.instance.setCountdownAlarm(
      countdownDurationInSeconds: countdownDurationInSeconds,
      repeatDurationInSeconds: repeatDurationInSeconds,
      label: label,
      tintColor: tintColor,
      soundPath: soundPath,
      uiConfig: uiConfig?.toMap(),
    );
  }

  /// Schedules a recurrent alarm for the specified weekdays and time.
  ///
  /// [weekdays] is a set of weekdays when the alarm should trigger;
  /// it must contain at least one weekday.
  /// [hour] is the hour of the day (0-23)
  /// [minute] is the minute of the hour (0-59)
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users
  /// associate the alarm with your app. Must be in the form `#RRGGBB`
  /// (6 hex digits, leading `#` optional); invalid values are ignored.
  ///
  /// [soundPath] is an optional string specifying the path to a custom audio file
  /// in your Flutter assets (e.g., "assets/sounds/alarm.caf").
  ///
  /// **Audio File Requirements:**
  /// - **Formats**: The file must be in a format supported by iOS system sounds,
  ///   such as `.caf` (Core Audio Format), `.aiff`, or `.wav`. MP3 is NOT supported
  ///   for this purpose.
  /// - **Duration**: The sound must be **under 30 seconds**. If it exceeds this
  ///   limit, the system will play the default sound instead.
  /// - **Asset Configuration**: Ensure the file is listed in your `pubspec.yaml`
  ///   under `assets`.
  ///
  /// **How to convert MP3 to CAF:**
  /// You can use `ffmpeg` or `afconvert` (built-in on macOS):
  /// ```bash
  /// afconvert -f caff -d LEI16 input.mp3 output.caf
  /// ```
  ///
  /// Returns a [Future<String>] that completes with the UUID of the scheduled
  /// alarm.
  ///
  /// Throws a [PlatformException] if:
  /// - The platform version is not supported (iOS < 26.0)
  /// - The time parameters are invalid
  /// - The alarm scheduling fails
  /// - The app is not authorized to schedule alarms
  Future<String> scheduleRecurrentAlarm({
    required Set<Weekday> weekdays,
    required int hour,
    required int minute,
    String? label,
    String? tintColor,
    String? soundPath,
    AlarmUIConfig? uiConfig,
  }) {
    if (weekdays.isEmpty) {
      throw ArgumentError.value(
        weekdays,
        'weekdays',
        'A recurrent alarm requires at least one weekday.',
      );
    }
    return FlutterAlarmkitPlatform.instance.scheduleRecurrentAlarm(
      weekdayMask: Weekday.toBitmask(weekdays),
      hour: hour,
      minute: minute,
      label: label,
      tintColor: tintColor,
      soundPath: soundPath,
      uiConfig: uiConfig?.toMap(),
    );
  }

  /// Gets all the alarms currently known to the system.
  ///
  /// Returns a [Future] that completes with the list of [Alarm]s, including
  /// each alarm's [AlarmState], schedule, and (for alarms scheduled through
  /// this plugin) its persisted label and tint color.
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0)
  Future<List<Alarm>> getAlarms() {
    return FlutterAlarmkitPlatform.instance.getAlarms();
  }

  /// Deletes the alarm from the system even if the alarm has a repeating
  /// schedule.
  ///
  /// [alarmId] is the UUID of the alarm to cancel.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// canceled, `false` if the operation failed (e.g. the alarm doesn't exist, or the
  /// system rejected the request).
  Future<bool> cancelAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.cancelAlarm(alarmId: alarmId);
  }

  /// Pauses the alarm with the specified ID if it's in the countdown state.
  ///
  /// [alarmId] is the UUID of the alarm to pause.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// paused, `false` if the operation failed (e.g. the alarm doesn't exist, or the
  /// system rejected the request).
  Future<bool> pauseAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.pauseAlarm(alarmId: alarmId);
  }

  /// Resumes the alarm with the specified ID if it's in the paused state.
  ///
  /// [alarmId] is the UUID of the alarm to resume.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// resumed, `false` if the operation failed (e.g. the alarm doesn't exist, or the
  /// system rejected the request).
  Future<bool> resumeAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.resumeAlarm(alarmId: alarmId);
  }

  /// Restarts the countdown of the alarm with the specified ID.
  ///
  /// Re-triggers the countdown for an existing countdown alarm (for example
  /// after it has alerted), mirroring AlarmKit's `countdown(id:)`. This is the
  /// lifecycle sibling of [pauseAlarm]/[resumeAlarm]; to schedule a *new*
  /// countdown alarm, use [setCountdownAlarm] instead.
  ///
  /// [alarmId] is the UUID of the alarm to restart the countdown for.
  ///
  /// Returns a [Future<bool>] that completes with `true` on success,
  /// `false` if the operation failed (e.g. the alarm doesn't exist).
  Future<bool> countdownAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.countdownAlarm(alarmId: alarmId);
  }

  /// If the alarm is a one-shot, meaning it doesn't have a repeating schedule,
  /// then the system deletes the alarm.
  /// If the alarm repeats then it's rescheduled to alert or begins counting
  /// down at the next scheduled time.
  ///
  /// [alarmId] is the UUID of the alarm to stop.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// stopped, `false` if the operation failed (e.g. the alarm doesn't exist, or the
  /// system rejected the request).
  Future<bool> stopAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.stopAlarm(alarmId: alarmId);
  }
}
