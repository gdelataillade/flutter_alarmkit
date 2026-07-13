# flutter_alarmkit

A Flutter plugin that provides access to Apple's AlarmKit framework, introduced in iOS 26 (WWDC 2025). This plugin allows you to schedule and manage prominent alarms and countdowns in your Flutter applications on iOS devices.

Your alarms will ring even when Do Not Disturb is enabled or if the app has been terminated.

See more: https://developer.apple.com/documentation/alarmkit

<img width="150" alt="IMG_0436" src="https://github.com/user-attachments/assets/0990fa59-801f-4cbe-a43a-687879fcdfff" />
<img width="150" alt="IMG_0438" src="https://github.com/user-attachments/assets/0f3b0f28-fdb1-4781-82ef-2cabd0fbba68" />
<img width="150" alt="IMG_0437" src="https://github.com/user-attachments/assets/da498822-7dcb-4eb1-9a1c-6ecd010c88a2" />
<img width="150" alt="IMG_0439" src="https://github.com/user-attachments/assets/823c16c5-14a2-407e-8639-5595a5cf1c20" />

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
- Customize the Live Activity UI (buttons, icons, colors, titles)
- Attach a displayable icon + subtitle to an alarm (`AlarmMetadata`)
- Cancel a single alarm, or all alarms at once (`cancelAll`)
- Stop alarms

## Installation

Requirements: Flutter 3.38.0 or newer, Xcode 26 or newer, and an iOS 26+
device to use AlarmKit. Your app may still support older iOS versions, but
AlarmKit calls made on iOS versions below 26 throw a `PlatformException` with
the code `UNSUPPORTED_VERSION`.

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
color and any `AlarmMetadata`:

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

### Use a custom alarm sound

Add a supported system-sound file (`.caf`, `.aiff`, or `.wav`, under 30
seconds) to your Flutter assets:

```yaml
flutter:
  assets:
    - assets/sounds/alarm.caf
```

Then pass its full asset path to any scheduling method:

```dart
await FlutterAlarmkit().scheduleOneShotAlarm(
  timestamp: DateTime.now()
      .add(const Duration(minutes: 1))
      .millisecondsSinceEpoch
      .toDouble(),
  label: 'Wake up',
  soundPath: 'assets/sounds/alarm.caf',
);
```

The plugin copies the asset to the app's `Library/Sounds` directory. Copies
are keyed by the full asset path, so same-named files in different folders do
not overwrite one another. If the bundled asset's content changes at the same
path, the copy is refreshed the next time an alarm using it is scheduled.

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

### Attach metadata

Attach a displayable SF Symbol `icon` and a `subtitle` to an alarm with `metadata` (available on every schedule method). The Live Activity renders them alongside the title, and they're returned by `getAlarms()`:

```dart
await FlutterAlarmkit().scheduleOneShotAlarm(
  timestamp: fireDate.millisecondsSinceEpoch.toDouble(),
  label: 'Medication',
  metadata: const AlarmMetadata(icon: 'pills.fill', subtitle: 'Take 2 tablets'),
);
```

The default widget renders the icon and subtitle; you can change *how* they render by editing your generated `AlarmkitWidget` sources. Adding entirely new metadata fields also requires changing the plugin's Swift struct.

### Control an existing alarm

The control methods return `true` when AlarmKit performs the operation. They
return `false` when AlarmKit rejects an otherwise valid operation, typically
because the alarm no longer exists or is not in the required state:

```dart
final alarmkit = FlutterAlarmkit();

final paused = await alarmkit.pauseAlarm(alarmId: alarmId);
final resumed = await alarmkit.resumeAlarm(alarmId: alarmId);
final restarted = await alarmkit.countdownAlarm(alarmId: alarmId);
final canceled = await alarmkit.cancelAlarm(alarmId: alarmId);
final stopped = await alarmkit.stopAlarm(alarmId: alarmId);
```

These calls throw a `PlatformException` for invalid arguments (`BAD_ARGS`), on
iOS versions below 26 (`UNSUPPORTED_VERSION`), and for unexpected channel
errors. If your app supports older iOS versions, handle the exception:

```dart
import 'package:flutter/services.dart';

try {
  final stopped = await FlutterAlarmkit().stopAlarm(alarmId: alarmId);
  if (!stopped) {
    print('Alarm was not found or could not be stopped in its current state');
  }
} on PlatformException catch (error) {
  print('Could not control alarm: ${error.code} — ${error.message}');
}
```

To cancel every scheduled alarm at once:

```dart
await FlutterAlarmkit().cancelAll();
```

`cancelAll()` throws `CANCEL_ALL_ERROR` if one or more alarms could not be
canceled; the exception's `details` contains the affected alarm IDs.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
