// This is a CLI script: print is its UI.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// The App Group earlier plugin versions (<= 0.4.x) told consumers to add.
/// It is no longer used, and App Group IDs are unique across Apple developer
/// accounts, so it breaks signing for every team except the one that owns it.
/// Setup removes it from the entitlements files it may have been written to.
const String kLegacyAppGroupId = 'group.flutter-alarmkit';

/// Files Xcode generates when creating the Widget Extension target that the
/// plugin does not use and that conflict with the plugin's templates.
const List<String> kStrayXcodeFiles = [
  'AlarmkitWidgetControl.swift',
  'AppIntent.swift',
];

/// FNV-1a (32-bit) fingerprints of every widget template version earlier
/// plugin releases shipped, by file name. A consumer file matching one is an
/// untouched old template rather than a customization, so setup updates it
/// without `--force`. When a template in ios/WidgetTemplates/ changes, add the
/// outgoing version's fingerprint (`_fnv1a32` of its bytes) here.
const Map<String, Set<int>> kPreviousTemplateHashes = {
  'AlarmkitWidget.swift': {0xa2341217},
  'AlarmkitWidgetBundle.swift': {0x094a9a62, 0xa0a8b896, 0xebb654cd},
  'AlarmkitWidgetLiveActivity.swift': {
    0x42c02bff,
    0x571d0793,
    0x5fea7ceb,
    0x816d5a89,
    0x87b4dac1,
    0xcb81a5c6,
    0xdac0371f,
  },
  'AppIntents.swift': {0x55690885, 0x94525f5b, 0xb322fcc0},
  'PrivacyInfo.xcprivacy': {0xbd2a45ce},
};

/// Info.plist keys required by AlarmKit / Live Activities.
const List<String> kRequiredPlistKeys = [
  'NSAlarmKitUsageDescription',
  'NSSupportsLiveActivities',
  'NSBonjourServices',
  'NSLocalNetworkUsageDescription',
  'UIApplicationSceneManifest',
];

void main(List<String> args) {
  final doctorMode = args.contains('--doctor');
  final force = args.contains('--force');

  print('');
  print(doctorMode ? 'flutter_alarmkit doctor' : 'flutter_alarmkit setup');
  print('======================');
  print('');

  final projectRoot = _findProjectRoot();
  if (projectRoot == null) {
    print('[ERROR] Could not find Flutter project root (no pubspec.yaml).');
    print('        Run this from your Flutter project directory.');
    exit(1);
  }

  final iosDir = Directory('${projectRoot.path}/ios');
  if (!iosDir.existsSync()) {
    print('[ERROR] No ios/ directory found. Run "flutter create ." first.');
    exit(1);
  }

  if (doctorMode) {
    exit(_runDoctor(projectRoot));
  }

  _patchInfoPlist(projectRoot);
  _patchAppDelegate(projectRoot);
  _syncWidgetTemplates(projectRoot, force: force);
  _removeLegacyAppGroup(projectRoot);
  _patchProjectObjectVersion(projectRoot);
  _fixBuildPhaseOrder(projectRoot);

  print('');
  print('Setup complete!');
  _printNextSteps(projectRoot);
}

// ---------------------------------------------------------------------------
// Find project root
// ---------------------------------------------------------------------------

Directory? _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
  return null;
}

// ---------------------------------------------------------------------------
// 1. Patch Info.plist
// ---------------------------------------------------------------------------

