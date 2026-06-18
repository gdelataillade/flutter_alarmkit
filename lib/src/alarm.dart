import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/src/weekday.dart';

/// The lifecycle state of an alarm, mirroring AlarmKit's `Alarm.State`.
enum AlarmState {
  /// The alarm is scheduled and waiting for its fire date.
  scheduled,

  /// The alarm is a countdown timer that is currently running.
  countdown,

  /// A countdown alarm whose timer has been paused.
  paused,

  /// The alarm is currently firing (ringing / presenting its alert).
  alerting,

  /// The state could not be mapped — e.g. a future AlarmKit state this
  /// version of the plugin does not yet know about.
  unknown;

  /// Maps a raw state string from the platform channel to an [AlarmState].
  ///
  /// Unrecognized or null values map to [AlarmState.unknown] so the API stays
  /// forward-compatible with future iOS releases.
  static AlarmState fromRaw(String? raw) {
    switch (raw) {
      case 'scheduled':
        return AlarmState.scheduled;
      case 'countdown':
        return AlarmState.countdown;
      case 'paused':
        return AlarmState.paused;
      case 'alerting':
        return AlarmState.alerting;
      default:
        return AlarmState.unknown;
    }
  }
}

/// When an alarm is set to fire.
///
/// This is a sealed hierarchy: an [AlarmSchedule] is exactly one of
/// [FixedAlarmSchedule], [RelativeAlarmSchedule], or [UnknownAlarmSchedule],
/// so callers can exhaustively `switch` over it. Countdown timers have no
/// schedule at all — their [Alarm.schedule] is null and the timing lives in
/// [Alarm.countdownDuration] instead.
@immutable
sealed class AlarmSchedule {
  /// Const constructor for subclasses.
  const AlarmSchedule();
}

/// A one-shot alarm that fires at a fixed wall-clock [date].
@immutable
class FixedAlarmSchedule extends AlarmSchedule {
  /// The exact moment the alarm fires.
  final DateTime date;

  /// Creates a fixed schedule firing at [date].
  const FixedAlarmSchedule(this.date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedAlarmSchedule && other.date == date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'FixedAlarmSchedule(date: $date)';
}

/// A recurring alarm that fires at [hour]:[minute] on the given [weekdays].
///
/// An empty [weekdays] set represents an alarm that fires once at the next
/// occurrence of [hour]:[minute] without repeating (AlarmKit's `.never`
/// recurrence).
@immutable
class RelativeAlarmSchedule extends AlarmSchedule {
  /// Hour of day, 0–23.
  final int hour;

  /// Minute of hour, 0–59.
  final int minute;

  /// The weekdays the alarm repeats on (unmodifiable). Empty means it does not
  /// repeat.
  final Set<Weekday> weekdays;

  /// Creates a relative schedule firing at [hour]:[minute] on [weekdays].
  ///
  /// [weekdays] is copied into an unmodifiable set so the schedule stays
  /// immutable — its value equality and hash code depend on it.
  RelativeAlarmSchedule({
    required this.hour,
    required this.minute,
    Set<Weekday> weekdays = const {},
  }) : weekdays = Set.unmodifiable(weekdays);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelativeAlarmSchedule &&
          other.hour == hour &&
          other.minute == minute &&
          setEquals(other.weekdays, weekdays);

  @override
  int get hashCode => Object.hash(hour, minute, Object.hashAllUnordered(weekdays));

  @override
  String toString() =>
      'RelativeAlarmSchedule(hour: $hour, minute: $minute, weekdays: $weekdays)';
}

/// A schedule of a kind this version of the plugin does not recognize.
///
/// Emitted instead of dropping the alarm when the platform reports a schedule
/// type added in a newer iOS release.
@immutable
class UnknownAlarmSchedule extends AlarmSchedule {
  /// Creates an unknown schedule marker.
  const UnknownAlarmSchedule();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnknownAlarmSchedule;

  @override
  int get hashCode => (UnknownAlarmSchedule).hashCode;

  @override
  String toString() => 'UnknownAlarmSchedule()';
}

/// The countdown timing of a countdown alarm, mirroring AlarmKit's
/// `Alarm.CountdownDuration`.
@immutable
class AlarmCountdownDuration {
  /// Seconds to count down before the alarm fires, if set.
  final double? preAlert;

