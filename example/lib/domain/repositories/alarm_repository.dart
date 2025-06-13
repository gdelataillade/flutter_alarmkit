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

  Future<bool> stopAlarm({required String alarmId});

  Future<String?> getPlatformVersion();
}