void _patchInfoPlist(Directory projectRoot) {
  final plistPath = '${projectRoot.path}/ios/Runner/Info.plist';
  final file = File(plistPath);
  if (!file.existsSync()) {
    print('[SKIP] Info.plist not found at $plistPath');
    return;
  }

  var content = file.readAsStringSync();

  const requiredEntries = <MapEntry<String, String>>[
    MapEntry(
      'NSAlarmKitUsageDescription',
      '\t<key>NSAlarmKitUsageDescription</key>\n'
          '\t<string>This app uses alarms to notify you even when your device is locked.</string>',
    ),
    MapEntry(
      'NSSupportsLiveActivities',
      '\t<key>NSSupportsLiveActivities</key>\n\t<true/>',
    ),
    MapEntry(
      'NSBonjourServices',
      '\t<key>NSBonjourServices</key>\n'
          '\t<array>\n'
          '\t\t<string>_alarmkit._tcp</string>\n'
          '\t</array>',
    ),
    MapEntry(
      'NSLocalNetworkUsageDescription',
      '\t<key>NSLocalNetworkUsageDescription</key>\n'
          '\t<string>This app needs access to the local network to discover and connect to alarm devices.</string>',
    ),
    MapEntry(
      'UIApplicationSceneManifest',
      '\t<key>UIApplicationSceneManifest</key>\n'
          '\t<dict>\n'
          '\t\t<key>UIApplicationSupportsMultipleScenes</key>\n'
          '\t\t<false/>\n'
          '\t\t<key>UISceneConfigurations</key>\n'
          '\t\t<dict>\n'
          '\t\t\t<key>UIWindowSceneSessionRoleApplication</key>\n'
          '\t\t\t<array>\n'
          '\t\t\t\t<dict>\n'
          '\t\t\t\t\t<key>UISceneClassName</key>\n'
          '\t\t\t\t\t<string>UIWindowScene</string>\n'
          '\t\t\t\t\t<key>UISceneConfigurationName</key>\n'
          '\t\t\t\t\t<string>flutter</string>\n'
          '\t\t\t\t\t<key>UISceneDelegateClassName</key>\n'
          '\t\t\t\t\t<string>FlutterSceneDelegate</string>\n'
          '\t\t\t\t\t<key>UISceneStoryboardFile</key>\n'
          '\t\t\t\t\t<string>Main</string>\n'
          '\t\t\t\t</dict>\n'
          '\t\t\t</array>\n'
          '\t\t</dict>\n'
          '\t</dict>',
    ),
  ];

  final missingBlocks = <String>[];
  for (final entry in requiredEntries) {
    if (!content.contains('<key>${entry.key}</key>')) {
      missingBlocks.add(entry.value);
    }
  }

  if (missingBlocks.isEmpty) {
    print('[OK]   Info.plist already contains AlarmKit keys');
    return;
  }

  final insertionPoint = content.lastIndexOf('</dict>');
  if (insertionPoint == -1) {
    print(
      '[WARN] Could not find closing </dict> in Info.plist. Manual edit needed.',
    );
    return;
  }

  final blockToInsert = '${missingBlocks.join('\n')}\n';
  content =
      '${content.substring(0, insertionPoint)}$blockToInsert${content.substring(insertionPoint)}';
  file.writeAsStringSync(content);
  print(
    '[DONE] Info.plist patched with ${missingBlocks.length} missing AlarmKit key blocks',
  );
}

// ---------------------------------------------------------------------------
// 2. Patch AppDelegate.swift
// ---------------------------------------------------------------------------

void _patchAppDelegate(Directory projectRoot) {
  final filePath = '${projectRoot.path}/ios/Runner/AppDelegate.swift';
  final file = File(filePath);
  if (!file.existsSync()) {
    print('[SKIP] AppDelegate.swift not found');
    return;
  }

  var content = file.readAsStringSync();
  var changed = false;

  final classPattern = RegExp(r'class\s+AppDelegate\s*:\s*([^{]+)\{');
  final classMatch = classPattern.firstMatch(content);
  if (classMatch == null) {
    print(
      '[WARN] Could not find AppDelegate class declaration. Manual edit needed.',
    );
    return;
  }

  final inheritedTypes =
      classMatch
          .group(1)!
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  if (!inheritedTypes.contains('FlutterImplicitEngineDelegate')) {
    inheritedTypes.add('FlutterImplicitEngineDelegate');
    final updatedDeclaration =
        'class AppDelegate: ${inheritedTypes.join(', ')} {';
    content = content.replaceRange(
      classMatch.start,
      classMatch.end,
      updatedDeclaration,
    );
    changed = true;
  }

  const methodToAdd = '''

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
''';

  if (!content.contains('didInitializeImplicitFlutterEngine(')) {
    // Re-match the class on the (possibly updated) content so offsets stay
    // valid after the inheritance edit above.
    final freshMatch = classPattern.firstMatch(content);
    if (freshMatch == null) {
      print(
        '[WARN] Could not find AppDelegate class declaration. Manual edit needed.',
      );
      return;
    }

    // Walk forward from just after the class's opening brace, tracking depth,
    // to find the class's own closing brace — not the file's last brace, which
    // may belong to a trailing extension/struct after the class body.
    var depth = 1;
    var i = freshMatch.end;
    while (i < content.length && depth > 0) {
      final c = content[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) break;
      }
      i++;
    }
    if (depth != 0) {
      print(
        '[WARN] Could not find AppDelegate class closing brace. Manual edit needed.',
      );
      return;
    }

    content = '${content.substring(0, i)}$methodToAdd${content.substring(i)}';
    changed = true;
  }

  if (!changed) {
    print(
      '[OK]   AppDelegate.swift already configured for implicit engine setup',
    );
    return;
  }

  file.writeAsStringSync(content);
  print(
    '[DONE] AppDelegate.swift patched for FlutterImplicitEngineDelegate setup',
  );
}