  /// Seconds to count down after the alarm fires (e.g. the snooze phase),
  /// if set.
  final double? postAlert;

  /// Creates a countdown duration with optional [preAlert]/[postAlert] seconds.
  const AlarmCountdownDuration({this.preAlert, this.postAlert});

  /// Builds an [AlarmCountdownDuration] from a platform-channel map.
  factory AlarmCountdownDuration.fromMap(Map<String, dynamic> map) {
    return AlarmCountdownDuration(
      preAlert: (map['preAlert'] as num?)?.toDouble(),
      postAlert: (map['postAlert'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmCountdownDuration &&
          other.preAlert == preAlert &&
          other.postAlert == postAlert;

  @override
  int get hashCode => Object.hash(preAlert, postAlert);

  @override
  String toString() =>
      'AlarmCountdownDuration(preAlert: $preAlert, postAlert: $postAlert)';
}

/// A snapshot of an alarm known to the system, as returned by
/// `FlutterAlarmkit.getAlarms()` and carried by alarm-update events.
///
/// Note that [label] and [tintColor] are persisted by the plugin (AlarmKit
/// does not expose an alarm's presentation back to the app) and are only
/// available for alarms scheduled through this plugin.
@immutable
class Alarm {
  /// The alarm's unique identifier (a UUID string).
  final String id;

  /// The current lifecycle state of the alarm.
  final AlarmState state;

  /// When the alarm fires, or null for a countdown timer (see
  /// [countdownDuration]).
  final AlarmSchedule? schedule;

  /// The countdown timing, present only for countdown alarms.
  final AlarmCountdownDuration? countdownDuration;

  /// The title shown in the alarm presentation, if the plugin persisted one.
  final String? label;

  /// The alarm's tint color as a `#RRGGBB` hex string, if the plugin
  /// persisted one.
  final String? tintColor;

  /// Creates an [Alarm] snapshot.
  const Alarm({
    required this.id,
    required this.state,
    this.schedule,
    this.countdownDuration,
    this.label,
    this.tintColor,
  });

  /// Builds an [Alarm] from a platform-channel map.
  ///
  /// Tolerant of the `Map<Object?, Object?>` shape that platform channels
  /// produce for nested maps.
  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] as String,
      state: AlarmState.fromRaw(map['state'] as String?),
      schedule: _scheduleFromMap(_asStringMap(map['schedule'])),
      countdownDuration: () {
        final cd = _asStringMap(map['countdownDuration']);
        return cd == null ? null : AlarmCountdownDuration.fromMap(cd);
      }(),
      label: map['label'] as String?,
      tintColor: map['tintColor'] as String?,
    );
  }

  static AlarmSchedule? _scheduleFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    switch (map['type'] as String?) {
      case 'fixed':
        final ms = (map['timestamp'] as num).round();
        return FixedAlarmSchedule(DateTime.fromMillisecondsSinceEpoch(ms));
      case 'relative':
        return RelativeAlarmSchedule(
          hour: (map['hour'] as num).toInt(),
          minute: (map['minute'] as num).toInt(),
          weekdays: _weekdaysFromMask((map['weekdayMask'] as num?)?.toInt() ?? 0),
        );
      default:
        return const UnknownAlarmSchedule();
    }
  }

  static Set<Weekday> _weekdaysFromMask(int mask) {
    return {
      for (final day in Weekday.values)
        if (mask & (1 << day.index) != 0) day,
    };
  }

  /// Normalizes a dynamic channel value into a `Map<String, dynamic>`,
  /// accepting the `Map<Object?, Object?>` that nested channel maps decode to.
  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key.toString(), v),
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alarm &&
          other.id == id &&
          other.state == state &&
          other.schedule == schedule &&
          other.countdownDuration == countdownDuration &&
          other.label == label &&
          other.tintColor == tintColor;

  @override
  int get hashCode =>
      Object.hash(id, state, schedule, countdownDuration, label, tintColor);

  @override
  String toString() => 'Alarm(id: $id, state: $state, schedule: $schedule, '
      'countdownDuration: $countdownDuration, label: $label, '
      'tintColor: $tintColor)';
}
