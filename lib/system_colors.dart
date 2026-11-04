import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The phone's own accent colour, where the system shares one: Android 12+
/// derives it from the wallpaper (Material You), macOS / Windows / Linux
/// have a user accent colour. iPhone gives apps no system colour, so this
/// is null there (and on the web, and on older Android).
class SystemColors {
  SystemColors._();

  /// The system accent's hue (HSL degrees), or null.
  static Future<double?> accentHue() async {
    if (kIsWeb) return null;
    try {
      final palette = await DynamicColorPlugin.getCorePalette()
          .timeout(const Duration(milliseconds: 600));
      if (palette != null) {
        // tone 40 is the system's own accent shade for light surfaces
        return HSLColor.fromColor(Color(palette.primary.get(40))).hue;
      }
      final accent = await DynamicColorPlugin.getAccentColor()
          .timeout(const Duration(milliseconds: 600));
      if (accent != null) return HSLColor.fromColor(accent).hue;
    } on PlatformException catch (e) {
      debugPrint('system colours: ${e.message}');
    } on MissingPluginException {
      // no plugin on this platform
    } on Exception {
      // a slow or failing platform channel: fall back to the default
    }
    return null;
  }
}
