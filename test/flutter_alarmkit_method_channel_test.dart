import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_alarmkit/flutter_alarmkit_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_alarmkit');
  final platform = MethodChannelFlutterAlarmkit();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('getAlarms decodes channel maps into typed Alarms', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'getAlarms') return null;
      // Mirror the StandardMessageCodec shapes a real iOS reply produces:
      // a List<Object?> of Map<Object?, Object?> with nested maps.
      return <Object?>[
        <Object?, Object?>{
          'id': 'A',
          'state': 'alerting',
          'schedule': <Object?, Object?>{
            'type': 'fixed',
            'timestamp': 1718000000000.0,
          },
          'label': 'Wake',
          'tintColor': '#00FF00',
        },
        <Object?, Object?>{
          'id': 'B',
          'state': 'countdown',
          'countdownDuration': <Object?, Object?>{
            'preAlert': 60.0,
            'postAlert': 5.0,
          },
        },
      ];
    });

    final alarms = await platform.getAlarms();

    expect(alarms, hasLength(2));

    expect(alarms[0].id, 'A');
    expect(alarms[0].state, AlarmState.alerting);
    expect(alarms[0].schedule, isA<FixedAlarmSchedule>());
    expect(alarms[0].label, 'Wake');
    expect(alarms[0].tintColor, '#00FF00');

    expect(alarms[1].id, 'B');
    expect(alarms[1].state, AlarmState.countdown);
    expect(alarms[1].schedule, isNull);
    expect(alarms[1].countdownDuration!.preAlert, 60.0);
    expect(alarms[1].countdownDuration!.postAlert, 5.0);
  });

  test('getAlarms returns an empty list when the platform returns null',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await platform.getAlarms(), isEmpty);
  });

  test('getAuthorizationState maps known and sentinel raw ints', () async {
    int? reply;
    messenger.setMockMethodCallHandler(channel, (call) async {
      return call.method == 'getAuthorizationState' ? reply : null;
    });

    reply = 0;
    expect(
      await platform.getAuthorizationState(),
      AlarmAuthorizationState.notDetermined,
    );
    reply = 2;
    expect(
      await platform.getAuthorizationState(),
      AlarmAuthorizationState.denied,
    );
    reply = 3;
    expect(
      await platform.getAuthorizationState(),
      AlarmAuthorizationState.authorized,
    );
    reply = -1;
    expect(
      await platform.getAuthorizationState(),
      AlarmAuthorizationState.unknown,
    );
    reply = null;
    expect(
      await platform.getAuthorizationState(),
      AlarmAuthorizationState.unknown,
    );
  });

  test('cancelAll invokes the cancelAll method', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'cancelAll') called = true;
      return null;
    });

    await platform.cancelAll();
    expect(called, isTrue);
  });

  test('cancelAll rethrows a CANCEL_ALL_ERROR PlatformException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'CANCEL_ALL_ERROR',
        message: 'fail',
        details: ['id-1'],
      );
    });

    await expectLater(
      platform.cancelAll(),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'CANCEL_ALL_ERROR'),
      ),
    );
  });
}
