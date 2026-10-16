// Prints the FNV-1a fingerprint of each given file, in the form used by
// `kPreviousTemplateHashes` in bin/setup.dart. Run it on the outgoing version
// of a widget template before changing it:
//
//   git show HEAD:ios/WidgetTemplates/AlarmkitWidgetLiveActivity.swift > /tmp/old.swift
//   dart run tool/template_hash.dart /tmp/old.swift
//
// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) {
  for (final path in args) {
    var hash = 0x811c9dc5;
    for (final byte in File(path).readAsBytesSync()) {
      hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
    }
    print('0x${hash.toRadixString(16).padLeft(8, '0')}  $path');
  }
}
