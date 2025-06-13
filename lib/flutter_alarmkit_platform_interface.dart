import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_alarmkit_method_channel.dart';

abstract class FlutterAlarmkitPlatform extends PlatformInterface {
  /// Constructs a FlutterAlarmkitPlatform.
  FlutterAlarmkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAlarmkitPlatform _instance = MethodChannelFlutterAlarmkit();

  /// The default instance of [FlutterAlarmkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAlarmkit].
  static FlutterAlarmkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAlarmkitPlatform] when
  /// they register themselves.
  static set instance(FlutterAlarmkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Requests authorization to schedule alarms using AlarmKit.
  ///
  /// Returns a [Future<bool>] that completes with `true` if authorization was granted,
  /// `false` otherwise.
  ///
  /// Throws a [PlatformException] if the platform version is not supported (iOS < 26.0).
  Future<bool> requestAuthorization() {
    throw UnimplementedError(
      'requestAuthorization() has not been implemented.',
    );
  }

  /// Gets the current authorization state of AlarmKit.
  ///
  /// Returns a [Future<int>] that completes with the raw value of the authorization state:
  /// - 0: notDetermined
  /// - 1: restricted
  /// - 2: denied
  /// - 3: authorized
  ///
  /// Throws a [PlatformException] if the platform version is not supported (iOS < 26.0)
  Future<int> getAuthorizationState() {
    throw UnimplementedError(
      'getAuthorizationState() has not been implemented.',
    );
  }

  /// Schedules a one-time alarm for the specified timestamp.
  ///
  /// [timestamp] should be a Unix timestamp in milliseconds since epoch.
  /// [label] is an optional string that will be displayed as the alarm title.
  ///
  /// Returns a [Future<String>] that completes with the UUID of the scheduled alarm.
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
    throw UnimplementedError(
      'scheduleOneShotAlarm() has not been implemented.',
    );
  }

  /// Schedules a countdown alarm for the specified duration.
  ///
  /// [countdownDurationInSeconds] is the duration of the countdown in seconds.
  /// [repeatDurationInSeconds] is the duration of the repeat in seconds.
  /// [label] is an optional string that will be displayed as the alarm title.
  ///
  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
  }) {
    throw UnimplementedError('setCountdownAlarm() has not been implemented.');
  }

  /// Schedules a recurrent alarm for the specified weekdays and time.
  ///
  /// [weekdayMask] is a bitmask representing the days of the week (0 = Monday, 1 = Tuesday, etc.)
  /// [hour] is the hour of the day (0-23)
  /// [minute] is the minute of the hour (0-59)
  /// [label] is an optional string that will be displayed as the alarm title.
  /// [tintColor] is an optional string representing a color that helps users associate the alarm with your app.
  ///
  /// Returns a [Future<String>] that completes with the UUID of the scheduled alarm.
  ///
  /// Throws a [PlatformException] if:
  /// - The platform version is not supported (iOS < 26.0)
  /// - The time parameters are invalid
  /// - The alarm scheduling fails
  /// - The app is not authorized to schedule alarms
  Future<String> scheduleRecurrentAlarm({
    required int weekdayMask,
    required int hour,
    required int minute,
    String? label,
    String? tintColor,
  }) {
    throw UnimplementedError(
      'scheduleRecurrentAlarm() has not been implemented.',
    );
  }

  /// Cancels an alarm with the given ID.
  ///
  /// [alarmId] is the UUID of the alarm to cancel.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was canceled,
  /// `false` otherwise.
  Future<bool> cancelAlarm({required String alarmId}) {
    throw UnimplementedError('cancelAlarm() has not been implemented.');
  }

  /// Stops an alarm with the given ID.
  ///
  /// [alarmId] is the UUID of the alarm to stop.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was stopped,
  /// `false` otherwise.
  Future<bool> stopAlarm({required String alarmId}) {
    throw UnimplementedError('stopAlarm() has not been implemented.');
  }
}