// ---------------------------------------------------------------------------
// 3. Sync widget template files (self-healing)
// ---------------------------------------------------------------------------
//
// Xcode 16+ creates the Widget Extension target as a filesystem-synchronized
// folder at ios/AlarmkitWidget/ and overwrites the plugin's templates with
// its own placeholders. This step compares each file against the bundled
// templates and restores anything that is missing or clobbered, so the setup
// can be safely re-run after creating the target in Xcode.

void _syncWidgetTemplates(Directory projectRoot, {bool force = false}) {
  final pluginDir = _findPluginDirectory(projectRoot);
  if (pluginDir == null) {
    print('[WARN] Could not locate flutter_alarmkit plugin directory.');
    print('       Run "flutter pub get" first, then re-run this setup.');
    return;
  }

  final templateDir = Directory('${pluginDir.path}/ios/WidgetTemplates');
  if (!templateDir.existsSync()) {
    print('[WARN] Widget templates not found in plugin at ${templateDir.path}');
    return;
  }

  final targetDir = Directory('${projectRoot.path}/ios/AlarmkitWidget');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  var copied = 0;
  var restored = 0;
  var unchanged = 0;
  final kept = <String>[];

  for (final entity in templateDir.listSync()) {
    if (entity is! File) continue;
    final fileName = Uri.file(entity.path).pathSegments.last;
    final dest = File('${targetDir.path}/$fileName');

    if (!dest.existsSync()) {
      entity.copySync(dest.path);
      copied++;
      continue;
    }

    final destContent = dest.readAsStringSync();
    final templateContent = entity.readAsStringSync();
    if (destContent == templateContent) {
      unchanged++;
      continue;
    }
    final String? reason;
    if (force) {
      reason = 'Restored ios/AlarmkitWidget/$fileName (--force)';
    } else if (_looksLikeXcodePlaceholder(destContent)) {
      reason = 'Restored ios/AlarmkitWidget/$fileName (Xcode placeholder replaced)';
    } else if (_isPreviousTemplate(fileName, dest)) {
      reason = 'Updated ios/AlarmkitWidget/$fileName (from a previous plugin version)';
    } else {
      reason = null;
    }
    if (reason == null) {
      kept.add(fileName);
    } else {
      entity.copySync(dest.path);
      restored++;
      print('[FIXED] $reason');
    }
  }

  // Xcode's target wizard also generates files the plugin does not use.
  for (final stray in kStrayXcodeFiles) {
    final file = File('${targetDir.path}/$stray');
    if (file.existsSync()) {
      file.deleteSync();
      print('[FIXED] Removed Xcode-generated ios/AlarmkitWidget/$stray');
    }
  }

  if (copied > 0) {
    print('[DONE] Copied $copied widget template files to ios/AlarmkitWidget/');
  }
  if (copied == 0 && restored == 0 && kept.isEmpty) {
    print('[OK]   ios/AlarmkitWidget/ templates match the plugin ($unchanged files)');
  }
  for (final fileName in kept) {
    print('[DIFF] ios/AlarmkitWidget/$fileName differs from the plugin template.');
    print('       Kept your version (it does not look like an Xcode placeholder).');
    print('       Re-run with --force to overwrite it with the plugin template.');
    if (_usesLegacyAppGroup(File('${targetDir.path}/$fileName'))) {
      print('[WARN] It still reads the removed "$kLegacyAppGroupId" App Group, so');
      print('       custom button colors and stop text will not show. Port your');
      print('       changes onto the new template (re-run with --force first).');
    }
  }
}

