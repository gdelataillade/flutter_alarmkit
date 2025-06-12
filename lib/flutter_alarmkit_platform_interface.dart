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
}
