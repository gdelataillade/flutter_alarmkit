// ignore_for_file: public_member_api_docs, document_ignores

import 'package:flutter_alarmkit/flutter_alarmkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A plugin for scheduling alarms using AlarmKit on iOS.
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

  Future<bool> requestAuthorization() {
    throw UnimplementedError(
      'requestAuthorization() has not been implemented.',
    );
  }

  Future<int> getAuthorizationState() {
    throw UnimplementedError(
      'getAuthorizationState() has not been implemented.',
    );
  }

  Future<String> scheduleOneShotAlarm({
    required double timestamp,
    String? label,
    String? tintColor,
  }) {
    throw UnimplementedError(
      'scheduleOneShotAlarm() has not been implemented.',
    );
  }

  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
  }) {
    throw UnimplementedError('setCountdownAlarm() has not been implemented.');
  }

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

  Future<List<Map<String, dynamic>>> getAlarms() {
    throw UnimplementedError('getAlarms() has not been implemented.');
  }

  Future<bool> pauseAlarm({required String alarmId}) {
    throw UnimplementedError('pauseAlarm() has not been implemented.');
  }

  Future<bool> countdownAlarm({required String alarmId}) {
    throw UnimplementedError('countdownAlarm() has not been implemented.');
  }

  Future<bool> cancelAlarm({required String alarmId}) {
    throw UnimplementedError('cancelAlarm() has not been implemented.');
  }

  Future<bool> stopAlarm({required String alarmId}) {
    throw UnimplementedError('stopAlarm() has not been implemented.');
  }

  Future<bool> resumeAlarm({required String alarmId}) {
    throw UnimplementedError('resumeAlarm() has not been implemented.');
  }

  Stream<dynamic> alarmUpdates() {
    throw UnimplementedError('alarmUpdates() has not been implemented.');
  }
}
