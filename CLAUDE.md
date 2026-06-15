# flutter_alarmkit

Flutter plugin wrapping Apple's AlarmKit (iOS 26+): schedule one-shot, countdown, and recurrent alarms that present as Live Activities (Lock Screen + Dynamic Island), with customizable buttons/titles via `AlarmUIConfig`.

## Architecture

- `lib/flutter_alarmkit.dart` → platform interface → method channel → `ios/Classes/FlutterAlarmkitPlugin.swift`. iOS only.
- `lib/src/alarm_ui_config.dart` / `alarm_button_config.dart`: per-alarm Live Activity customization, serialized over the channel as maps.
- `ios/WidgetTemplates/`: **canonical** widget extension sources (Live Activity UI). The setup CLI copies them into consumer apps at `ios/AlarmkitWidget/`. `example/ios/AlarmkitWidget/` must stay byte-identical to `ios/WidgetTemplates/` — the CLI's self-heal compares file content.
- Button tint colors can't ride on AlarmKit's `AlarmButton`, so the plugin writes them to shared `UserDefaults` in the App Group and the widget reads them there.
- `bin/setup.dart`: consumer-facing installer (`dart run flutter_alarmkit:setup`), idempotent and self-healing, with a read-only `--doctor` verification mode and `--force` to overwrite customized widget files. No dependencies beyond `dart:io` — keep it that way so it runs before `pod install`.

## Load-bearing values (change all together or not at all)

- App Group `group.flutter-alarmkit`: hardcoded in `ios/Classes/FlutterAlarmkitPlugin.swift`, `ios/Classes/AlarmLiveActivity.swift`, `ios/WidgetTemplates/AlarmkitWidgetLiveActivity.swift`, `bin/setup.dart` (`kAppGroupId`), and the docs/entitlements.
- Target/folder names `AlarmkitWidget` → `AlarmkitWidgetExtension`: referenced by the Podfile snippet in `bin/setup.dart`, the doctor checks, and `InstallationSteps.md`.

## Consumer setup model (what the CLI/docs encode)

Order matters: `flutter pub add` → create the `AlarmkitWidget` Widget Extension target in Xcode (GUI-only) → `dart run flutter_alarmkit:setup` → App Groups capability on both targets (GUI-only) → `pod install` → `flutter run --release`. Target creation must precede setup because Xcode 16+ creates the target as a filesystem-synchronized folder and clobbers whatever is in `ios/AlarmkitWidget/`; setup run afterwards restores the templates and repairs two Xcode-26 side effects:

| Error | Cause | Fix in CLI |
|---|---|---|
| `pod install`: `Unable to find compatibility version string for object version '70'` | Xcode upgrades pbxproj to objectVersion 70/77; CocoaPods can't parse it (CocoaPods #12840) | downgrade to 60 |
| Build: `Cycle inside Runner` | Xcode/CocoaPods append embed phases after Flutter's `Thin Binary` | move both embed phases above `Thin Binary` |

Never create Xcode targets or add capabilities by editing `project.pbxproj` — those two steps need the GUI. The only pbxproj edits known to be safe to script are the two above.

## Development

- `flutter analyze` must be clean (strict lints incl. `public_member_api_docs`, `always_use_package_imports`).
- No unit tests; verification is manual on an iOS 26 device via the example app (`example/`), which has buttons exercising every feature — "Custom UI Alarm (15s)" covers all `AlarmUIConfig` fields.
- Test setup-CLI changes against a throwaway `flutter create` project with the plugin as a path dependency; `dart run flutter_alarmkit:setup --doctor` must pass all checks on the example app and on a correctly configured consumer.
- CocoaPods only; Swift Package Manager not yet supported (Flutter warns on `pub add` — known, tracked in README roadmap).
