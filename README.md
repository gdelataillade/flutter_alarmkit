# flutter_alarmkit

A Flutter plugin that provides access to Apple's AlarmKit framework, introduced in iOS 26 (WWDC 2025). This plugin allows you to schedule and manage prominent alarms and countdowns in your Flutter applications on iOS devices.

Your alarms will ring even when Do Not Disturb is enabled or if the app has been terminated.

See more: https://developer.apple.com/documentation/alarmkit

![Simulator Screenshot - iPhone 16 - 2025-06-20 at 20 30 28](https://github.com/user-attachments/assets/008b96fb-5bef-46e0-adaf-75ed0e105e10)
<img width="100" alt="IMG_4596" src="https://github.com/user-attachments/assets/b80eeb3a-6d9c-4665-81a0-b6a89a6df090" />
<img width="100" alt="IMG_4597" src="https://github.com/user-attachments/assets/5dd478f0-c528-44e2-98f4-9228e3d2b20a" />
<img width="100" alt="IMG_4598" src="https://github.com/user-attachments/assets/b69ca13a-2ab2-4e1e-a29d-d72c082dd885" />


## ⚠️ Important Notes

- This plugin is in active development and relies on Apple's AlarmKit framework (beta).
- Requires iOS 26+ and macOS Tahoe with Xcode 26.0 (beta).
- **Critical**: iOS 26 has known issues with Flutter's debug mode due to stricter memory protection. Use Profile mode for on-device testing and iOS 18.5 simulator for debugging. [See more](https://www.reddit.com/r/FlutterDev/comments/1l856sr/ios_26_warning_and_a_maybe_workaround/).

## Features

### Available features

- Request authorization to schedule alarms
- Schedule one-shot alarms
- Schedule countdown alarms
- Schedule recurrent alarms
- Listen to alarm updates
- Cancel alarms
- Stop alarms

More customizations coming soon.

## Installation

Please carefully follow the installation steps in [InstallationSteps.md](InstallationSteps.md).

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

### Listen to alarm updates

To listen to alarm updates (when alarms are added, updated, or removed):

```dart
final stream = FlutterAlarmkit.alarmUpdates();

stream.listen((alarmUpdate) {
  print('Alarm updated: $alarmUpdate');
});
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

### Schedule a Countdown Alarm

To schedule a countdown alarm:

```dart
final alarmId = await FlutterAlarmkit.scheduleCountdownAlarm(
  countdownDurationInSeconds: 10, // Duration before the alarm triggers
  repeatDurationInSeconds: 5, // Duration between each repetition
  label: 'My Countdown Alarm',
  tintColor: '#0000FF',
);
```

### Schedule a Recurrent Alarm

To schedule a recurrent alarm:

```dart
final alarmId = await FlutterAlarmkit.scheduleRecurrentAlarm(
  weekdays: {Weekday.monday, Weekday.wednesday, Weekday.friday},
  hour: 10,
  minute: 0,
  label: 'My Recurrent Alarm',
  tintColor: '#0000FF',
);
```

### Cancel an Alarm

To cancel an alarm:

```dart
await FlutterAlarmkit.cancelAlarm(alarmId: alarmId);
```

### Stop an Alarm

To stop an alarm:

```dart
await FlutterAlarmkit.stopAlarm(alarmId: alarmId);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
