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
}
