import 'package:flutter/foundation.dart';

/// Displayable metadata attached to an alarm and surfaced in its Live Activity.
///
/// Maps to a small AlarmKit `AlarmMetadata` value. All fields are optional, and
/// empty strings are treated as absent. The default widget renders the [icon]
/// next to the alarm title and the [subtitle] beneath it; consumers can restyle
/// that rendering in their own (CLI-copied) widget.
@immutable
class AlarmMetadata {
  /// An SF Symbol name shown alongside the alarm title (e.g. `"pills.fill"`).
  ///
  /// See https://developer.apple.com/sf-symbols/ for available symbols.
  final String? icon;

  /// A secondary line shown beneath the alarm title.
  final String? subtitle;

  /// Creates alarm metadata; all fields are optional.
  const AlarmMetadata({this.icon, this.subtitle});

  /// Builds [AlarmMetadata] from a platform-channel map. Empty strings are
  /// normalized to null.
  factory AlarmMetadata.fromMap(Map<String, dynamic> map) {
    return AlarmMetadata(
      icon: _clean(map['icon'] as String?),
      subtitle: _clean(map['subtitle'] as String?),
    );
  }

  static String? _clean(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Whether no fields are set (after empty-string normalization).
  bool get isEmpty => _clean(icon) == null && _clean(subtitle) == null;

  /// Serializes to a map for the method channel, omitting null/empty fields.
  Map<String, dynamic> toMap() {
    final cleanIcon = _clean(icon);
    final cleanSubtitle = _clean(subtitle);
    return {
      if (cleanIcon != null) 'icon': cleanIcon,
      if (cleanSubtitle != null) 'subtitle': cleanSubtitle,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmMetadata &&
          _clean(other.icon) == _clean(icon) &&
          _clean(other.subtitle) == _clean(subtitle);

  @override
  int get hashCode => Object.hash(_clean(icon), _clean(subtitle));

  @override
  String toString() => 'AlarmMetadata(icon: $icon, subtitle: $subtitle)';
}
