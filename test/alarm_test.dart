// Test fixtures pass plain map literals to the model factories; const-ness is
// irrelevant here.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmState.fromRaw', () {
    test('maps every known state', () {
      expect(AlarmState.fromRaw('scheduled'), AlarmState.scheduled);
      expect(AlarmState.fromRaw('countdown'), AlarmState.countdown);
      expect(AlarmState.fromRaw('paused'), AlarmState.paused);
      expect(AlarmState.fromRaw('alerting'), AlarmState.alerting);
    });

    test('maps unknown and null to unknown', () {
      expect(AlarmState.fromRaw('a-future-state'), AlarmState.unknown);
      expect(AlarmState.fromRaw(null), AlarmState.unknown);
    });
  });

  group('Alarm.fromMap schedules', () {
    test('fixed schedule preserves the timestamp', () {
      final alarm = Alarm.fromMap({
        'id': 'A',
        'state': 'scheduled',
        'schedule': {'type': 'fixed', 'timestamp': 1718000000000.0},
      });

      expect(alarm.schedule, isA<FixedAlarmSchedule>());
      final schedule = alarm.schedule! as FixedAlarmSchedule;
      expect(schedule.date.millisecondsSinceEpoch, 1718000000000);
    });

    test('relative schedule round-trips the weekday mask', () {
      final mask = Weekday.toBitmask(
        {Weekday.monday, Weekday.friday, Weekday.sunday},
      );
      final alarm = Alarm.fromMap({
        'id': 'A',
        'state': 'scheduled',
        'schedule': {
          'type': 'relative',
          'hour': 7,
          'minute': 30,
          'weekdayMask': mask,
        },
      });

      expect(alarm.schedule, isA<RelativeAlarmSchedule>());
      final schedule = alarm.schedule! as RelativeAlarmSchedule;
      expect(schedule.hour, 7);
      expect(schedule.minute, 30);
      expect(
        schedule.weekdays,
        {Weekday.monday, Weekday.friday, Weekday.sunday},
      );
    });

    test('relative schedule with empty mask has no weekdays', () {
      final alarm = Alarm.fromMap({
        'id': 'A',
        'state': 'scheduled',
        'schedule': {'type': 'relative', 'hour': 8, 'minute': 0, 'weekdayMask': 0},
      });

      final schedule = alarm.schedule! as RelativeAlarmSchedule;
      expect(schedule.weekdays, isEmpty);
    });

    test('countdown alarm has no schedule and nullable durations', () {
      final alarm = Alarm.fromMap({
        'id': 'A',
        'state': 'countdown',
        'countdownDuration': {'preAlert': 60.0},
      });

      expect(alarm.schedule, isNull);
      expect(alarm.countdownDuration, isNotNull);
      expect(alarm.countdownDuration!.preAlert, 60.0);
      expect(alarm.countdownDuration!.postAlert, isNull);
    });

    test('unknown schedule type is retained, not dropped', () {
      final alarm = Alarm.fromMap({
        'id': 'A',
        'state': 'scheduled',
        'schedule': {'type': 'a-future-kind'},
      });

      expect(alarm.schedule, isA<UnknownAlarmSchedule>());
    });
  });

  group('Alarm.fromMap nested channel maps', () {
    test('accepts Map<Object?, Object?> nested maps from the channel', () {
      final raw = <Object?, Object?>{
        'id': 'A',
        'state': 'scheduled',
        'schedule': <Object?, Object?>{
          'type': 'relative',
          'hour': 9,
          'minute': 0,
          'weekdayMask': 1, // monday
        },
        'countdownDuration': <Object?, Object?>{'preAlert': 30.0, 'postAlert': 5.0},
      };

      final alarm = Alarm.fromMap(raw.cast<String, dynamic>());

      expect(alarm.schedule, isA<RelativeAlarmSchedule>());
      final schedule = alarm.schedule! as RelativeAlarmSchedule;
      expect(schedule.hour, 9);
      expect(schedule.weekdays, {Weekday.monday});
      expect(alarm.countdownDuration!.postAlert, 5.0);
    });
  });

  group('Alarm metadata', () {
    test('parses persisted label and tint color', () {
      final alarm = Alarm.fromMap({
        'id': 'A',
        'state': 'scheduled',
        'label': 'Wake up',
        'tintColor': '#FF0000',
      });

      expect(alarm.label, 'Wake up');
      expect(alarm.tintColor, '#FF0000');
    });

    test('leaves label and tint null when absent', () {
      final alarm = Alarm.fromMap({'id': 'A', 'state': 'scheduled'});

      expect(alarm.label, isNull);
      expect(alarm.tintColor, isNull);
    });
  });

  group('equality and hashing', () {
    test('weekday set equality is order-independent', () {
      const a = RelativeAlarmSchedule(
        hour: 7,
        minute: 0,
        weekdays: {Weekday.monday, Weekday.friday},
      );
      const b = RelativeAlarmSchedule(
        hour: 7,
        minute: 0,
        weekdays: {Weekday.friday, Weekday.monday},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('Alarm value equality covers all fields', () {
      Alarm build() => Alarm.fromMap({
            'id': 'A',
            'state': 'countdown',
            'countdownDuration': {'preAlert': 30.0, 'postAlert': 5.0},
            'label': 'x',
            'tintColor': '#112233',
          });

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });

    test('Alarms differing in state are not equal', () {
      final scheduled = Alarm.fromMap({'id': 'A', 'state': 'scheduled'});
      final alerting = Alarm.fromMap({'id': 'A', 'state': 'alerting'});

      expect(scheduled, isNot(alerting));
    });
  });
}
