// Test fixtures pass plain map literals to the model factory; const-ness is
// irrelevant here.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmMetadata.toMap', () {
    test('includes set fields', () {
      const metadata = AlarmMetadata(icon: 'pills.fill', subtitle: 'Take 2');
      expect(metadata.toMap(), {'icon': 'pills.fill', 'subtitle': 'Take 2'});
    });

    test('omits null fields', () {
      expect(const AlarmMetadata(icon: 'pills.fill').toMap(), {'icon': 'pills.fill'});
    });

    test('omits empty-string fields', () {
      expect(const AlarmMetadata(icon: '', subtitle: 'Hi').toMap(), {'subtitle': 'Hi'});
      expect(const AlarmMetadata().toMap(), <String, dynamic>{});
    });
  });

  group('AlarmMetadata.fromMap', () {
    test('round-trips set fields', () {
      final metadata = AlarmMetadata.fromMap({'icon': 'bell', 'subtitle': 'Wake'});
      expect(metadata.icon, 'bell');
      expect(metadata.subtitle, 'Wake');
    });

    test('normalizes empty strings to null', () {
      final metadata = AlarmMetadata.fromMap({'icon': '', 'subtitle': ''});
      expect(metadata.icon, isNull);
      expect(metadata.subtitle, isNull);
      expect(metadata.isEmpty, isTrue);
    });
  });

  group('AlarmMetadata equality and isEmpty', () {
    test('empty string and null compare equal', () {
      expect(const AlarmMetadata(icon: ''), const AlarmMetadata());
      expect(const AlarmMetadata(icon: '').hashCode, const AlarmMetadata().hashCode);
    });

    test('differs by field value', () {
      expect(const AlarmMetadata(icon: 'a'), isNot(const AlarmMetadata(icon: 'b')));
    });

    test('isEmpty reflects content', () {
      expect(const AlarmMetadata().isEmpty, isTrue);
      expect(const AlarmMetadata(subtitle: 'x').isEmpty, isFalse);
    });
  });
}
