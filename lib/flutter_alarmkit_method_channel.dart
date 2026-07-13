import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_alarmkit/src/alarm.dart';
import 'package:flutter_alarmkit/src/alarm_authorization_state.dart';
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
  Future<AlarmAuthorizationState> getAuthorizationState() async {
    try {
      final state = await methodChannel.invokeMethod<int>(
        'getAuthorizationState',
      );
      return AlarmAuthorizationState.fromRaw(state);
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
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final args = {
        'timestamp': timestamp,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
        if (uiConfig != null) 'uiConfig': uiConfig,
        if (metadata != null) 'metadata': metadata,
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
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final args = {
        'countdownDurationInSeconds': countdownDurationInSeconds,
        'repeatDurationInSeconds': repeatDurationInSeconds,
        if (label != null) 'label': label,
        if (tintColor != null) 'tintColor': tintColor,
        if (soundPath != null) 'soundPath': soundPath,
        if (uiConfig != null) 'uiConfig': uiConfig,
        if (metadata != null) 'metadata': metadata,
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
    Map<String, dynamic>? metadata,
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
        if (metadata != null) 'metadata': metadata,
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
  Future<bool> pauseAlarm({required String alarmId}) =>
      _controlAlarm('pauseAlarm', alarmId);

  @override
  Future<bool> resumeAlarm({required String alarmId}) =>
      _controlAlarm('resumeAlarm', alarmId);

  @override
  Future<bool> countdownAlarm({required String alarmId}) =>
      _controlAlarm('countdownAlarm', alarmId);

  @override
  Future<bool> cancelAlarm({required String alarmId}) =>
      _controlAlarm('cancelAlarm', alarmId);

  @override
  Future<void> cancelAll() async {
    try {
      await methodChannel.invokeMethod<void>('cancelAll');
    } on PlatformException catch (e) {
      _rethrowMapped(e);
    }
  }

  @override
  Future<bool> stopAlarm({required String alarmId}) =>
      _controlAlarm('stopAlarm', alarmId);

  /// Error codes the native side raises when an alarm can't be controlled —
  /// it doesn't exist, or it isn't in a state the operation applies to.
  /// These map to a `false` return; every other code (`UNSUPPORTED_VERSION`,
  /// `BAD_ARGS`, ...) is genuinely exceptional and propagates.
  static const _controlFailureCodes = {
    'PAUSE_ERROR',
    'RESUME_ERROR',
    'COUNTDOWN_ERROR',
    'CANCEL_ERROR',
    'STOP_ERROR',
  };

  /// Shared implementation of the five alarm-control methods.
  Future<bool> _controlAlarm(String method, String alarmId) async {
    try {
      return await methodChannel.invokeMethod<bool>(method, alarmId) ?? false;
    } on PlatformException catch (e) {
      if (_controlFailureCodes.contains(e.code)) {
        debugPrint(
          '[FlutterAlarmkit] $method($alarmId) failed: [${e.code}] ${e.message}',
        );
        return false;
      }
      _rethrowMapped(e);
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
