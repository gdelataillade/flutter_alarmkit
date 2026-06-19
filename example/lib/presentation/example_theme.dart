import 'package:flutter/cupertino.dart';

/// Small, app-local visual system for the example project.
///
/// Keeping these values here makes the demo easy to restyle without suggesting
/// that consumers need to adopt a particular UI framework or theme.
abstract final class ExampleTheme {
  static const accent = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF5A3C),
    darkColor: Color(0xFFFF6B52),
  );
  static const canvas = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF3F5F7),
    darkColor: Color(0xFF0C0F12),
  );
  static const surface = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: Color(0xFF171B20),
  );
  static const subtleSurface = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF8F9FA),
    darkColor: Color(0xFF20252B),
  );
  static const border = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE4E8EC),
    darkColor: Color(0xFF2B3138),
  );
  static const secondaryText = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF66717D),
    darkColor: Color(0xFFA4ADB7),
  );

  static Color resolve(BuildContext context, Color color) {
    return CupertinoDynamicColor.resolve(color, context);
  }

  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: resolve(context, surface),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: resolve(context, border)),
    );
  }
}
