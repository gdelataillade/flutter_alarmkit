import 'package:flutter/foundation.dart';

/// Collects log lines for the example's in-app log panel.
///
/// Wired to `debugPrint` in `main()` so both plugin logs (`[FlutterAlarmkit] …`)
/// and the app's own messages show up for developers and maintainers.
class LogController extends ValueNotifier<List<String>> {
  LogController() : super(const []);

  static const _maxLines = 200;

  /// Appends a timestamped [message], keeping only the most recent lines.
  void log(String message) {
    final entry = '${_timestamp()}  $message';
    final next = [...value, entry];
    value = next.length > _maxLines
        ? next.sublist(next.length - _maxLines)
        : next;
  }

  /// Clears all captured lines.
  void clear() => value = const [];

  String _timestamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }
}

/// Global log sink for the example app.
final logController = LogController();
