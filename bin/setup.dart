// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  print('');
  print('flutter_alarmkit setup');
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

  _patchInfoPlist(projectRoot);
  _patchAppDelegate(projectRoot);
  _patchPodfile(projectRoot);
  _copyWidgetTemplates(projectRoot);
  _createEntitlements(projectRoot);

  print('');
  print('Setup complete!');
  print('');
  print('Remaining manual steps:');
  print('  1. Open ios/Runner.xcworkspace in Xcode');
  print('  2. File > New > Target > Widget Extension');
  print('     - Name it "AlarmkitWidget"');
  print('     - Check only "Live Activity"');
  print('     - Click Finish, then Activate if prompted');
  print('  3. Delete the generated Swift files in the AlarmkitWidget group');
  print('  4. Drag the files from ios/AlarmkitWidget/ into the');
  print('     AlarmkitWidget group in Xcode');
  print('  5. For BOTH the Runner and AlarmkitWidgetExtension targets:');
  print('     - Go to Signing & Capabilities > + Capability > App Groups');
  print('     - Add "group.flutter-alarmkit"');
  print('  6. Run:');
  print('     cd ios && pod install && cd ..');
  print('     flutter run --release');
  print('');
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
    final lastBrace = content.lastIndexOf('}');
    if (lastBrace == -1) {
      print(
        '[WARN] Could not find closing brace in AppDelegate.swift. Manual edit needed.',
      );
      return;
    }

    content =
        '${content.substring(0, lastBrace)}$methodToAdd${content.substring(lastBrace)}';
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
// 3. Patch Podfile
// ---------------------------------------------------------------------------

void _patchPodfile(Directory projectRoot) {
  final filePath = '${projectRoot.path}/ios/Podfile';
  final file = File(filePath);
  if (!file.existsSync()) {
    print('[SKIP] Podfile not found');
    return;
  }

  var content = file.readAsStringSync();

  if (RegExp(
    r'''^\s*target\s+['"]AlarmkitWidgetExtension['"]\s+do\b''',
    multiLine: true,
  ).hasMatch(content)) {
    print('[OK]   Podfile already contains AlarmkitWidgetExtension target');
    return;
  }

  const snippet = '''

  target 'AlarmkitWidgetExtension' do
    inherit! :search_paths
    use_frameworks!
    pod 'flutter_alarmkit', :path => '.symlinks/plugins/flutter_alarmkit/ios'
  end
''';

  final runnerMatch = RegExp(
    r'''^\s*target\s+['"]Runner['"]\s+do\b''',
    multiLine: true,
  ).firstMatch(content);
  if (runnerMatch == null) {
    print(
      "[WARN] Could not find Runner target in Podfile. Manual edit needed.",
    );
    return;
  }

  // Walk through lines after Runner target to find the matching `end`.
  final afterRunner = content.substring(runnerMatch.start);
  final lines = afterRunner.split('\n');
  var depth = 0;
  var charOffset = 0;

  for (final line in lines) {
    final trimmed = line.split('#').first.trim();
    if (RegExp(r'''^target\s+['"][^'"]+['"]\s+do\b''').hasMatch(trimmed)) {
      depth++;
    }
    if (trimmed == 'end') {
      depth--;
      if (depth == 0) {
        final endIndex = runnerMatch.start + charOffset;
        content =
            '${content.substring(0, endIndex)}$snippet\n${content.substring(endIndex)}';
        file.writeAsStringSync(content);
        print('[DONE] Podfile patched with AlarmkitWidgetExtension target');
        return;
      }
    }
    charOffset += line.length + 1; // +1 for the \n
  }

  print(
    '[WARN] Could not find end of Runner target in Podfile. Manual edit needed.',
  );
}

// ---------------------------------------------------------------------------
// 4. Copy widget template files
// ---------------------------------------------------------------------------

void _copyWidgetTemplates(Directory projectRoot) {
  final targetDir = Directory('${projectRoot.path}/ios/AlarmkitWidget');

  if (targetDir.existsSync()) {
    print('[OK]   ios/AlarmkitWidget/ already exists, skipping copy');
    return;
  }

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

  targetDir.createSync(recursive: true);
  var count = 0;
  for (final entity in templateDir.listSync()) {
    if (entity is File) {
      final fileName = Uri.file(entity.path).pathSegments.last;
      entity.copySync('${targetDir.path}/$fileName');
      count++;
    }
  }

  print('[DONE] Copied $count widget template files to ios/AlarmkitWidget/');
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
  } catch (_) {
    // Fall through
  }
  return null;
}

// ---------------------------------------------------------------------------
// 5. Create App Group entitlements
// ---------------------------------------------------------------------------

void _createEntitlements(Directory projectRoot) {
  final entitlementsPath = '${projectRoot.path}/ios/Runner/Runner.entitlements';
  final file = File(entitlementsPath);

  if (file.existsSync()) {
    var content = file.readAsStringSync();
    if (content.contains('group.flutter-alarmkit')) {
      print('[OK]   Runner.entitlements already contains App Group');
      return;
    }

    // Add App Group to existing entitlements
    if (content.contains('com.apple.security.application-groups')) {
      final arrayEnd = content.indexOf(
        '</array>',
        content.indexOf('com.apple.security.application-groups'),
      );
      if (arrayEnd != -1) {
        content =
            '${content.substring(0, arrayEnd)}\t\t<string>group.flutter-alarmkit</string>\n\t${content.substring(arrayEnd)}';
        file.writeAsStringSync(content);
        print('[DONE] Added App Group to existing Runner.entitlements');
        return;
      }
    }

    // Add new App Groups key
    final dictEnd = content.lastIndexOf('</dict>');
    if (dictEnd != -1) {
      const groupsEntry = '''
\t<key>com.apple.security.application-groups</key>
\t<array>
\t\t<string>group.flutter-alarmkit</string>
\t</array>''';
      content =
          '${content.substring(0, dictEnd)}$groupsEntry\n${content.substring(dictEnd)}';
      file.writeAsStringSync(content);
      print('[DONE] Added App Group to Runner.entitlements');
      return;
    }
  }

  // Create new entitlements file
  const entitlementsContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>com.apple.security.application-groups</key>
\t<array>
\t\t<string>group.flutter-alarmkit</string>
\t</array>
</dict>
</plist>
''';
  file.writeAsStringSync(entitlementsContent);
  print('[DONE] Created Runner.entitlements with App Group');
  print(
    '       NOTE: You must also add this entitlements file to your',
  );
  print(
    '       Runner target in Xcode (Build Settings > Code Signing Entitlements).',
  );
}
