import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/src/alarm.dart';

/// The kind of change carried by an [AlarmUpdateEvent].
enum AlarmUpdateKind {
  /// An alarm was added (scheduled).
  added,

  /// An existing alarm changed (state, schedule, or countdown duration).
  updated,

  /// An alarm was removed (cancelled, stopped, or completed).
  removed,

  /// An event kind this version of the plugin does not recognize.
  unknown;

  /// Maps a raw event string from the platform channel to an
  /// [AlarmUpdateKind]. Unrecognized values map to [AlarmUpdateKind.unknown].
  static AlarmUpdateKind fromRaw(String? raw) {
    switch (raw) {
      case 'add':
        return AlarmUpdateKind.added;
      case 'update':
        return AlarmUpdateKind.updated;
      case 'remove':
        return AlarmUpdateKind.removed;
      default:
        return AlarmUpdateKind.unknown;
    }
  }
}

/// An event emitted by `FlutterAlarmkit.alarmUpdates()` whenever an alarm is
/// added, updated, or removed.
@immutable
class AlarmUpdateEvent {
  /// What changed.
  final AlarmUpdateKind kind;

  /// The id of the affected alarm.
  final String alarmId;

  /// The alarm snapshot. Non-null for [AlarmUpdateKind.added] and
  /// [AlarmUpdateKind.updated]; null for [AlarmUpdateKind.removed] (and
  /// usually for [AlarmUpdateKind.unknown]).
  final Alarm? alarm;

  /// Creates an [AlarmUpdateEvent].
  const AlarmUpdateEvent({
    required this.kind,
    required this.alarmId,
    this.alarm,
  });

  /// Builds an [AlarmUpdateEvent] from a platform-channel map.
  ///
  /// Tolerant of the `Map<Object?, Object?>` shape that platform channels
  /// produce for nested maps.
  factory AlarmUpdateEvent.fromMap(Map<String, dynamic> map) {
    final rawAlarm = map['alarm'];
    return AlarmUpdateEvent(
      kind: AlarmUpdateKind.fromRaw(map['event'] as String?),
      alarmId: map['id'] as String,
      alarm: rawAlarm is Map
          ? Alarm.fromMap(
              rawAlarm.map((key, dynamic v) => MapEntry(key.toString(), v)),
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmUpdateEvent &&
          other.kind == kind &&
          other.alarmId == alarmId &&
          other.alarm == alarm;

  @override
  int get hashCode => Object.hash(kind, alarmId, alarm);

  @override
  String toString() =>
      'AlarmUpdateEvent(kind: $kind, alarmId: $alarmId, alarm: $alarm)';
}
