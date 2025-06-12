import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_alarmkit_platform_interface.dart';

/// An implementation of [FlutterAlarmkitPlatform] that uses method channels.
class MethodChannelFlutterAlarmkit extends FlutterAlarmkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_alarmkit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> requestAuthorization() async {
    try {
      final bool granted =
          await methodChannel.invokeMethod<bool>('requestAuthorization') ??
          false;
      return granted;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        throw PlatformException(
          code: 'UNSUPPORTED_VERSION',
          message: 'AlarmKit is only available on iOS 26.0 and above',
          details: null,
        );
      }
      rethrow;
    }
  }
}
