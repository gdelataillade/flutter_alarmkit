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
class AlarmButtonConfig {
  /// The button label text (e.g., "Stop", "Pause", "Resume", "Repeat").
  final String text;

  /// SF Symbol name for the button icon (e.g., "stop.circle", "pause.circle").
  ///
  /// See https://developer.apple.com/sf-symbols/ for available icons.
  final String icon;

  /// Hex color string for the button text color (e.g., "#FFFFFF").
  ///
  /// If null, defaults to the system default for the button style.
  final String? textColor;

  /// Hex color string for the button background/tint (e.g., "#FF0000").
  ///
  /// This controls the `.tint()` modifier on the button view, separate from
  /// AlarmButton's textColor. If null, defaults to the standard tint for each
  /// button type (red for stop, orange for pause, green for resume).
  final String? tintColor;

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
}
