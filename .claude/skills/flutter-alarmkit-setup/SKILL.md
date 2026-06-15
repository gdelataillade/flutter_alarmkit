---
name: flutter-alarmkit-setup
description: >-
  Step-by-step guide for installing and configuring the flutter_alarmkit plugin
  (Apple AlarmKit alarms presented as Live Activities) in a Flutter iOS app. Use
  this skill whenever the user is adding, installing, setting up, configuring, or
  troubleshooting flutter_alarmkit — including running `dart run
  flutter_alarmkit:setup`, creating the AlarmkitWidget Widget Extension target,
  wiring up App Groups, or hitting setup errors such as "Unable to find
  compatibility version string for object version 70/77", "Cycle inside Runner",
  widget files that look like Xcode's emoji sample, or a Live Activity that shows
  no custom colors or titles. Trigger it even when the user only mentions setting
  up alarms, Live Activities, or the widget extension in a Flutter iOS project, or
  pastes InstallationSteps.md and says "set this up for me". Prefer this skill over
  improvising Xcode/CocoaPods steps from memory — the setup has version-specific
  pitfalls this skill knows how to avoid.
---

# flutter_alarmkit setup

Guide a Flutter iOS app through installing `flutter_alarmkit` end to end. Most of
the work is automated by a bundled CLI; your job is to run it in the right order,
hand off the two steps that genuinely require the Xcode GUI, and verify the result.

## Mental model

`flutter_alarmkit` wraps Apple's AlarmKit (iOS 26+). Alarms present as Live
Activities (Lock Screen + Dynamic Island), which requires a **Widget Extension**
target alongside the app. Setting that up touches files Flutter usually hides:
`Info.plist`, `AppDelegate.swift`, the `Podfile`, entitlements, the widget's Swift
sources, and `project.pbxproj`.

The plugin ships a CLI — `dart run flutter_alarmkit:setup` — that patches all of
those, copies the widget sources, and repairs two Xcode-26 side effects that
otherwise produce cryptic failures. It is **idempotent and self-healing**: running
it again is always safe and is the standard way to recover from a bad state.

Only **two** steps cannot be scripted, because they need Xcode's signing identity
and project UI:

1. Creating the `AlarmkitWidget` Widget Extension target.
2. Adding the App Groups capability to both targets.

For everything else, prefer running the CLI over hand-editing files — it knows the
version-specific pitfalls. Verify any state with `dart run
flutter_alarmkit:setup --doctor` rather than trying to read Xcode's UI, which you
can't see.

## Before you start

Confirm the environment, because AlarmKit has hard requirements that produce
confusing errors if missing:

- **macOS with Xcode 26+** — the Widget Extension target and signing live in Xcode.
- **A physical iOS 26 device** (or iOS 26 simulator) — AlarmKit is iOS 26 only.
  The plugin builds against the iOS 26 SDK. Release mode (`flutter run --release`)
  is the reliable way to test alarms.
- **CocoaPods** — the Widget Extension setup is CocoaPods-based (the CLI writes a
  Podfile block and you run `pod install`). The plugin itself also supports Swift
  Package Manager, so the rest of the app can use either dependency manager.
- You are at the **root of the Flutter app** that will consume the plugin (the
  directory with `pubspec.yaml` and an `ios/` folder).

If you're on Linux/Windows or there's no `ios/` directory, stop and explain that
this plugin is iOS-only and needs a Mac with Xcode.

## The sequence

Run these in order. Steps 2 and 4 are 🖐 **human-only** — you must stop, give the
user precise instructions, and wait for them to confirm before continuing. Don't
attempt to create targets or add capabilities by editing `project.pbxproj`; those
edits won't carry the signing/membership Xcode adds, and you'll create a broken
project that's hard to diagnose.

### 1. Add the dependency

```bash
flutter pub add flutter_alarmkit
```

This also runs `flutter pub get`, which the setup CLI needs in order to locate the
plugin.

### 2. 🖐 Create the Widget Extension target (Xcode GUI — hand off to the user)

Tell the user to do exactly this in Xcode, and wait:

> 1. Open `ios/Runner.xcworkspace` in Xcode.
> 2. **File ▸ New ▸ Target…**
> 3. Choose **Widget Extension**.
> 4. Name it **exactly** `AlarmkitWidget`.
> 5. Check **only** "Include Live Activity" and uncheck anything else.
> 6. Click **Finish**, then **Activate** if prompted.

Why this comes before the CLI: Xcode 16+ creates the target as a
filesystem-synchronized folder at `ios/AlarmkitWidget/` and overwrites whatever is
there with placeholder sample code. Running setup *after* this lets it replace
those placeholders with the plugin's real widget code. The exact name matters —
Xcode derives the target `AlarmkitWidgetExtension` and the folder from it, and the
Podfile and entitlements reference the derived name.

It's fine if Xcode also generates extras like `AlarmkitWidgetControl.swift` or
`AppIntent.swift`; the CLI removes them in the next step. The user does **not**
need to delete or drag any files — synchronized folders pick up disk changes
automatically.

### 3. Run the setup CLI

```bash
dart run flutter_alarmkit:setup
```

