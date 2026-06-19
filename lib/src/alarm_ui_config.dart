import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/src/alarm_button_config.dart';

/// UI customization for an alarm's Live Activity presentation.
///
/// All fields are optional. When null, the plugin uses sensible defaults
/// matching the standard AlarmKit behavior.
///
/// Example:
/// ```dart
/// AlarmUIConfig(
///   stopButton: AlarmButtonConfig(
///     text: 'Done',
///     icon: 'checkmark.circle',
///     textColor: '#FFFFFF',
///     tintColor: '#FF3B30',
///   ),
///   pauseButton: AlarmButtonConfig(
///     text: 'Hold',
///     icon: 'pause.fill',
///     tintColor: '#FF9500',
///   ),
///   countdownTitle: 'Counting down...',
///   pausedTitle: 'Timer paused',
/// )
/// ```
@immutable
class AlarmUIConfig {
  /// Stop button shown in the alert state.
  ///
  /// Defaults: text="Stop", icon="stop.circle", textColor=white,
  /// tintColor=system red.
  ///
  /// For countdown alarms the default stop button text is "Done" instead.
  final AlarmButtonConfig? stopButton;

  /// Pause button shown during the countdown state.
  /// Only used by countdown alarms.
  ///
  /// Defaults: text="Pause", icon="pause.circle", textColor=white,
  /// tintColor=system orange.
  final AlarmButtonConfig? pauseButton;

  /// Resume button shown when the alarm is paused.
  /// Only used by countdown alarms.
  ///
  /// Defaults: text="Resume", icon="play.circle", textColor=white,
  /// tintColor=system green.
  final AlarmButtonConfig? resumeButton;

  /// Secondary button shown in the alert state for countdown alarms
  /// (typically "Repeat" — restarts the countdown).
  /// Only used by countdown alarms.
  ///
  /// Defaults: text="Repeat", icon="repeat.circle", textColor=white,
  /// tintColor=system blue.
  final AlarmButtonConfig? repeatButton;

  /// Title shown during the countdown state.
  /// If null, uses the alarm's main label.
  final String? countdownTitle;

  /// Title shown when the alarm is paused.
  /// If null, uses the alarm's main label.
  final String? pausedTitle;

  /// Creates a UI configuration; all fields are optional.
  const AlarmUIConfig({
    this.stopButton,
    this.pauseButton,
    this.resumeButton,
    this.repeatButton,
    this.countdownTitle,
    this.pausedTitle,
  });

  /// Serializes this configuration to a map for method channel transport.
  Map<String, dynamic> toMap() {
    return {
      if (stopButton != null) 'stopButton': stopButton!.toMap(),
      if (pauseButton != null) 'pauseButton': pauseButton!.toMap(),
      if (resumeButton != null) 'resumeButton': resumeButton!.toMap(),
      if (repeatButton != null) 'repeatButton': repeatButton!.toMap(),
      if (countdownTitle != null) 'countdownTitle': countdownTitle,
      if (pausedTitle != null) 'pausedTitle': pausedTitle,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmUIConfig &&
          other.stopButton == stopButton &&
          other.pauseButton == pauseButton &&
          other.resumeButton == resumeButton &&
          other.repeatButton == repeatButton &&
          other.countdownTitle == countdownTitle &&
          other.pausedTitle == pausedTitle;

  @override
  int get hashCode => Object.hash(stopButton, pauseButton, resumeButton,
      repeatButton, countdownTitle, pausedTitle);

  @override
  String toString() => 'AlarmUIConfig(stopButton: $stopButton, '
      'pauseButton: $pauseButton, resumeButton: $resumeButton, '
      'repeatButton: $repeatButton, countdownTitle: $countdownTitle, '
      'pausedTitle: $pausedTitle)';
}
