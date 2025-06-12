import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_alarmkit/flutter_alarmkit_platform_interface.dart';
import 'package:flutter_alarmkit/flutter_alarmkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlarmkitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlarmkitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterAlarmkitPlatform initialPlatform = FlutterAlarmkitPlatform.instance;

  test('$MethodChannelFlutterAlarmkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAlarmkit>());
  });

  test('getPlatformVersion', () async {
    FlutterAlarmkit flutterAlarmkitPlugin = FlutterAlarmkit();
    MockFlutterAlarmkitPlatform fakePlatform = MockFlutterAlarmkitPlatform();
    FlutterAlarmkitPlatform.instance = fakePlatform;

    expect(await flutterAlarmkitPlugin.getPlatformVersion(), '42');
  });
}
