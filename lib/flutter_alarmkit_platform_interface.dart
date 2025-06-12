import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_alarmkit_method_channel.dart';

abstract class FlutterAlarmkitPlatform extends PlatformInterface {
  /// Constructs a FlutterAlarmkitPlatform.
  FlutterAlarmkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAlarmkitPlatform _instance = MethodChannelFlutterAlarmkit();

  /// The default instance of [FlutterAlarmkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAlarmkit].
  static FlutterAlarmkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAlarmkitPlatform] when
  /// they register themselves.
  static set instance(FlutterAlarmkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