/// 32-bit FNV-1a hash, used to fingerprint widget template versions without
/// pulling in a crypto dependency.
int _fnv1a32(List<int> bytes) {
  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Whether [file] is an untouched copy of a template an earlier plugin
/// release shipped (see [kPreviousTemplateHashes]).
bool _isPreviousTemplate(String fileName, File file) =>
    kPreviousTemplateHashes[fileName]
        ?.contains(_fnv1a32(file.readAsBytesSync())) ??
    false;

/// Whether a (customized) widget file still depends on the App Group that
/// plugin versions <= 0.4.x used for button tints.
bool _usesLegacyAppGroup(File file) =>
    file.readAsStringSync().contains(kLegacyAppGroupId);

/// Heuristic for files generated by Xcode's Widget Extension target wizard:
/// they carry a `Created by ... on ...` header and/or the emoji-based sample
/// widget (`Text(entry.emoji)`, "This is an example widget."). Note the
/// plugin's own `AlarmkitWidget.swift` template is a standalone stub of that
/// sample and contains the emoji markers too — that's fine, because callers
/// always check byte-equality with the template before consulting this
/// heuristic, but it does mean edits to that one file that keep the sample
/// text are treated as placeholders and overwritten.
bool _looksLikeXcodePlaceholder(String content) {
  return content.contains('Created by') ||
      content.contains('Text(entry.emoji)') ||
      content.contains('This is an example widget.');
}

Directory? _findPluginDirectory(Directory projectRoot) {
  final configFile = File(
    '${projectRoot.path}/.dart_tool/package_config.json',
  );
  if (!configFile.existsSync()) return null;

  try {
    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>?;
    if (packages == null) return null;

    for (final pkg in packages) {
      final map = pkg as Map<String, dynamic>;
      if (map['name'] == 'flutter_alarmkit') {
        final rootUri = map['rootUri'] as String?;
        if (rootUri == null) continue;

        if (rootUri.startsWith('file://')) {
          return Directory(Uri.parse(rootUri).toFilePath());
        }
        // Relative path — resolve against .dart_tool/
        final dartToolDir = configFile.parent;
        final resolved = Uri.parse('${dartToolDir.uri}$rootUri');
        return Directory(resolved.toFilePath());
      }
    }
  } on Object catch (_) {
    // Fall through
  }
  return null;
}

// ---------------------------------------------------------------------------
// 4. Remove the legacy App Group
// ---------------------------------------------------------------------------
//
// Plugin versions <= 0.4.x wrote `group.flutter-alarmkit` into
// Runner.entitlements and told consumers to add it to the extension too. The
// plugin no longer needs an App Group, and that ID can only be registered by
// one developer account, so leaving it in place fails code signing ("An
// Application Group with Identifier 'group.flutter-alarmkit' is not
// available"). Only that entry is removed; other App Groups are kept, and the
// files themselves stay (build settings may reference them).

void _removeLegacyAppGroup(Directory projectRoot) {
  for (final file in _entitlementsFiles(projectRoot)) {
    final label = file.path.replaceFirst('${projectRoot.path}/', '');
    final updated = _stripLegacyAppGroup(file.readAsStringSync());
    if (updated == null) continue;
    file.writeAsStringSync(updated);
    print('[DONE] Removed the unused "$kLegacyAppGroupId" App Group from $label');
  }
}

/// Returns [content] without the legacy App Group entry (and without the
/// App Groups key if that leaves it empty), or null when there is nothing to
/// remove.
String? _stripLegacyAppGroup(String content) {
  final entry = RegExp(
    '[ \t]*<string>${RegExp.escape(kLegacyAppGroupId)}</string>[ \t]*\n?',
  );
  if (!entry.hasMatch(content)) return null;
  return content.replaceAll(entry, '').replaceAll(
        RegExp(
          r'[ \t]*<key>com\.apple\.security\.application-groups</key>\s*'
          r'<array>\s*</array>[ \t]*\n?',
        ),
        '',
      );
}

/// Every entitlements file the legacy App Group may live in: each one the
/// Xcode project signs with (`CODE_SIGN_ENTITLEMENTS`, which covers flavors
/// and per-configuration files), plus Runner.entitlements and the widget
/// extension's entitlements.
List<File> _entitlementsFiles(Directory projectRoot) {
  final iosPath = '${projectRoot.path}/ios';
  final paths = <String>{'$iosPath/Runner/Runner.entitlements'};
  final pbxproj = File(_pbxprojPath(projectRoot));
  if (pbxproj.existsSync()) {
    final setting = RegExp('CODE_SIGN_ENTITLEMENTS = "?([^";]+)"?;');
    for (final match in setting.allMatches(pbxproj.readAsStringSync())) {
      final value = match.group(1)!.trim().replaceFirst(r'$(SRCROOT)/', '');
      // Skip values built from other build settings; they can't be resolved
      // without Xcode.
      if (value.contains(r'$(')) continue;
      paths.add('$iosPath/$value');
    }
  }
  if (_findExtensionEntitlements(projectRoot) case final File extension) {
    paths.add(extension.path);
  }
  return [
    for (final path in paths)
      if (File(path).existsSync()) File(path),
  ];
}

// ---------------------------------------------------------------------------
// 5. Patch project format version (objectVersion)
// ---------------------------------------------------------------------------
//
// Creating the widget target in Xcode 16.3+/26 silently upgrades the project
// to objectVersion 70/77, which released CocoaPods versions cannot parse
// ("Unable to find compatibility version string for object version `70`",
// CocoaPods #12840 / #12889). Downgrading the declared version to 60 keeps
// both Xcode and CocoaPods happy.

String _pbxprojPath(Directory projectRoot) =>
    '${projectRoot.path}/ios/Runner.xcodeproj/project.pbxproj';

void _patchProjectObjectVersion(Directory projectRoot) {
  final file = File(_pbxprojPath(projectRoot));
  if (!file.existsSync()) {
    print('[SKIP] Runner.xcodeproj/project.pbxproj not found');
    return;
  }

  var content = file.readAsStringSync();
  final match = RegExp(r'objectVersion = (\d+);').firstMatch(content);
  if (match == null) {
    print('[WARN] Could not find objectVersion in project.pbxproj');
    return;
  }

  final version = match.group(1)!;
  if (version != '70' && version != '77') {
    print('[OK]   Project format (objectVersion = $version) is CocoaPods-compatible');
    return;
  }

  content = content.replaceFirst(match.group(0)!, 'objectVersion = 60;');
  file.writeAsStringSync(content);
  print('[FIXED] Project format downgraded (objectVersion $version -> 60)');
  print('        Xcode upgrades it when creating the widget target, but');
  print('        released CocoaPods versions cannot parse it (CocoaPods #12840).');
  print('        Xcode may re-upgrade it on a later save; if "pod install"');
  print('        fails again with an objectVersion error, re-run this setup.');
}

// ---------------------------------------------------------------------------
// 6. Fix Runner build-phase order
// ---------------------------------------------------------------------------
//
// Xcode appends "Embed Foundation Extensions" (and CocoaPods appends
// "[CP] Embed Pods Frameworks") after Flutter's "Thin Binary" script phase,
// which makes release builds fail with "Cycle inside Runner". Both embed
// phases must run before "Thin Binary".

void _fixBuildPhaseOrder(Directory projectRoot) {
  final file = File(_pbxprojPath(projectRoot));
  if (!file.existsSync()) {
    print('[SKIP] Runner.xcodeproj/project.pbxproj not found');
    return;
  }

  final content = file.readAsStringSync();
  final result = _reorderBuildPhases(content);
  if (result == null) {
    print('[OK]   Runner build phases are correctly ordered');
    return;
  }

  file.writeAsStringSync(result.content);
  print(
    '[FIXED] Moved ${result.movedPhases.join(' and ')} above "Thin Binary"',
  );
  print('        in the Runner build phases (prevents the "Cycle inside');
  print('        Runner" build error).');
}

class _ReorderResult {
  final String content;
  final List<String> movedPhases;
  _ReorderResult(this.content, this.movedPhases);
}

/// Phases that must run before Flutter's "Thin Binary" script phase.
const List<String> kEmbedPhaseNames = [
  'Embed Foundation Extensions',
  '[CP] Embed Pods Frameworks',
];

/// Returns the pbxproj content with misordered embed phases moved above
/// "Thin Binary" in the Runner target, or null if no reorder is needed.
_ReorderResult? _reorderBuildPhases(String content) {
  var searchFrom = 0;
  while (true) {
    final start = content.indexOf('buildPhases = (', searchFrom);
    if (start == -1) return null;
    final end = content.indexOf(');', start);
    if (end == -1) return null;

    final block = content.substring(start, end);
    // Only the Runner target has Flutter's "Thin Binary" phase.
    if (!block.contains('/* Thin Binary */')) {
      searchFrom = end;
      continue;
    }

    final lines = block.split('\n');
    final thinIndex =
        lines.indexWhere((l) => l.contains('/* Thin Binary */'));
    final movedLines = <String>[];
    final keptLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isMisplacedEmbed = i > thinIndex &&
          kEmbedPhaseNames.any((name) => line.contains('/* $name */'));
      if (isMisplacedEmbed) {
        movedLines.add(line);
      } else {
        keptLines.add(line);
      }
    }

    if (movedLines.isEmpty) return null;

    final newThinIndex =
        keptLines.indexWhere((l) => l.contains('/* Thin Binary */'));
    keptLines.insertAll(newThinIndex, movedLines);

    final movedNames = movedLines
        .map(
          (l) => kEmbedPhaseNames.firstWhere(
            (name) => l.contains('/* $name */'),
          ),
        )
        .map((name) => '"$name"')
        .toList();

    return _ReorderResult(
      content.replaceRange(start, end, keptLines.join('\n')),
      movedNames,
    );
  }
}

