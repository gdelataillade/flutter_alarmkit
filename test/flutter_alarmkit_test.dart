import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Records the arguments the public API forwards to the platform layer.
class _RecordingPlatform extends FlutterAlarmkitPlatform
    with MockPlatformInterfaceMixin {
  int? lastWeekdayMask;
  Map<String, dynamic>? lastMetadata;

  @override
  Future<String> scheduleOneShotAlarm({
    required double timestamp,
    String? label,
    String? tintColor,
    String? soundPath,
    Map<String, dynamic>? uiConfig,
    Map<String, dynamic>? metadata,
  }) async {
    lastMetadata = metadata;
    return 'mock-id';
  }

  @override
  Future<String> setCountdownAlarm({
    required int countdownDurationInSeconds,
    required int repeatDurationInSeconds,
    String? label,
    String? tintColor,
    String? soundPath,
    Map<String, dynamic>? uiConfig,
    Map<String, dynamic>? metadata,
  }) async {
    lastMetadata = metadata;
    return 'mock-id';
  }

  @override
  Future<String> scheduleRecurrentAlarm({
    required int weekdayMask,
    required int hour,
    required int minute,
    String? label,
    String? tintColor,
    String? soundPath,
    Map<String, dynamic>? uiConfig,
    Map<String, dynamic>? metadata,
  }) async {
    lastWeekdayMask = weekdayMask;
    lastMetadata = metadata;
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

  group('metadata normalization', () {
    test('forwards a non-empty metadata map', () async {
      await plugin.scheduleOneShotAlarm(
        timestamp: 0,
        metadata: const AlarmMetadata(icon: 'pills.fill', subtitle: 'Take 2'),
      );

      expect(platform.lastMetadata, {'icon': 'pills.fill', 'subtitle': 'Take 2'});
    });

    test('forwards null when metadata is null', () async {
      await plugin.scheduleOneShotAlarm(timestamp: 0);
      expect(platform.lastMetadata, isNull);
    });

    test('forwards null for an empty AlarmMetadata', () async {
      await plugin.scheduleOneShotAlarm(
        timestamp: 0,
        metadata: const AlarmMetadata(),
      );
      expect(platform.lastMetadata, isNull);
    });

    test('forwards null when all fields are empty strings', () async {
      await plugin.scheduleOneShotAlarm(
        timestamp: 0,
        metadata: const AlarmMetadata(icon: '', subtitle: ''),
      );
      expect(platform.lastMetadata, isNull);
    });

    test('countdown and recurrent also forward metadata', () async {
      await plugin.setCountdownAlarm(
        countdownDurationInSeconds: 10,
        repeatDurationInSeconds: 5,
        metadata: const AlarmMetadata(icon: 'timer'),
      );
      expect(platform.lastMetadata, {'icon': 'timer'});

      await plugin.scheduleRecurrentAlarm(
        weekdays: const {},
        hour: 7,
        minute: 0,
        metadata: const AlarmMetadata(subtitle: 'Daily'),
      );
      expect(platform.lastMetadata, {'subtitle': 'Daily'});
    });
  });
}
