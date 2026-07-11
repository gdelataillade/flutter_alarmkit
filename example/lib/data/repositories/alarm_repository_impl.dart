import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import '../../domain/repositories/alarm_repository.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final FlutterAlarmkit _plugin;

  AlarmRepositoryImpl(this._plugin);

  @override
  Future<bool> requestAuthorization() async {
    return await _plugin.requestAuthorization();
  }

  @override
  Future<AlarmAuthorizationState> getAuthorizationState() async {
    return await _plugin.getAuthorizationState();
  }

  @override
  Future<List<Alarm>> getAlarms() async {
    return await _plugin.getAlarms();
  }

  @override
  Stream<AlarmUpdateEvent> watchAlarms() {
    return _plugin.alarmUpdates();
  }

  @override
  Future<String> scheduleOneShotAlarm({
    required DateTime timestamp,
    required String label,
    required String tintColor,
    String? soundPath,
  }) async {
    return await _plugin.scheduleOneShotAlarm(
      timestamp: timestamp.millisecondsSinceEpoch.toDouble(),
      label: label,
      tintColor: tintColor,
      soundPath: soundPath,
    );
  }

  @override
  Future<String> scheduleCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    required String label,
    required String tintColor,
    String? soundPath,
  }) async {
    return await _plugin.setCountdownAlarm(
      countdownDurationInSeconds: countdownDurationInSeconds,
      repeatDurationInSeconds: repeatDurationInSeconds,
      label: label,
      tintColor: tintColor,
      soundPath: soundPath,
    );
  }

  @override
  Future<String> scheduleRecurrentAlarm({
    required Set<Weekday> weekdays,
    required int hour,
    required int minute,
    required String label,
    required String tintColor,
    String? soundPath,
  }) async {
    return await _plugin.scheduleRecurrentAlarm(
      weekdays: weekdays,
      hour: hour,
      minute: minute,
      label: label,
      tintColor: tintColor,
      soundPath: soundPath,
    );
  }

  @override
  Future<String?> getPlatformVersion() async {
    return await _plugin.getPlatformVersion();
  }

  @override
  Future<bool> cancelAlarm({required String alarmId}) async {
    return await _plugin.cancelAlarm(alarmId: alarmId);
  }

  @override
  Future<bool> stopAlarm({required String alarmId}) async {
    return await _plugin.stopAlarm(alarmId: alarmId);
  }
}
