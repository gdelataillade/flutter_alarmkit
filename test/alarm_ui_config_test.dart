import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmUIConfig.toMap', () {
    test('includes openAppButton when set', () {
      const config = AlarmUIConfig(
        openAppButton: AlarmButtonConfig(
          text: 'Open',
          icon: 'arrow.up.forward.app',
        ),
      );

      final map = config.toMap();
      expect(map.containsKey('openAppButton'), isTrue);
      expect((map['openAppButton']! as Map)['text'], 'Open');
    });

    test('omits openAppButton when null', () {
      const config = AlarmUIConfig(
        stopButton: AlarmButtonConfig(text: 'Stop', icon: 'stop.circle'),
      );

      expect(config.toMap().containsKey('openAppButton'), isFalse);
    });
  });

  group('AlarmUIConfig equality', () {
    test('covers the openAppButton field', () {
      const a = AlarmUIConfig(
        openAppButton: AlarmButtonConfig(text: 'Open', icon: 'a'),
      );
      const same = AlarmUIConfig(
        openAppButton: AlarmButtonConfig(text: 'Open', icon: 'a'),
      );
      const different = AlarmUIConfig(
        openAppButton: AlarmButtonConfig(text: 'Launch', icon: 'a'),
      );

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(different));
    });
  });
}
