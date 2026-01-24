import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';

/// An implementation of [FlutterAlarmkitPlatform] that uses method channels.
class MethodChannelFlutterAlarmkit extends FlutterAlarmkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_alarmkit');

  static const _eventChannel = EventChannel('flutter_alarmkit/events');
  Stream<dynamic>? _alarmUpdates;

  @override
  Stream<dynamic> alarmUpdates() {
    _alarmUpdates ??= _eventChannel.receiveBroadcastStream();
    return _alarmUpdates!;
  }

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
      final granted =
          await methodChannel.invokeMethod<bool>('requestAuthorization') ??
          false;
      return granted;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
        );
      }
      rethrow;
    }
  }

  @override
  Future<int> getAuthorizationState() async {
    try {
      final state =
          await methodChannel.invokeMethod<int>('getAuthorizationState') ?? 0;
      return state;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
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
    String? soundPath,
  }) async {
    try {
      final args = {
        'timestamp': timestamp,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
      };

      final alarmId = await methodChannel.invokeMethod<String>(
        'scheduleOneShotAlarm',
        args,
      );

      if (alarmId != null) {
        debugPrint(
          '[FlutterAlarmkit] One shot alarm $alarmId was scheduled successfully',
        );
      } else {
        throw PlatformException(
          code: 'UNKNOWN_ERROR',
          message: 'Failed to schedule alarm: null result',
        );
      }

      return alarmId;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
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
    String? soundPath,
  }) async {
    try {
      final args = {
        'countdownDurationInSeconds': countdownDurationInSeconds,
        'repeatDurationInSeconds': repeatDurationInSeconds,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
      };

      final alarmId = await methodChannel.invokeMethod<String>(
        'setCountdownAlarm',
        args,
      );

      if (alarmId != null) {
        debugPrint(
          '[FlutterAlarmkit] Countdown alarm $alarmId was scheduled successfully',
        );
      } else {
        throw PlatformException(
          code: 'UNKNOWN_ERROR',
          message: 'Failed to schedule alarm: null result',
        );
      }

      return alarmId;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
        );
      }
      rethrow;
    }
  }

  @override
  Future<String> scheduleRecurrentAlarm({
    required int weekdayMask,
    required int hour,
    required int minute,
    String? label,
    String? tintColor,
    String? soundPath,
  }) async {
    try {
      final args = <String, dynamic>{
        'weekdayMask': weekdayMask,
        'hour': hour,
        'minute': minute,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
      };

      final alarmId = await methodChannel.invokeMethod<String>(
        'scheduleRecurrentAlarm',
        args,
      );

      if (alarmId != null) {
        debugPrint(
          '[FlutterAlarmkit] Recurrent alarm $alarmId was scheduled successfully',
        );
      } else {
        throw PlatformException(
          code: 'UNKNOWN_ERROR',
          message: 'Failed to schedule alarm: null result',
        );
      }

      return alarmId;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAlarms() async {
    final alarms = await methodChannel.invokeListMethod<Map<dynamic, dynamic>>(
      'getAlarms',
    );
    return alarms?.map((alarm) => alarm.cast<String, dynamic>()).toList() ?? [];
  }

  @override
  Future<bool> pauseAlarm({required String alarmId}) async {
    try {
      return await methodChannel.invokeMethod<bool>('pauseAlarm', alarmId) ??
          false;
    } on PlatformException catch (e) {
      debugPrint(
        '[FlutterAlarmkit] Failed to pause alarm $alarmId: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<bool> resumeAlarm({required String alarmId}) async {
    try {
      return await methodChannel.invokeMethod<bool>('resumeAlarm', alarmId) ??
          false;
    } on PlatformException catch (e) {
      debugPrint(
        '[FlutterAlarmkit] Failed to resume alarm $alarmId: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<bool> countdownAlarm({required String alarmId}) async {
    try {
      return await methodChannel.invokeMethod<bool>(
            'countdownAlarm',
            alarmId,
          ) ??
          false;
    } on PlatformException catch (e) {
      debugPrint(
        '[FlutterAlarmkit] Failed to countdown alarm $alarmId: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<bool> cancelAlarm({required String alarmId}) async {
    try {
      final result =
          await methodChannel.invokeMethod<bool>('cancelAlarm', alarmId) ??
          false;

      debugPrint(
        '[FlutterAlarmkit] Alarm $alarmId was cancelled successfully',
      );

      return result;
    } on PlatformException catch (e) {
      debugPrint(
        '[FlutterAlarmkit] Failed to cancel alarm $alarmId: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<bool> stopAlarm({required String alarmId}) async {
    try {
      final stopped =
          await methodChannel.invokeMethod<bool>('stopAlarm', alarmId) ?? false;

      if (stopped) {
        debugPrint(
          '[FlutterAlarmkit] Alarm $alarmId was stopped successfully',
        );
      }

      return stopped;
    } on PlatformException catch (e) {
      debugPrint(
        '[FlutterAlarmkit] Failed to stop alarm $alarmId: ${e.message}',
      );
      return false;
    }
  }
}
