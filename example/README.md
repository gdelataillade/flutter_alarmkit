# flutter_alarmkit example

Demonstrates authorization, one-shot and recurrent alarms, repeating and
non-repeating countdowns, custom sounds and Live Activity UI, alarm metadata,
typed alarm state, update events, cancellation, and stopping an active alarm.

## Run the example

The example requires Flutter 3.38.0+, Xcode 26+, and a physical device running
iOS 26 or newer. AlarmKit behavior cannot be exercised on older iOS versions.

The checked-in iOS project is already configured for the plugin. From this
directory, verify the setup and run a release build:

```bash
flutter pub get
dart run flutter_alarmkit:setup --doctor
flutter run --release
```

Grant alarm permission in the app before using the scheduling controls. The
quick-start alarms use `assets/marimba.caf`; the additional examples cover
metadata, a non-repeating timer, custom buttons, and daily/one-time relative
alarms.

For setup in another app, follow the package's
[installation guide](../InstallationSteps.md).
