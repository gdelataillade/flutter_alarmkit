import 'package:flutter_alarmkit/flutter_alarmkit.dart' show Weekday;

abstract class AlarmRepository {
  Future<bool> requestAuthorization();

  Future<String> scheduleOneShotAlarm({
    required DateTime timestamp,
    required String label,
    required String tintColor,
  });

  Future<String> scheduleCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    required String label,
    required String tintColor,
  });

  Future<String> scheduleRecurrentAlarm({
    required Set<Weekday> weekdays,
    required int hour,
    required int minute,
    required String label,
    required String tintColor,
  });

  Future<bool> cancelAlarm({required String alarmId});

  Future<bool> stopAlarm({required String alarmId});

  Future<String?> getPlatformVersion();
}
