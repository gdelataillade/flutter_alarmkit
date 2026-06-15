import 'package:flutter/foundation.dart';

/// Configuration for a single alarm button displayed in the Live Activity.
///
/// Maps to AlarmKit's AlarmButton (text, textColor, systemImageName)
/// plus an additional [tintColor] for the button's background/tint.
///
/// Example:
/// ```dart
/// AlarmButtonConfig(
///   text: 'Stop',
///   icon: 'stop.circle',
///   textColor: '#FFFFFF',
///   tintColor: '#FF0000',
/// )
/// ```
@immutable
class AlarmButtonConfig {
  /// The button label text (e.g., "Stop", "Pause", "Resume", "Repeat").
  final String text;

  /// SF Symbol name for the button icon (e.g., "stop.circle", "pause.circle").
  ///
  /// See https://developer.apple.com/sf-symbols/ for available icons.
  final String icon;

  /// Hex color string for the button text color.
  ///
  /// Must be in the form `#RRGGBB` (6 hex digits, the leading `#` is optional).
  /// Shorthand (`#FFF`), alpha (`#RRGGBBAA`), and named colors are not
  /// supported; invalid values are ignored and the default is used.
  ///
  /// If null, defaults to the system default for the button style.
  final String? textColor;

  /// Hex color string for the button background/tint.
  ///
  /// Must be in the form `#RRGGBB` (6 hex digits, the leading `#` is optional).
  /// Shorthand (`#FFF`), alpha (`#RRGGBBAA`), and named colors are not
  /// supported; invalid values are ignored and the default is used.
  ///
  /// This controls the `.tint()` modifier on the button view, separate from
  /// AlarmButton's textColor. If null, defaults to the standard tint for each
  /// button type (red for stop, orange for pause, green for resume).
  final String? tintColor;

  /// Creates a button configuration with the given [text] and [icon].
  const AlarmButtonConfig({
    required this.text,
    required this.icon,
    this.textColor,
    this.tintColor,
  });

  /// Serializes this configuration to a map for method channel transport.
  Map<String, String?> toMap() => {
        'text': text,
        'icon': icon,
        'textColor': textColor,
        'tintColor': tintColor,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmButtonConfig &&
          other.text == text &&
          other.icon == icon &&
          other.textColor == textColor &&
          other.tintColor == tintColor;

  @override
  int get hashCode => Object.hash(text, icon, textColor, tintColor);

  @override
  String toString() => 'AlarmButtonConfig(text: $text, icon: $icon, '
      'textColor: $textColor, tintColor: $tintColor)';
}
