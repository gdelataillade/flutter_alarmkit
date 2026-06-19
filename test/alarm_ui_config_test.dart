import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmUIConfig.toMap', () {
    test('includes a button when set', () {
      const config = AlarmUIConfig(
        stopButton: AlarmButtonConfig(text: 'Done', icon: 'stop.circle'),
      );

      final map = config.toMap();
      expect(map.containsKey('stopButton'), isTrue);
      expect((map['stopButton']! as Map)['text'], 'Done');
    });

    test('omits unset buttons', () {
      const config = AlarmUIConfig(
        stopButton: AlarmButtonConfig(text: 'Stop', icon: 'stop.circle'),
      );

      expect(config.toMap().containsKey('repeatButton'), isFalse);
    });
  });

  group('AlarmUIConfig equality', () {
    test('covers button fields', () {
      const a = AlarmUIConfig(
        repeatButton: AlarmButtonConfig(text: 'Again', icon: 'a'),
      );
      const same = AlarmUIConfig(
        repeatButton: AlarmButtonConfig(text: 'Again', icon: 'a'),
      );
      const different = AlarmUIConfig(
        repeatButton: AlarmButtonConfig(text: 'Repeat', icon: 'a'),
      );

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(different));
    });
  });
}
