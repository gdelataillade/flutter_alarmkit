import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_alarmkit/flutter_alarmkit_method_channel.dart';

import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_alarmkit/src/weekday.dart' show Weekday;

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
  /// This stream emits events when alarms are added, updated, or removed.
  ///
  /// Returns a [Stream<dynamic>] that emits events when alarms are added,
  /// updated, or removed.
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0)
  static Stream<dynamic> alarmUpdates() {
    return FlutterAlarmkitPlatform.instance.alarmUpdates();
  }

  /// Schedules a one-time alarm for the specified timestamp.
  ///
  /// [timestamp] should be a Unix timestamp in milliseconds since epoch.
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users
  /// associate the alarm with your app.
  /// This color is used throughout the alarm presentation:
  /// - In the alert presentation, it sets the fill color of the
  /// secondary button
  /// - On the lock screen, it tints the symbol in the secondary button,
  /// the alarm title, and the countdown
  /// - In the Dynamic Island, it's used for visual consistency
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
  }) {
    return FlutterAlarmkitPlatform.instance.scheduleOneShotAlarm(
      timestamp: timestamp,
      label: label,
      tintColor: tintColor,
    );
  }

  /// Schedules a countdown alarm for the specified duration.
  ///
  /// [countdownDurationInSeconds] is the duration of the countdown in seconds.
  /// [repeatDurationInSeconds] is the duration of the repeat in seconds.
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users
  /// associate the alarm with your app.
  /// This color is used throughout the alarm presentation:
  /// - In the alert presentation, it sets the fill color of the
  /// secondary button
  /// - On the lock screen, it tints the symbol in the secondary button,
  /// the alarm title, and the countdown
  /// - In the Dynamic Island, it's used for visual consistency
  ///
  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
  }) {
    return FlutterAlarmkitPlatform.instance.setCountdownAlarm(
      countdownDurationInSeconds: countdownDurationInSeconds,
      repeatDurationInSeconds: repeatDurationInSeconds,
      label: label,
      tintColor: tintColor,
    );
  }

  /// Schedules a recurrent alarm for the specified weekdays and time.
  ///
  /// [weekdays] is a set of weekdays when the alarm should trigger.
  /// [hour] is the hour of the day (0-23)
  /// [minute] is the minute of the hour (0-59)
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users
  /// associate the alarm with your app.
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
  }) {
    return FlutterAlarmkitPlatform.instance.scheduleRecurrentAlarm(
      weekdayMask: Weekday.toBitmask(weekdays),
      hour: hour,
      minute: minute,
      label: label,
      tintColor: tintColor,
    );
  }

  /// Gets all the alarms scheduled in the system.
  ///
  /// Returns a [Future<List<Map<String, dynamic>>>] that completes with a
  /// list of alarms.
  ///
  /// Throws a [PlatformException] if the platform version is not supported
  /// (iOS < 26.0)
  Future<List<Map<String, dynamic>>> getAlarms() {
    return FlutterAlarmkitPlatform.instance.getAlarms();
  }

  /// Deletes the alarm from the system even if the alarm has a repeating
  /// schedule.
  ///
  /// [alarmId] is the UUID of the alarm to cancel.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// canceled, `false` otherwise.
  Future<bool> cancelAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.cancelAlarm(alarmId: alarmId);
  }

  /// Performs a countdown for the alarm with the specified ID if it's currently
  /// alerting.
  ///
  /// The function throws otherwise. This is identical to the repeat function of
  /// a timer, or the snooze function of an alarm.
  ///
  /// [alarmId] is the UUID of the alarm to countdown.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// countdown, `false` otherwise.
  Future<bool> countdownAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.countdownAlarm(alarmId: alarmId);
  }

  /// Pauses the alarm with the specified ID if it's in the countdown state.
  ///
  /// [alarmId] is the UUID of the alarm to pause.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// paused, `false` otherwise.
  Future<bool> pauseAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.pauseAlarm(alarmId: alarmId);
  }

  /// Resumes the alarm with the specified ID if it's in the paused state.
  ///
  /// [alarmId] is the UUID of the alarm to resume.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// resumed, `false` otherwise.
  Future<bool> resumeAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.resumeAlarm(alarmId: alarmId);
  }

  /// If the alarm is a one-shot, meaning it doesn't have a repeating schedule,
  /// then the system deletes the alarm.
  /// If the alarm repeats then it's rescheduled to alert or begins counting
  /// down at the next scheduled time.
  ///
  /// [alarmId] is the UUID of the alarm to stop.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was
  /// stopped, `false` otherwise.
  Future<bool> stopAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.stopAlarm(alarmId: alarmId);
  }
}
