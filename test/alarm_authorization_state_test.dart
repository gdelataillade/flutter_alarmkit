import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmAuthorizationState.fromRaw', () {
    test('maps the known raw values', () {
      expect(
        AlarmAuthorizationState.fromRaw(0),
        AlarmAuthorizationState.notDetermined,
      );
      expect(
        AlarmAuthorizationState.fromRaw(2),
        AlarmAuthorizationState.denied,
      );
      expect(
        AlarmAuthorizationState.fromRaw(3),
        AlarmAuthorizationState.authorized,
      );
    });

    test('maps the -1 sentinel, null, and unrecognized values to unknown', () {
      expect(
        AlarmAuthorizationState.fromRaw(-1),
        AlarmAuthorizationState.unknown,
      );
      expect(
        AlarmAuthorizationState.fromRaw(null),
        AlarmAuthorizationState.unknown,
      );
      // 1 was the old bogus "restricted" value — it must not map to anything.
      expect(
        AlarmAuthorizationState.fromRaw(1),
        AlarmAuthorizationState.unknown,
      );
      expect(
        AlarmAuthorizationState.fromRaw(99),
        AlarmAuthorizationState.unknown,
      );
    });
  });
}
