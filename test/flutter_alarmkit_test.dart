import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Records the arguments the public API forwards to the platform layer.
class _RecordingPlatform extends FlutterAlarmkitPlatform
    with MockPlatformInterfaceMixin {
  int? lastWeekdayMask;

  @override
  Future<String> scheduleRecurrentAlarm({
    required int weekdayMask,
    required int hour,
    required int minute,
    String? label,
    String? tintColor,
    String? soundPath,
    Map<String, dynamic>? uiConfig,
  }) async {
    lastWeekdayMask = weekdayMask;
    return 'mock-id';
  }
}

void main() {
  late _RecordingPlatform platform;
  late FlutterAlarmkit plugin;

  setUp(() {
    platform = _RecordingPlatform();
    FlutterAlarmkitPlatform.instance = platform;
    plugin = FlutterAlarmkit();
  });

  group('scheduleRecurrentAlarm weekday handling', () {
    test('empty weekdays no longer throws and forwards mask 0 (fires once)',
        () async {
      final id = await plugin.scheduleRecurrentAlarm(
        weekdays: {},
        hour: 7,
        minute: 0,
      );

      expect(id, 'mock-id');
      expect(platform.lastWeekdayMask, 0);
    });

    test('Weekday.everyday forwards mask 127 (daily)', () async {
      await plugin.scheduleRecurrentAlarm(
        weekdays: Weekday.everyday,
        hour: 7,
        minute: 0,
      );

      expect(platform.lastWeekdayMask, 127);
    });

    test('a specific weekday set forwards the matching bitmask', () async {
      await plugin.scheduleRecurrentAlarm(
        weekdays: {Weekday.monday, Weekday.sunday},
        hour: 7,
        minute: 0,
      );

      expect(platform.lastWeekdayMask, 1 | 64);
    });
  });
}
