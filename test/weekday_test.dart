import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Weekday.everyday', () {
    test('contains all seven weekdays', () {
      expect(Weekday.everyday, Weekday.values.toSet());
      expect(Weekday.everyday.length, 7);
    });

    test('encodes to 127 (all seven low bits set)', () {
      expect(Weekday.toBitmask(Weekday.everyday), 127);
    });
  });

  group('Weekday.toBitmask', () {
    test('empty set encodes to 0', () {
      expect(Weekday.toBitmask({}), 0);
    });

    test('monday is bit 0 and sunday is bit 6', () {
      expect(Weekday.toBitmask({Weekday.monday}), 1);
      expect(Weekday.toBitmask({Weekday.sunday}), 64);
    });
  });
}
