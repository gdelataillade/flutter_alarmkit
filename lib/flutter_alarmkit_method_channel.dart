import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_alarmkit/src/alarm.dart';
import 'package:flutter_alarmkit/src/alarm_update_event.dart';

/// An implementation of [FlutterAlarmkitPlatform] that uses method channels.
class MethodChannelFlutterAlarmkit extends FlutterAlarmkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_alarmkit');

  static const _eventChannel = EventChannel('flutter_alarmkit/events');
  Stream<AlarmUpdateEvent>? _alarmUpdates;

  @override
  Stream<AlarmUpdateEvent> alarmUpdates() {
    _alarmUpdates ??= _eventChannel.receiveBroadcastStream().map(
      (dynamic event) => AlarmUpdateEvent.fromMap(
        (event as Map).map((key, dynamic v) => MapEntry(key.toString(), v)),
      ),
    );
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
      _rethrowMapped(e);
    }
  }

  @override
  Future<int> getAuthorizationState() async {
    try {
      final state =
          await methodChannel.invokeMethod<int>('getAuthorizationState') ?? 0;
      return state;
    } on PlatformException catch (e) {
      _rethrowMapped(e);
    }
  }

  @override
  Future<String> scheduleOneShotAlarm({
    required double timestamp,
    String? label,
    String? tintColor,
    String? soundPath,
    Map<String, dynamic>? uiConfig,
  }) async {
    try {
      final args = {
        'timestamp': timestamp,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
        if (uiConfig != null) 'uiConfig': uiConfig,
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
      _rethrowMapped(e);
    }
  }

  @override
  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
    String? soundPath,
    Map<String, dynamic>? uiConfig,
  }) async {
    try {
      final args = {
        'countdownDurationInSeconds': countdownDurationInSeconds,
        'repeatDurationInSeconds': repeatDurationInSeconds,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
        if (uiConfig != null) 'uiConfig': uiConfig,
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
      _rethrowMapped(e);
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
    Map<String, dynamic>? uiConfig,
  }) async {
    try {
      final args = <String, dynamic>{
        'weekdayMask': weekdayMask,
        'hour': hour,
        'minute': minute,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
        if (uiConfig != null) 'uiConfig': uiConfig,
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
      _rethrowMapped(e);
    }
  }

  @override
  Future<List<Alarm>> getAlarms() async {
    final alarms = await methodChannel.invokeListMethod<Map<dynamic, dynamic>>(
      'getAlarms',
    );
    return alarms
            ?.map((alarm) => Alarm.fromMap(alarm.cast<String, dynamic>()))
            .toList() ??
        [];
  }

  @override
  Future<bool> pauseAlarm({required String alarmId}) async {
    try {
      return await methodChannel.invokeMethod<bool>('pauseAlarm', alarmId) ??
          false;
    } on PlatformException catch (e) {
      debugPrint(
        '[FlutterAlarmkit] Failed to pause alarm $alarmId: [${e.code}] ${e.message}',
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
        '[FlutterAlarmkit] Failed to resume alarm $alarmId: [${e.code}] ${e.message}',
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
        '[FlutterAlarmkit] Failed to countdown alarm $alarmId: [${e.code}] ${e.message}',
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
        '[FlutterAlarmkit] Failed to cancel alarm $alarmId: [${e.code}] ${e.message}',
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
        '[FlutterAlarmkit] Failed to stop alarm $alarmId: [${e.code}] ${e.message}',
      );
      return false;
    }
  }

  /// Re-throws [e], replacing the iOS-version error with a clearer message
  /// while preserving the original details and stack trace.
  Never _rethrowMapped(PlatformException e) {
    if (e.code == 'UNSUPPORTED_VERSION') {
      throw PlatformException(
        code: e.code,
        message: 'AlarmKit is only available on iOS 26.0 and above',
        details: e.details,
        stacktrace: e.stacktrace,
      );
    }
    throw e;
  }
}
