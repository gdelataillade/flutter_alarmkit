import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_alarmkit_platform_interface.dart';

/// An implementation of [FlutterAlarmkitPlatform] that uses method channels.
class MethodChannelFlutterAlarmkit extends FlutterAlarmkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_alarmkit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> requestAuthorization() async {
    try {
      final bool granted =
          await methodChannel.invokeMethod<bool>('requestAuthorization') ??
          false;
      return granted;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
          details: null,
        );
      }
      rethrow;
    }
  }

  @override
  Future<int> getAuthorizationState() async {
    try {
      final int state =
          await methodChannel.invokeMethod<int>('getAuthorizationState') ?? 0;
      return state;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
          details: null,
        );
      }
      rethrow;
    }
  }

  @override
  Future<String> scheduleOneShotAlarm({
    required double timestamp,
    String? label,
    String? tintColor,
  }) async {
    try {
      final Map<String, dynamic> args = {
        'timestamp': timestamp,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
      };

      final String? alarmId = await methodChannel.invokeMethod<String>(
        'scheduleOneShotAlarm',
        args,
      );

      if (alarmId == null) {
        throw PlatformException(
          code: 'UNKNOWN_ERROR',
          message: 'Failed to schedule alarm: null result',
          details: null,
        );
      }

      return alarmId;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
          details: null,
        );
      }
      rethrow;
    }
  }

  @override
  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
  }) async {
    try {
      final Map<String, dynamic> args = {
        'countdownDurationInSeconds': countdownDurationInSeconds,
        'repeatDurationInSeconds': repeatDurationInSeconds,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
      };

      final String? alarmId = await methodChannel.invokeMethod<String>(
        'setCountdownAlarm',
        args,
      );

      if (alarmId == null) {
        throw PlatformException(
          code: 'UNKNOWN_ERROR',
          message: 'Failed to schedule alarm: null result',
          details: null,
        );
      }

      return alarmId;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
          details: null,
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> stopAlarm({required String alarmId}) async {
    final bool? stopped = await methodChannel.invokeMethod<bool>(
      'stopAlarm',
      alarmId,
    );
    return stopped ?? false;
  }
}
