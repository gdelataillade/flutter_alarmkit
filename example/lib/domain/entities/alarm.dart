class Alarm {
  final String id;
  final DateTime timestamp;
  final String label;
  final String tintColor;
  final int? countdownDurationInSeconds;
  final int? repeatDurationInSeconds;

  const Alarm({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.tintColor,
    this.countdownDurationInSeconds,
    this.repeatDurationInSeconds,
  });

  bool get isCountdown => countdownDurationInSeconds != null;
}