This patches `Info.plist`, `AppDelegate.swift`, and the `Podfile`; writes the
plugin's widget Swift files into `ios/AlarmkitWidget/` (replacing Xcode's
placeholders, removing its extras); creates `Runner.entitlements` with the App
Group; downgrades the project format if Xcode bumped it past what CocoaPods can
read; and reorders the Runner build phases so release builds don't deadlock.

Read its output. Every line is prefixed: `[DONE]`/`[FIXED]` (it changed
something), `[OK]` (already correct), `[SKIP]`/`[WARN]` (couldn't act — investigate).

> If you ran setup *before* creating the target by mistake, that's recoverable:
> Xcode overwrote the widget files when it created the target, so just run setup
> again now.

### 4. 🖐 Add App Groups to BOTH targets (Xcode GUI — hand off to the user)

Tell the user, and wait:

> For **both** the `Runner` target and the `AlarmkitWidgetExtension` target:
> 1. Select the target ▸ **Signing & Capabilities**.
> 2. **+ Capability ▸ App Groups**.
> 3. Add the group `group.flutter-alarmkit`.

This must be `group.flutter-alarmkit` exactly — it's hardcoded in the plugin's
native code. Custom button colors and titles travel from the app to the widget
through this shared App Group; without it on both targets, the Live Activity
silently falls back to default styling. Adding the capability also wires the
entitlements files into the build automatically.

### 5. Verify

```bash
dart run flutter_alarmkit:setup --doctor
```

This read-only check reports `[PASS]`/`[FAIL]`/`[WARN]` for every step above and
exits non-zero if anything is broken. Run it now, and run it again any time the
build misbehaves — it's the fastest way to localize a problem, and its output is
exactly what to paste into a bug report.

If it flags a `[FAIL]` the CLI can fix (templates out of sync, project format,
build-phase order), the fix is almost always: run `dart run flutter_alarmkit:setup`
again, then re-run `--doctor`. A `[WARN]` about the extension's App Group means
step 4 isn't done yet on the extension target.

### 6. Build and run

```bash
cd ios && pod install && cd ..
flutter run --release
```

If the build fails with `Cycle inside Runner`, run `dart run
flutter_alarmkit:setup` once more and rebuild — `pod install`'s first run can
re-append a build phase in the wrong spot, and setup re-fixes the order.

## Troubleshooting

These are the failures real installs hit on current Xcode/CocoaPods, with the
fix. The common thread: **re-run the setup CLI** — it detects and repairs most of
these.

| Symptom | Cause | Fix |
|---|---|---|
| `pod install` → `Unable to find compatibility version string for object version '70'` (or `77`) | Xcode 16.3+/26 upgraded the project format past what released CocoaPods can parse ([CocoaPods #12840](https://github.com/CocoaPods/CocoaPods/issues/12840)) | `dart run flutter_alarmkit:setup` (downgrades `objectVersion` to 60), then `pod install`. Xcode may re-upgrade on a later save — just re-run setup. |
| Build → `Error (Xcode): Cycle inside Runner` | Embed phases ended up after Flutter's `Thin Binary` phase | `dart run flutter_alarmkit:setup` (reorders the phases), then rebuild |
| `ios/AlarmkitWidget/` files look like Xcode's emoji-timer sample | Creating the target overwrote the plugin's widget code | `dart run flutter_alarmkit:setup` (restores the real files, removes Xcode's extras) |
| Alarm fires but the Live Activity shows no custom colors/titles | The App Group isn't on both targets | Redo step 4 on **both** Runner and AlarmkitWidgetExtension; confirm with `--doctor` |
| `flutter run --release` → `Could not run … Runner.app` | The iPhone is locked (Flutter hides the real `devicectl` error) | Unlock the phone and retry |
| The user intentionally customized the widget Swift files and setup keeps a `[DIFF]` notice | Setup preserves files it doesn't recognize as Xcode placeholders | Their edits are safe. To overwrite with the plugin templates anyway: `dart run flutter_alarmkit:setup --force` |

If something falls outside this table, point the user to the plugin's
`InstallationSteps.md` (Troubleshooting section) and have them open an issue with
the `--doctor` output, plus Flutter/Xcode/iOS versions and device model.

## What not to do

- **Don't hand-write the widget Swift files.** They must match the plugin's
  canonical templates; the CLI syncs them. Editing them by hand drifts from the
  plugin and breaks the self-heal check.
- **Don't create the Xcode target or add capabilities by scripting
  `project.pbxproj`.** Those need Xcode's GUI for signing and target membership.
  The only pbxproj edits that are safe to script are the two the CLI already does
  (the `objectVersion` downgrade and the build-phase reorder) — let it do them.
- **Don't add `flutter_alarmkit` to the Runner target's pod list.** It belongs in
  the `AlarmkitWidgetExtension` Podfile block, which the CLI writes.
- **Keep CocoaPods for the Widget Extension.** The plugin now supports Swift Package
  Manager, but the widget integration (the Podfile block + `pod install`) is
  CocoaPods-based — don't remove the `Podfile` even if the app otherwise uses SPM.
