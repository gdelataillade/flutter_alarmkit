import 'flutter_alarmkit_platform_interface.dart';

class FlutterAlarmkit {
  Future<String?> getPlatformVersion() {
    return FlutterAlarmkitPlatform.instance.getPlatformVersion();
  }

  /// Requests authorization to schedule alarms using AlarmKit.
  ///
  /// Returns a [Future<bool>] that completes with `true` if authorization was granted,
  /// `false` otherwise.
  ///
  /// Throws a [PlatformException] if the platform version is not supported (iOS < 26.0).
  Future<bool> requestAuthorization() {
    return FlutterAlarmkitPlatform.instance.requestAuthorization();
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
    return FlutterAlarmkitPlatform.instance.getAuthorizationState();
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
    return FlutterAlarmkitPlatform.instance.scheduleOneShotAlarm(
      timestamp: timestamp,
      label: label,
      tintColor: tintColor,
    );
  }

  /// Stops an alarm with the given ID.
  ///
  /// [alarmId] is the UUID of the alarm to stop.
  ///
  /// Returns a [Future<bool>] that completes with `true` if the alarm was stopped,
  /// `false` otherwise.
  Future<bool> stopAlarm({required String alarmId}) {
    return FlutterAlarmkitPlatform.instance.stopAlarm(alarmId: alarmId);
  }
}
