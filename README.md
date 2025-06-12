# flutter_alarmkit

A Flutter plugin that provides access to Apple's AlarmKit framework, introduced in iOS 26 (WWDC 2025). This plugin allows you to schedule and manage prominent alarms and countdowns in your Flutter applications on iOS devices.

See more: https://developer.apple.com/documentation/alarmkit

Note that this plugin is still in development. Feel free to contribute to the project.

## Features

- Request authorization to schedule alarms
- Schedule one-shot alarms with custom metadata
- Native integration with iOS AlarmKit framework

## Requirements

- iOS 26.0 (beta)
- Xcode 26.0 (beta)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_alarmkit: ^0.0.1  # Use the latest version
```

Then run:

```bash
flutter pub get
```

## Usage

### Request Authorization

Before scheduling any alarms, you need to request authorization from the user:

```dart
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

try {
  final state = await FlutterAlarmkit.requestAuthorization();
  print('Authorization state: $state');
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
    title: 'My Alarm',
    body: 'Time to wake up!',
  );
  print('Alarm scheduled with ID: $alarmId');
} catch (e) {
  print('Error scheduling alarm: $e');
}
```

## API Reference

### `requestAuthorization()`

Requests permission to schedule alarms. Returns the current authorization state.

Returns:
- `Future<AlarmAuthorizationState>`: The current authorization state

Possible states:
- `authorized`: User has granted permission
- `denied`: User has denied permission
- `notDetermined`: User hasn't made a choice yet

### `scheduleOneShotAlarm()`

Schedules a one-time alarm for a specific date and time.

Parameters:
- `dateTime` (DateTime): When the alarm should trigger
- `title` (String): The alarm's title
- `body` (String): The alarm's message

Returns:
- `Future<String>`: The unique identifier for the scheduled alarm

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

