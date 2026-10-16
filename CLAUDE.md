# flutter_alarmkit

Flutter plugin wrapping Apple's AlarmKit (iOS 26+): schedule one-shot, countdown, and recurrent alarms that present as Live Activities (Lock Screen + Dynamic Island), with customizable buttons/titles via `AlarmUIConfig`.

## Architecture

- `lib/flutter_alarmkit.dart` → platform interface → method channel → `ios/flutter_alarmkit/Sources/flutter_alarmkit/FlutterAlarmkitPlugin.swift`. iOS only.
- `lib/src/alarm_ui_config.dart` / `alarm_button_config.dart`: per-alarm Live Activity customization, serialized over the channel as maps.
- `ios/WidgetTemplates/`: **canonical** widget extension sources (Live Activity UI). The setup CLI copies them into consumer apps at `ios/AlarmkitWidget/`. `example/ios/AlarmkitWidget/` must stay byte-identical to `ios/WidgetTemplates/` — the CLI's self-heal compares file content. **When you change a template, add the outgoing version's fingerprint to `kPreviousTemplateHashes` in `bin/setup.dart`** (`git show HEAD:<path> > /tmp/old && dart run tool/template_hash.dart /tmp/old`). Without it, setup treats consumers' untouched old copies as customizations and won't update them without `--force`.
- Button tint colors can't ride on AlarmKit's `AlarmButton`, so the plugin puts them in the alarm's `NeverMetadata` (`stopTint`/`pauseTint`/`resumeTint`/`repeatTint`) and the widget reads them from `attributes.metadata`. The stop button itself (`stopText`/`stopIcon`/`stopTextColor`) travels there too: `AlarmPresentation.Alert.stopButton` is deprecated since iOS 26.1 and arrives in the widget as a default "Stop" button, so the widget must not read it. The plugin still passes `stopButton` on iOS 26.0 only (`makeAlert`). Per-alarm state for `getAlarms()` (label, tint, metadata) lives in the app's own `UserDefaults.standard`. **No App Group**: App Group IDs are unique across Apple developer accounts, so a hardcoded one only signs for the team that registered it (issue #21). Don't reintroduce one; if app↔widget shared state is ever needed, the group ID must be per-app.
- `bin/setup.dart`: consumer-facing installer (`dart run flutter_alarmkit:setup`), idempotent and self-healing, with a read-only `--doctor` verification mode and `--force` to overwrite customized widget files. No dependencies beyond `dart:io` — keep it that way so it runs before `pod install`.

## Load-bearing values (change all together or not at all)

- Legacy App Group `group.flutter-alarmkit` (≤ 0.4.x): no longer used. `bin/setup.dart` (`kLegacyAppGroupId`) strips it from consumer entitlements and the doctor fails if it remains; the plugin reads that suite once to migrate old `getAlarms()` data (`migrateLegacyPersistenceIfNeeded`).
- Target/folder names `AlarmkitWidget` → `AlarmkitWidgetExtension`: referenced by the doctor checks in `bin/setup.dart` and `InstallationSteps.md`.
- `NeverMetadata` stored-property set (the `AlarmMetadata` payload): defined in `ios/flutter_alarmkit/Sources/flutter_alarmkit/NeverMetadata.swift` (internal) and inline in `ios/WidgetTemplates/AlarmkitWidgetLiveActivity.swift` + `example/ios/AlarmkitWidget/AlarmkitWidgetLiveActivity.swift` (public). The fields must match across all three or AlarmKit's encode (plugin) ↔ decode (widget) won't round-trip; the two widget copies also stay byte-identical. The name is kept (not "AlarmMetadata") to preserve the `AlarmAttributes<NeverMetadata>` Live Activity type identity.

## Consumer setup model (what the CLI/docs encode)

Order matters: `flutter pub add` → create the `AlarmkitWidget` Widget Extension target in Xcode (GUI-only) → quit Xcode → `dart run flutter_alarmkit:setup` → `pod install` (CocoaPods apps only) → `flutter run --release`. Target creation must precede setup because Xcode 16+ creates the target as a filesystem-synchronized folder and clobbers whatever is in `ios/AlarmkitWidget/`; setup run afterwards restores the templates and repairs two Xcode-26 side effects:

| Error | Cause | Fix in CLI |
|---|---|---|
| `pod install`: `Unable to find compatibility version string for object version '70'` | Xcode upgrades pbxproj to objectVersion 70/77; CocoaPods can't parse it (CocoaPods #12840) | downgrade to 60 |
| Build: `Cycle inside Runner` | Xcode/CocoaPods append embed phases after Flutter's `Thin Binary` | move both embed phases above `Thin Binary` |

Never create Xcode targets or add capabilities by editing `project.pbxproj` — that needs the GUI. The only pbxproj edits known to be safe to script are the two above.

## Development

- `flutter analyze` must be clean (strict lints incl. `public_member_api_docs`, `always_use_package_imports`).
- Dart unit tests live in `test/` (models, channel decoding, weekday/metadata normalization); `flutter test` must pass. Native/Live Activity behavior has no automated coverage — verify manually on an iOS 26 device via the example app (`example/`), which has buttons exercising every feature — "Custom alarm UI" (15s countdown) covers all `AlarmUIConfig` fields.
- Test setup-CLI changes against a throwaway `flutter create` project with the plugin as a path dependency; `dart run flutter_alarmkit:setup --doctor` must pass all checks on the example app and on a correctly configured consumer.
- Supports both Swift Package Manager (`ios/flutter_alarmkit/Package.swift`) and CocoaPods (`ios/flutter_alarmkit.podspec`); both build the same sources under `ios/flutter_alarmkit/Sources/flutter_alarmkit/` and must stay in sync (source path, iOS platform floor, bundled `PrivacyInfo.xcprivacy`). The Widget Extension is a standalone WidgetKit target (its own metadata + intents, no plugin import), so it needs no `Podfile` entry and the setup works end to end under both SPM and CocoaPods.