// ---------------------------------------------------------------------------
// Next steps
// ---------------------------------------------------------------------------

bool _widgetTargetExists(Directory projectRoot) {
  final file = File(_pbxprojPath(projectRoot));
  if (!file.existsSync()) return false;
  return file.readAsStringSync().contains('AlarmkitWidgetExtension.appex');
}

/// Whether the consumer app uses CocoaPods (a Podfile is present). Apps using
/// Swift Package Manager have no Podfile and skip `pod install`.
bool _usesCocoaPods(Directory projectRoot) =>
    File('${projectRoot.path}/ios/Podfile').existsSync();

void _printNextSteps(Directory projectRoot) {
  print('');
  if (!_widgetTargetExists(projectRoot)) {
    print('Remaining steps (do all the Xcode GUI work first, run setup last):');
    print('  1. Open ios/Runner.xcworkspace in Xcode');
    print('  2. File > New > Target > Widget Extension');
    print('     - Name it exactly "AlarmkitWidget"');
    print('     - Check only "Live Activity" (uncheck any other options)');
    print('     - Click Finish, then Activate if prompted');
    print('  3. Quit Xcode, then re-run "dart run flutter_alarmkit:setup"');
    print('     (Creating the target makes Xcode overwrite the widget files');
    print('      and upgrade the project format. Running setup LAST, with');
    print('      Xcode closed, restores the files and keeps the format');
    print('      CocoaPods can parse.)');
    print('  4. Build and run (with Xcode closed):');
    if (_usesCocoaPods(projectRoot)) {
      print('     cd ios && pod install && cd ..');
    }
    print('     flutter run --release');
  } else {
    print('Remaining step — build and run (with Xcode closed):');
    if (_usesCocoaPods(projectRoot)) {
      print('  cd ios && pod install && cd ..');
    }
    print('  flutter run --release');
    print('  (If the build fails with "Cycle inside Runner", run this setup');
    print('   once more, then build again.)');
  }
  print('');
  print('Verify your setup anytime with:');
  print('  dart run flutter_alarmkit:setup --doctor');
  print('');
}

