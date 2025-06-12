
import 'flutter_alarmkit_platform_interface.dart';

class FlutterAlarmkit {
  Future<String?> getPlatformVersion() {
    return FlutterAlarmkitPlatform.instance.getPlatformVersion();
  }
}
