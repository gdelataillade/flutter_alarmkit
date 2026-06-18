// Test fixtures pass plain map literals to the model factories; const-ness is
// irrelevant here.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('add event carries a typed alarm', () {
    final event = AlarmUpdateEvent.fromMap({
      'id': 'A',
      'event': 'add',
      'alarm': {'id': 'A', 'state': 'scheduled'},
    });

    expect(event.kind, AlarmUpdateKind.added);
    expect(event.alarmId, 'A');
    expect(event.alarm, isNotNull);
    expect(event.alarm!.state, AlarmState.scheduled);
  });

  test('update event carries the new alarm state', () {
    final event = AlarmUpdateEvent.fromMap({
      'id': 'A',
      'event': 'update',
      'alarm': {'id': 'A', 'state': 'countdown'},
    });

    expect(event.kind, AlarmUpdateKind.updated);
    expect(event.alarm!.state, AlarmState.countdown);
  });

  test('remove event has a null alarm', () {
    final event = AlarmUpdateEvent.fromMap({'id': 'A', 'event': 'remove'});

    expect(event.kind, AlarmUpdateKind.removed);
    expect(event.alarmId, 'A');
    expect(event.alarm, isNull);
  });

  test('unrecognized event kind maps to unknown', () {
    final event = AlarmUpdateEvent.fromMap({'id': 'A', 'event': 'whoknows'});

    expect(event.kind, AlarmUpdateKind.unknown);
  });

  test('decodes nested Map<Object?, Object?> alarm payloads', () {
    final raw = <Object?, Object?>{
      'id': 'A',
      'event': 'add',
      'alarm': <Object?, Object?>{
        'id': 'A',
        'state': 'scheduled',
        'schedule': <Object?, Object?>{
          'type': 'fixed',
          'timestamp': 1718000000000.0,
        },
      },
    };

    final event = AlarmUpdateEvent.fromMap(raw.cast<String, dynamic>());

    expect(event.kind, AlarmUpdateKind.added);
    expect(event.alarm!.schedule, isA<FixedAlarmSchedule>());
  });
}