// ---------------------------------------------------------------------------
// Doctor mode — read-only verification of every setup step
// ---------------------------------------------------------------------------

int _runDoctor(Directory projectRoot) {
  var failures = 0;
  var warnings = 0;

  void pass(String message) => print('[PASS] $message');
  void fail(String message, String hint) {
    failures++;
    print('[FAIL] $message');
    print('       -> $hint');
  }

  void warn(String message, String hint) {
    warnings++;
    print('[WARN] $message');
    print('       -> $hint');
  }

  const rerunHint = 'Run "dart run flutter_alarmkit:setup" to fix this.';

  // 1. Info.plist keys
  final plistFile = File('${projectRoot.path}/ios/Runner/Info.plist');
  if (!plistFile.existsSync()) {
    fail('ios/Runner/Info.plist not found', rerunHint);
  } else {
    final plist = plistFile.readAsStringSync();
    final missing = kRequiredPlistKeys
        .where((key) => !plist.contains('<key>$key</key>'))
        .toList();
    if (missing.isEmpty) {
      pass('Info.plist contains the ${kRequiredPlistKeys.length} required keys');
    } else {
      fail('Info.plist is missing: ${missing.join(', ')}', rerunHint);
    }
  }

  // 2. AppDelegate
  final appDelegateFile =
      File('${projectRoot.path}/ios/Runner/AppDelegate.swift');
  if (!appDelegateFile.existsSync()) {
    fail('ios/Runner/AppDelegate.swift not found', rerunHint);
  } else {
    final appDelegate = appDelegateFile.readAsStringSync();
    if (appDelegate.contains('FlutterImplicitEngineDelegate') &&
        appDelegate.contains('didInitializeImplicitFlutterEngine(')) {
      pass('AppDelegate.swift implements FlutterImplicitEngineDelegate');
    } else {
      fail(
        'AppDelegate.swift does not implement FlutterImplicitEngineDelegate',
        rerunHint,
      );
    }
  }

  // 3. Widget Extension target in Xcode project
  if (_widgetTargetExists(projectRoot)) {
    pass('Widget Extension target exists in Runner.xcodeproj');
  } else {
    fail(
      'No Widget Extension target in Runner.xcodeproj',
      'Create it in Xcode: File > New > Target > Widget Extension, '
          'name it "AlarmkitWidget", check only "Live Activity". '
          'Then re-run "dart run flutter_alarmkit:setup".',
    );
  }

  // 4. Widget templates in sync
  final pluginDir = _findPluginDirectory(projectRoot);
  if (pluginDir == null) {
    warn(
      'Could not locate the flutter_alarmkit plugin directory',
      'Run "flutter pub get", then re-run the doctor.',
    );
  } else {
    final templateDir = Directory('${pluginDir.path}/ios/WidgetTemplates');
    final targetDir = Directory('${projectRoot.path}/ios/AlarmkitWidget');
    final broken = <String>[]; // missing or Xcode-placeholder -> FAIL
    final customized = <String>[]; // intentional edits -> WARN (kept by setup)
    if (!templateDir.existsSync()) {
      warn(
        'Plugin widget templates not found at ${templateDir.path}',
        'Run "flutter pub get" / reinstall the plugin, then re-run the doctor.',
      );
    } else {
      for (final entity in templateDir.listSync()) {
        if (entity is! File) continue;
        final fileName = Uri.file(entity.path).pathSegments.last;
        final dest = File('${targetDir.path}/$fileName');
        if (!dest.existsSync()) {
          broken.add('$fileName (missing)');
        } else {
          final destContent = dest.readAsStringSync();
          if (destContent != entity.readAsStringSync()) {
            // Mirror setup's behavior: Xcode placeholders and untouched old
            // templates are replaced (a real FAIL), but deliberate
            // customizations are kept (just a WARN), so a customized-but-correct
            // consumer can still pass the doctor. A customization still built
            // on the removed App Group is broken, though.
            if (_looksLikeXcodePlaceholder(destContent)) {
              broken.add('$fileName (Xcode placeholder)');
            } else if (_isPreviousTemplate(fileName, dest)) {
              broken.add('$fileName (from a previous plugin version)');
            } else if (_usesLegacyAppGroup(dest)) {
              broken.add(
                '$fileName (customized, still reads the removed '
                '"$kLegacyAppGroupId" App Group)',
              );
            } else {
              customized.add(fileName);
            }
          }
        }
      }
      if (broken.isEmpty && customized.isEmpty) {
        pass('ios/AlarmkitWidget/ files match the plugin templates');
      } else if (broken.isEmpty) {
        warn(
          'Widget files customized: ${customized.join(', ')}',
          'Kept your versions (they do not look like Xcode placeholders). '
              'Run "dart run flutter_alarmkit:setup --force" to reset them to '
              'the plugin templates.',
        );
      } else {
        fail(
          'Widget files out of sync: ${broken.join(', ')}',
          '$rerunHint Xcode placeholders and previous plugin templates are '
              'replaced automatically; intentional customizations are kept '
              '(use --force to overwrite, then re-apply your changes).',
        );
        if (customized.isNotEmpty) {
          warn(
            'Widget files also customized: ${customized.join(', ')}',
            'Kept your versions; run with --force to reset them.',
          );
        }
      }
    }
    final strays = kStrayXcodeFiles
        .where(
          (name) => File('${targetDir.path}/$name').existsSync(),
        )
        .toList();
    if (strays.isNotEmpty) {
      fail(
        'Xcode-generated files present: ${strays.join(', ')}',
        rerunHint,
      );
    }
  }

  // 5. No leftover legacy App Group (breaks signing for other teams)
  final legacy = _entitlementsFiles(projectRoot)
      .where((f) => _stripLegacyAppGroup(f.readAsStringSync()) != null)
      .map((f) => f.path.replaceFirst('${projectRoot.path}/', ''))
      .toList();
  if (legacy.isEmpty) {
    pass('No entitlements reference the unused "$kLegacyAppGroupId" App Group');
  } else {
    fail(
      '"$kLegacyAppGroupId" App Group still in ${legacy.join(', ')} '
      '(no longer used; breaks code signing)',
      rerunHint,
    );
  }

  // 6. Project format parseable by CocoaPods
  final pbxprojFile = File(_pbxprojPath(projectRoot));
  if (pbxprojFile.existsSync()) {
    final pbxproj = pbxprojFile.readAsStringSync();
    final match = RegExp(r'objectVersion = (\d+);').firstMatch(pbxproj);
    final version = match?.group(1);
    if (version == null) {
      warn(
        'Could not determine project format (objectVersion not found in '
        'project.pbxproj)',
        'Verify ios/Runner.xcodeproj/project.pbxproj is intact.',
      );
    } else if (version == '70' || version == '77') {
      fail(
        'Project format (objectVersion = $version) breaks "pod install" '
        '(CocoaPods #12840)',
        rerunHint,
      );
    } else {
      pass('Project format (objectVersion = $version) is CocoaPods-compatible');
    }

    // 7. Build phase order
    if (_reorderBuildPhases(pbxproj) == null) {
      pass('Runner build phases are ordered (embed phases before Thin Binary)');
    } else {
      fail(
        'Embed phases run after "Thin Binary" (causes "Cycle inside Runner")',
        rerunHint,
      );
    }
  } else {
    fail('ios/Runner.xcodeproj/project.pbxproj not found', rerunHint);
  }

  print('');
  if (failures == 0 && warnings == 0) {
    print('All checks passed. You are ready to build:');
    if (_usesCocoaPods(projectRoot)) {
      print('  cd ios && pod install && cd ..');
    }
    print('  flutter run --release');
  } else {
    print(
      '$failures issue${failures == 1 ? '' : 's'}, '
      '$warnings warning${warnings == 1 ? '' : 's'} found.',
    );
  }
  print('');
  return failures == 0 ? 0 : 1;
}

File? _findExtensionEntitlements(Directory projectRoot) {
  final candidates = [
    '${projectRoot.path}/ios/AlarmkitWidgetExtension.entitlements',
    '${projectRoot.path}/ios/AlarmkitWidget/AlarmkitWidgetExtension.entitlements',
    '${projectRoot.path}/ios/AlarmkitWidget/AlarmkitWidget.entitlements',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file;
  }

  // Fallback: shallow search under ios/ for an extension entitlements file.
  final iosDir = Directory('${projectRoot.path}/ios');
  const skippedDirs = {'Pods', 'build', '.symlinks', 'Flutter'};
  try {
    for (final entity in iosDir.listSync()) {
      if (entity is Directory) {
        final dirName = Uri.directory(entity.path).pathSegments.lastWhere(
              (s) => s.isNotEmpty,
            );
        if (skippedDirs.contains(dirName)) continue;
        for (final child in entity.listSync()) {
          if (child is File &&
              child.path.endsWith('.entitlements') &&
              !child.path.endsWith('Runner.entitlements')) {
            return child;
          }
        }
      }
    }
  } on FileSystemException catch (_) {
    // Ignore unreadable directories.
  }
  return null;
}
