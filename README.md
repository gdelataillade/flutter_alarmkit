# flutter_alarmkit

A Flutter plugin that provides access to Apple's AlarmKit framework, introduced in iOS 26 (WWDC 2025). This plugin allows you to schedule and manage prominent alarms and countdowns in your Flutter applications on iOS devices.

Your alarms will ring even when Do Not Disturb is enabled or if the app has been terminated.

See more: https://developer.apple.com/documentation/alarmkit

![Simulator Screenshot - iPhone 16 - 2025-06-20 at 20 30 28](https://github.com/user-attachments/assets/008b96fb-5bef-46e0-adaf-75ed0e105e10)
<img width="100" alt="IMG_4596" src="https://github.com/user-attachments/assets/b80eeb3a-6d9c-4665-81a0-b6a89a6df090" />
<img width="100" alt="IMG_4597" src="https://github.com/user-attachments/assets/5dd478f0-c528-44e2-98f4-9228e3d2b20a" />
<img width="100" alt="IMG_4598" src="https://github.com/user-attachments/assets/b69ca13a-2ab2-4e1e-a29d-d72c082dd885" />

## Features

### Available features

- Request authorization to schedule alarms
- Schedule one-shot alarms
- Schedule countdown alarms
- Schedule recurrent, daily, and one-time relative alarms
- Read scheduled alarms with their full state, schedule, and metadata (`getAlarms`)
- Observe typed alarm add/update/remove events (`alarmUpdates`)
- Query the typed authorization state (`getAuthorizationState`)
- Set custom alarm sounds
- Customize the Live Activity UI (buttons, icons, colors, titles), including an "Open app" button
- Cancel a single alarm, or all alarms at once (`cancelAll`)
- Stop alarms

## Installation

Please carefully follow the installation steps in [InstallationSteps.md](InstallationSteps.md). Most of it is automated:

```bash
dart run flutter_alarmkit:setup            # patches your iOS project
dart run flutter_alarmkit:setup --doctor   # verifies every step
```

> **Using Claude Code?** This repo includes a `flutter-alarmkit-setup` skill that drives the whole install for you. See [Using with Claude Code](InstallationSteps.md#using-with-claude-code-optional).

> **Note:** the plugin supports both Swift Package Manager and CocoaPods, and needs no `Podfile` changes. The Live Activity Widget Extension is a standalone WidgetKit target with no plugin dependency, so the setup is the same whichever dependency manager your app uses.

## Usage

### Request Authorization

Before scheduling any alarms, you need to request authorization from the user:

```dart
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

try {
  final isAuthorized = await FlutterAlarmkit().requestAuthorization();
  if (isAuthorized) {
    print('Alarm authorization granted');
  } else {
    print('Alarm authorization denied or not determined');
  }
} catch (e) {
  print('Error requesting authorization: $e');
}
```

### Read scheduled alarms

`getAlarms()` returns the alarms currently known to the system as typed
[`Alarm`] objects — including each alarm's lifecycle state, schedule, countdown
durations, and (for alarms scheduled through this plugin) its label and tint
color:

```dart
final alarms = await FlutterAlarmkit().getAlarms();
for (final alarm in alarms) {
  print('${alarm.label} — ${alarm.state}'); // e.g. "Wake up — AlarmState.alerting"

  switch (alarm.schedule) {
    case FixedAlarmSchedule(:final date):
      print('Fires once at $date');
    case RelativeAlarmSchedule(:final hour, :final minute, :final weekdays):
      print('Fires at $hour:$minute on $weekdays');
    case UnknownAlarmSchedule():
    case null:
      break;
  }
}
```

`AlarmState` mirrors AlarmKit's states: `scheduled`, `countdown`, `paused`,
`alerting`, and `unknown` (forward-compatible with future iOS states).

### Listen to alarm updates

`alarmUpdates()` emits a typed `AlarmUpdateEvent` whenever an alarm is added,
updated, or removed. `updated` events fire only when an alarm's state, schedule,
or countdown duration actually changes:

```dart
final stream = FlutterAlarmkit().alarmUpdates();

stream.listen((event) {
  switch (event.kind) {
    case AlarmUpdateKind.added:
    case AlarmUpdateKind.updated:
      print('${event.alarmId} is now ${event.alarm?.state}');
    case AlarmUpdateKind.removed:
      print('${event.alarmId} was removed');
    case AlarmUpdateKind.unknown:
      break;
  }
});
```


### Schedule a One-Shot Alarm

To schedule a one-time alarm:

```dart
try {
  final alarmId = await FlutterAlarmkit().scheduleOneShotAlarm(
    // timestamp is a Unix timestamp in milliseconds since epoch
    timestamp: DateTime.now()
        .add(const Duration(hours: 1))
        .millisecondsSinceEpoch
        .toDouble(),
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
final alarmId = await FlutterAlarmkit().setCountdownAlarm(
  countdownDurationInSeconds: 10, // Duration before the alarm triggers
  repeatDurationInSeconds: 5, // Duration between each repetition
  label: 'My Countdown Alarm',
  tintColor: '#0000FF',
);
```

### Schedule a Recurrent Alarm

To schedule a recurrent alarm:

```dart
final alarmId = await FlutterAlarmkit().scheduleRecurrentAlarm(
  weekdays: {Weekday.monday, Weekday.wednesday, Weekday.friday},
  hour: 10,
  minute: 0,
  label: 'My Recurrent Alarm',
  tintColor: '#0000FF',
);
```

Pass `Weekday.everyday` for a daily alarm, or an **empty set** to fire once at
the next occurrence of the given time without repeating:

```dart
// Daily at 07:00
await FlutterAlarmkit().scheduleRecurrentAlarm(
  weekdays: Weekday.everyday,
  hour: 7,
  minute: 0,
  label: 'Wake up',
);

// Once at the next 07:00 (no repeat)
await FlutterAlarmkit().scheduleRecurrentAlarm(
  weekdays: const {},
  hour: 7,
  minute: 0,
  label: 'One-off',
);
```

### Customize the Live Activity UI

All schedule methods accept an optional `uiConfig` to customize the Live Activity's buttons (text, SF Symbol icon, text color, tint color) and the countdown/paused titles:

```dart
final alarmId = await FlutterAlarmkit().setCountdownAlarm(
  countdownDurationInSeconds: 60,
  repeatDurationInSeconds: 10,
  label: 'Tea timer',
  uiConfig: const AlarmUIConfig(
    stopButton: AlarmButtonConfig(
      text: 'Done',
      icon: 'checkmark.circle',
      textColor: '#FFFFFF',
      tintColor: '#FF3B30',
    ),
    pauseButton: AlarmButtonConfig(text: 'Hold', icon: 'pause.fill'),
    resumeButton: AlarmButtonConfig(text: 'Go', icon: 'play.fill'),
    countdownTitle: 'Steeping...',
    pausedTitle: 'On hold',
  ),
);
```

Every field is optional — anything you leave null keeps the standard AlarmKit appearance. Custom tint colors require the App Group from the installation steps.

For one-shot and recurrent alarms you can add an **"Open app"** secondary button (shown next to Stop) that foregrounds your app — and stops the alarm — when tapped:

```dart
await FlutterAlarmkit().scheduleOneShotAlarm(
  timestamp: fireDate.millisecondsSinceEpoch.toDouble(),
  label: 'Wake up',
  uiConfig: const AlarmUIConfig(
    openAppButton: AlarmButtonConfig(text: 'Open', icon: 'arrow.up.forward.app'),
  ),
);
```

### Cancel an Alarm

To cancel an alarm:

```dart
await FlutterAlarmkit().cancelAlarm(alarmId: alarmId);
```

Or cancel every scheduled alarm at once:

```dart
await FlutterAlarmkit().cancelAll();
```

### Stop an Alarm

To stop an alarm:

```dart
await FlutterAlarmkit().stopAlarm(alarmId: alarmId);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
