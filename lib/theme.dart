import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Design tokens, dark + light. Restraint rules:
// - one quiet accent (sage green), muted enough to sit still on screen
// - hierarchy from gray values + font weight, never from color
// - big radius, almost no borders

class _Palette {
  final Color bg, card, cardHi, ink, sub, faint, accent, onAccent, line;
  final Color tier1, tier2, tier3;
  final Brightness overlayBrightness; // system chrome icon brightness

  const _Palette({
    required this.bg,
    required this.card,
    required this.cardHi,
    required this.ink,
    required this.sub,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.line,
    required this.tier1,
    required this.tier2,
    required this.tier3,
    required this.overlayBrightness,
  });
}

class Iron {
  Iron._();

  static final ValueNotifier<int> notifier = ValueNotifier(0);

  /// 'system' | 'dark' | 'light'
  static String appearance = 'system';
  static bool _dark = true;

  static void setAppearance(String setting, {bool platformDark = true}) {
    appearance = setting;
    _dark = switch (setting) {
      'dark' => true,
      'light' => false,
      _ => platformDark,
    };
    SystemChrome.setSystemUIOverlayStyle(overlay);
    notifier.value++;
  }

  // ---- dark palette (fresh green, halfway between neon and sage) -------
  static const _darkPalette = _Palette(
    bg: Color(0xFF000000),
    card: Color(0xFF17181C),
    cardHi: Color(0xFF212226),
    ink: Color(0xFFF2F2F7),
    sub: Color(0xFFA6A6AD), // slightly brighter than before
    faint: Color(0xFF63636B),
    accent: Color(0xFF4EBB8A), // fresh green — between neon #30D158 and sage
    onAccent: Color(0xFF0A1812),
    line: Color(0x14F2F2F7),
    tier1: Color(0xFF5FB3D9),
    tier2: Color(0xFFA48FE0),
    tier3: Color(0xFFD97B8C),
    overlayBrightness: Brightness.light, // light icons on dark bg
  );

  // ---- light palette (warm paper + lively-but-not-neon accent) ----------
  static const _lightPalette = _Palette(
    bg: Color(0xFFFAF9F6),
    card: Color(0xFFFFFFFF),
    cardHi: Color(0xFFF0EFEA),
    ink: Color(0xFF1B1B1E),
    sub: Color(0xFF5F5F66),
    faint: Color(0xFF9B9BA1),
    accent: Color(0xFF2E9E6E), // livelier sage for white-bg contrast
    onAccent: Color(0xFFFFFFFF),
    line: Color(0x14000000),
    tier1: Color(0xFF4A92C6),
    tier2: Color(0xFF8477C8),
    tier3: Color(0xFFCC7180),
    overlayBrightness: Brightness.dark, // dark icons on light bg
  );

  static _Palette get _p => _dark ? _darkPalette : _lightPalette;

  static bool get isDark => _dark;

  static Color get bg => _p.bg;
  static Color get card => _p.card;
  static Color get cardHi => _p.cardHi;
  static Color get ink => _p.ink;
  static Color get sub => _p.sub;
  static Color get faint => _p.faint;
  static Color get accent => _p.accent;
  static Color get onAccent => _p.onAccent;
  static Color get line => _p.line;

  static Map<int, Color> get tierColor => {1: _p.tier1, 2: _p.tier2, 3: _p.tier3};

  static SystemUiOverlayStyle get overlay => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _p.overlayBrightness,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: _p.overlayBrightness,
      );

  // ---- geometry (shared across both palettes) --------------------------
  static const rL = Radius.circular(16);
  static const rM = Radius.circular(12);
  static const rS = Radius.circular(10);
  static const rBtn = Radius.circular(14);

  // ---- text ------------------------------------------------------------
  static TextStyle hero(double size,
          {Color? color, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
          fontSize: size,
          color: color ?? ink,
          fontWeight: weight,
          height: 1.1,
          letterSpacing: -0.4);

  static TextStyle body(double size,
          {Color? color, FontWeight weight = FontWeight.normal}) =>
      TextStyle(
          fontSize: size,
          color: color ?? ink,
          fontWeight: weight,
          height: 1.4);

  static TextStyle caption({Color? color}) =>
      TextStyle(fontSize: 13, color: color ?? sub, height: 1.35);

  static ThemeData theme() {
    final p = _p;
    return ThemeData(
      useMaterial3: true,
      brightness: _dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme(
        brightness: _dark ? Brightness.dark : Brightness.light,
        primary: p.accent,
        onPrimary: p.onAccent,
        surface: p.bg,
        onSurface: p.ink,
        outline: p.line,
        secondary: p.sub,
        onSecondary: p.onAccent,
        error: const Color(0xFFB4534A),
        onError: Colors.white,
      ),
      dividerColor: p.line,
      hintColor: p.faint,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: p.ink),
        iconTheme: IconThemeData(color: p.ink),
        systemOverlayStyle: overlay,
      ),
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(rL)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(rBtn)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          backgroundColor: p.cardHi,
          side: BorderSide.none,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(rBtn)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.sub,
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.cardHi,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardHi,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(rM), borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(rM), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(rM),
            borderSide: BorderSide(color: p.accent, width: 1.5)),
        labelStyle: TextStyle(color: p.sub, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.cardHi,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(rS)),
        labelStyle: TextStyle(color: p.sub, fontSize: 12),
      ),
      listTileTheme: ListTileThemeData(
        textColor: p.ink,
        iconColor: p.sub,
        subtitleTextStyle: TextStyle(color: p.sub, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.cardHi,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(rL)),
        titleTextStyle:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.cardHi,
        contentTextStyle: TextStyle(color: p.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bg,
        indicatorColor: p.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected) ? p.ink : p.faint)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color:
                states.contains(WidgetState.selected) ? p.accent : p.faint,
            size: 22)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.accent
                : p.sub),
      ),
    );
  }
}

/// Full-width accent action block, 52px.

class IronButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const IronButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

/// Quiet matte card.

class IronCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const IronCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Iron.card,
        borderRadius: const BorderRadius.all(Iron.rL),
        boxShadow: Iron.isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: child,
    );
  }
}

/// Segmented progress: one rounded segment per exercise.

class BarbellProgress extends StatelessWidget {
  final int current; // 1-based
  final int total;

  const BarbellProgress({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                color: i < current ? Iron.accent : Iron.cardHi,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
