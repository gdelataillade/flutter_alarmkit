# flutter_alarmkit

A Flutter plugin that provides access to Apple's AlarmKit framework, introduced in iOS 26 (WWDC 2025). This plugin allows you to schedule and manage prominent alarms and countdowns in your Flutter applications on iOS devices.

See more: https://developer.apple.com/documentation/alarmkit

⚠️ Note that this plugin is still in development. Feel free to contribute to the project.

## Features

- Request authorization to schedule alarms
- Schedule one-shot alarms with custom metadata
- Native integration with iOS AlarmKit framework

## Requirements

- iOS 26.0 (beta)
- Xcode 26.0 (beta)

## Installation

Run:

```bash
flutter pub add flutter_alarmkit
flutter pub get
```

## Usage

### Request Authorization

Before scheduling any alarms, you need to request authorization from the user:

```dart
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

try {
  final isAuthorized = await FlutterAlarmkit.requestAuthorization();
  if (isAuthorized) {
    print('Alarm authorization granted');
  } else {
    print('Alarm authorization denied or not determined');
  }
} catch (e) {
  print('Error requesting authorization: $e');
}
```

### Schedule a One-Shot Alarm

To schedule a one-time alarm:

```dart
try {
  final alarmId = await FlutterAlarmkit.scheduleOneShotAlarm(
    dateTime: DateTime.now().add(Duration(hours: 1)),
    label: 'My Alarm',
  );
  print('Alarm scheduled with ID: $alarmId');
} catch (e) {
  print('Error scheduling alarm: $e');
}
```

## API Reference

### `requestAuthorization()`

Requests permission to schedule alarms. Returns whether the authorization was granted.

Returns:
- `Future<bool>`: `true` if authorization was granted, `false` if denied or not determined

Example:
```dart
try {
  final isAuthorized = await FlutterAlarmkit.requestAuthorization();
  if (isAuthorized) {
    print('Alarm authorization granted');
  } else {
    print('Alarm authorization denied or not determined');
  }
} catch (e) {
  print('Error requesting authorization: $e');
}
```

### `scheduleOneShotAlarm()`

Schedules a one-time alarm for a specific date and time.

Parameters:
- `dateTime` (DateTime): When the alarm should trigger
- `label` (String): The alarm's title

Returns:
- `Future<String>`: The unique identifier for the scheduled alarm

Example:

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

