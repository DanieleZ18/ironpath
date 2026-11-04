import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

// Design tokens, light + dark — "soft & friendly", Morandi (v4.1, 2026-10-29).
// - rounded everything: 24px cards, 20px buttons, pill chips
// - colour carries meaning, quietly: each tier owns a dusty hue (mist blue /
//   grey violet / clay rose) shown as soft tinted blocks; one sage accent
//   marks actions + progress
// - hues are FILL tones (dots, rings, blocks, glyphs). Wherever a hue is
//   used for text or behind text, [Iron.inkOf] derives a deeper shade of the
//   same hue that reads at 4.5:1 — so the palette can stay muted
// - Nunito (bundled, rounded terminals) for Latin + numerals; CJK falls
//   back to the system font

class _Palette {
  final Color bg, card, cardHi, ink, sub, faint, accent, onAccent, line;
  final Color tier1, tier2, tier3;
  final Color danger;
  final double tintAmount; // how much hue goes into a tinted block
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
    required this.danger,
    required this.tintAmount,
    required this.overlayBrightness,
  });
}

/// A colour theme: one accent and three tier hues for each brightness.
/// Surfaces (beige paper / charcoal) are shared; [surfaceTint] leans the
/// page and inset surfaces a few percent toward the accent so the whole
/// screen feels tuned to the choice.
class ThemeSpec {
  final String id;
  final String nameEn;
  final String nameZh;
  final List<Color> light; // accent, tier1, tier2, tier3
  final List<Color> dark;
  final double surfaceTint;

  const ThemeSpec({
    required this.id,
    required this.nameEn,
    required this.nameZh,
    required this.light,
    required this.dark,
    this.surfaceTint = 0.03,
  });

  String name(bool zh) => zh ? nameZh : nameEn;

  /// A full theme from any hue: a low-saturation accent at that hue and
  /// three tier hues spread around the wheel (+120°, +180°, +240°). Each
  /// tone is solved for a contrast target rather than a fixed lightness,
  /// so every hue comes out equally legible (greens and yellows would
  /// otherwise be far lighter than blues at the same HSL lightness).
  factory ThemeSpec.custom(double hue) {
    Color tone(double h, double s, double target) => _solve(
        HSLColor.fromAHSL(1, h % 360, s, 0.62).toColor(),
        const Color(0xFFFFFFFF),
        target,
        darken: true);
    final light = [
      tone(hue, 0.18, 4.4),
      tone(hue + 120, 0.24, 3.6),
      tone(hue + 180, 0.22, 3.6),
      tone(hue + 240, 0.26, 3.6),
    ];
    return ThemeSpec(
      id: 'custom',
      nameEn: 'Custom',
      nameZh: '自定义',
      light: light,
      dark: [for (final c in light) _liftForDark(c)],
    );
  }
}

/// Step [c]'s HSL lightness (darker or lighter) until it reaches [target]
/// contrast against [against]. Used to solve custom tones and as a safety
/// clamp on preset tones.
Color _solve(Color c, Color against, double target, {required bool darken}) {
  var hsl = HSLColor.fromColor(c);
  for (var i = 0;
      i < 60 && Iron._contrast(hsl.toColor(), against) < target;
      i++) {
    final l = (hsl.lightness + (darken ? -0.01 : 0.01)).clamp(0.0, 1.0);
    hsl = hsl.withLightness(l);
  }
  return hsl.toColor();
}

/// Dark-mode version of a light tone: same hue, a touch more saturation,
/// lifted to a pastel that reads on charcoal.
Color _liftForDark(Color c) {
  final h = HSLColor.fromColor(c);
  return _solve(
      h
          .withSaturation((h.saturation * 1.08 + 0.04).clamp(0.0, 1.0))
          .withLightness(0.72)
          .toColor(),
      _darkBase.card,
      5.0,
      darken: false);
}

// Shared surfaces. Light = warm grey-beige paper (米色), dark = grey
// charcoal (黑色); themes only lean them slightly (ThemeSpec.surfaceTint).
const _lightBase = _Palette(
  bg: Color(0xFFF4F2EE),
  card: Color(0xFFFFFFFF),
  cardHi: Color(0xFFECE9E3),
  ink: Color(0xFF2E302E),
  sub: Color(0xFF61635E),
  faint: Color(0xFF6F716B),
  accent: Color(0xFF5E7F6A),
  onAccent: Color(0xFFFFFFFF),
  line: Color(0x1A2E302E),
  tier1: Color(0xFF6F8BA6),
  tier2: Color(0xFF8A7AA0),
  tier3: Color(0xFFB07A6A),
  danger: Color(0xFFB07A6A),
  tintAmount: 0.14,
  overlayBrightness: Brightness.dark, // dark icons on light bg
);

const _darkBase = _Palette(
  bg: Color(0xFF191A19),
  card: Color(0xFF232523),
  cardHi: Color(0xFF2D302D),
  ink: Color(0xFFEDECE8),
  sub: Color(0xFFB2B1AB),
  faint: Color(0xFF8E8D87),
  accent: Color(0xFF8FB09A),
  onAccent: Color(0xFF172019),
  line: Color(0x1AEDECE8),
  tier1: Color(0xFF9DB3C9),
  tier2: Color(0xFFB4A8C8),
  tier3: Color(0xFFD0A595),
  danger: Color(0xFFD0A595),
  tintAmount: 0.18,
  overlayBrightness: Brightness.light, // light icons on dark bg
);

class Iron {
  Iron._();

  static final ValueNotifier<int> notifier = ValueNotifier(0);

  /// 'system' | 'dark' | 'light'
  static String appearance = 'system';
  static bool _dark = false;

  static void setAppearance(String setting, {bool platformDark = false}) {
    appearance = setting;
    _dark = switch (setting) {
      'dark' => true,
      'light' => false,
      _ => platformDark,
    };
    SystemChrome.setSystemUIOverlayStyle(overlay);
    notifier.value++;
  }

  static const fontFamily = 'Nunito';

  // ---- colour themes -----------------------------------------------------
  // Each preset takes its colours from somewhere training happens. Sage is
  // the default and reproduces the original palette exactly.

  static const presets = <ThemeSpec>[
    ThemeSpec(
      id: 'sage',
      nameEn: 'Sage',
      nameZh: '鼠尾草',
      light: [
        Color(0xFF5E7F6A), // sage
        Color(0xFF6F8BA6), // mist blue
        Color(0xFF8A7AA0), // grey violet
        Color(0xFFB07A6A), // clay rose
      ],
      dark: [
        Color(0xFF8FB09A),
        Color(0xFF9DB3C9),
        Color(0xFFB4A8C8),
        Color(0xFFD0A595),
      ],
      surfaceTint: 0,
    ),
    // tiers follow the bumper-plate colour code: harder = heavier plate
    ThemeSpec(
      id: 'plates',
      nameEn: 'Plates',
      nameZh: '杠铃片',
      light: [
        Color(0xFF56616B), // iron
        Color(0xFF9A7F3D), // yellow 15 kg
        Color(0xFF5E7DA6), // blue 20 kg
        Color(0xFFA65D57), // red 25 kg
      ],
      dark: [
        Color(0xFFACB8C3),
        Color(0xFFDBC795),
        Color(0xFF9FB4D1),
        Color(0xFFD3A19D),
      ],
    ),
    // chalk and graphite: tiers step from light to dark grey
    ThemeSpec(
      id: 'chalk',
      nameEn: 'Chalk',
      nameZh: '镁粉',
      light: [
        Color(0xFF474C51),
        Color(0xFF80858A),
        Color(0xFF6B7075),
        Color(0xFF4C5156),
      ],
      dark: [
        Color(0xFFD5D9DC),
        Color(0xFF8E959B),
        Color(0xFFB3B9BE),
        Color(0xFFD9DDE0),
      ],
      surfaceTint: 0,
    ),
    // an outdoor run: moss, river, bark, red earth
    ThemeSpec(
      id: 'trail',
      nameEn: 'Trail',
      nameZh: '林道',
      light: [
        Color(0xFF687A4C),
        Color(0xFF5C8A86),
        Color(0xFF9A7E55),
        Color(0xFF9A5E4B),
      ],
      dark: [
        Color(0xFFBCCCA3),
        Color(0xFFA5CAC7),
        Color(0xFFD1BC9E),
        Color(0xFFD5A89A),
      ],
    ),
    // pool tiles, water, lavender towels, coral lane ropes
    ThemeSpec(
      id: 'pool',
      nameEn: 'Pool',
      nameZh: '泳池',
      light: [
        Color(0xFF4C8587),
        Color(0xFF6A8BB6),
        Color(0xFF8981B3),
        Color(0xFFB57662),
      ],
      dark: [
        Color(0xFF9FCED0),
        Color(0xFF9AB4D5),
        Color(0xFFA9A2CE),
        Color(0xFFD6A899),
      ],
    ),
    // an early run: heather, morning sky, sunrise ochre, rose
    ThemeSpec(
      id: 'dawn',
      nameEn: 'Dawn',
      nameZh: '晨跑',
      light: [
        Color(0xFF84688A),
        Color(0xFF648AA3),
        Color(0xFFA8834F),
        Color(0xFFB06D73),
      ],
      dark: [
        Color(0xFFC0AAC5),
        Color(0xFFA1BCCF),
        Color(0xFFD6BD99),
        Color(0xFFD19EA2),
      ],
    ),
  ];

  static ThemeSpec _spec = presets.first;

  /// The active theme: a preset id, or 'custom' with [customHue].
  static String get themeId => _spec.id;
  static double customHue = 150;
  static ThemeSpec get spec => _spec;

  static ThemeSpec specFor(String id, {double? hue}) => id == 'custom'
      ? ThemeSpec.custom(hue ?? customHue)
      : presets.firstWhere((p) => p.id == id, orElse: () => presets.first);

  static void setTheme(String id, {double? hue}) {
    if (hue != null) customHue = hue;
    _spec = specFor(id, hue: customHue);
    _light = _build(_lightBase, _spec.light, _spec.surfaceTint);
    _darkP = _build(_darkBase, _spec.dark, _spec.surfaceTint);
    _inkCache.clear();
    SystemChrome.setSystemUIOverlayStyle(overlay);
    notifier.value++;
  }

  static _Palette _build(_Palette base, List<Color> tones, double lean) {
    final dark = base.overlayBrightness == Brightness.light;
    final accent = tones[0];
    Color leanTo(Color c, double amount) => Color.lerp(c, accent, amount)!;
    final card = dark ? leanTo(base.card, lean * 0.6) : base.card;
    // safety clamp: fills keep 3:1 against their own tinted block
    Color fill(Color c) {
      final tint = Color.lerp(card, c, base.tintAmount)!;
      return _solve(c, tint, 3.0, darken: !dark);
    }

    final h = HSLColor.fromColor(accent);
    return _Palette(
      bg: leanTo(base.bg, lean),
      card: card,
      cardHi: leanTo(base.cardHi, lean),
      ink: base.ink,
      sub: base.sub,
      faint: base.faint,
      accent: fill(accent),
      onAccent: dark
          ? HSLColor.fromAHSL(1, h.hue, 0.22, 0.10).toColor()
          : base.onAccent,
      line: base.line,
      tier1: fill(tones[1]),
      tier2: fill(tones[2]),
      tier3: fill(tones[3]),
      danger: base.danger,
      tintAmount: base.tintAmount,
      overlayBrightness: base.overlayBrightness,
    );
  }

  static _Palette _light = _build(_lightBase, presets.first.light, 0);
  static _Palette _darkP = _build(_darkBase, presets.first.dark, 0);

  /// The accent + tier fills a theme would use in the current brightness —
  /// for previews (theme swatches) without switching.
  static List<Color> previewTones(ThemeSpec s) {
    final p = _build(_dark ? _darkBase : _lightBase, _dark ? s.dark : s.light,
        s.surfaceTint);
    return [p.accent, p.tier1, p.tier2, p.tier3];
  }

  static _Palette get _p => _dark ? _darkP : _light;

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
  static Color get danger => _p.danger;

  static Map<int, Color> get tierColor =>
      {1: _p.tier1, 2: _p.tier2, 3: _p.tier3};

  /// Tier hue, accent for anything outside 1-3 (custom plans).
  static Color tier(int t) => tierColor[t] ?? accent;

  /// Soft block colour: [c] mixed into the card surface. Text in [c] on a
  /// tint stays above 4.5:1 for every palette hue.
  static Color tint(Color c) => Color.lerp(card, c, _p.tintAmount)!;

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) /
        (la > lb ? lb + 0.05 : la + 0.05);
  }

  static final Map<(int, bool), Color> _inkCache = {};

  /// Readable shade of [hue] for text (or as a fill behind white text):
  /// the same hue, darkened (light mode) or lightened (dark mode) just
  /// enough to clear 4.5:1 against its own tint, the page and the card.
  static Color inkOf(Color hue) {
    return _inkCache.putIfAbsent((hue.toARGB32(), _dark), () {
      final hsl = HSLColor.fromColor(hue);
      bool ok(Color c) =>
          _contrast(c, tint(hue)) >= 4.6 &&
          _contrast(c, bg) >= 4.6 &&
          _contrast(c, card) >= 4.6;
      var c = hue;
      for (var i = 0; i < 40 && !ok(c); i++) {
        final l =
            (hsl.lightness + (_dark ? 1 : -1) * 0.02 * (i + 1)).clamp(0.0, 1.0);
        c = hsl.withLightness(l).toColor();
      }
      return c;
    });
  }

  static bool _isHue(Color c) =>
      c == accent ||
      c == danger ||
      c == _p.tier1 ||
      c == _p.tier2 ||
      c == _p.tier3;

  /// Text colours that are palette hues become their readable shade.
  static Color _text(Color? c, Color fallback) =>
      c == null ? fallback : (_isHue(c) ? inkOf(c) : c);

  static SystemUiOverlayStyle get overlay => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _p.overlayBrightness,
        systemNavigationBarColor: card,
        systemNavigationBarIconBrightness: _p.overlayBrightness,
      );

  /// Soft drop shadow for raised cards; none in dark mode (surfaces step up
  /// in lightness instead).
  static List<BoxShadow>? get shadow => _dark
      ? null
      : [
          BoxShadow(
              color: const Color(0xFF2D2A35).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ];

  // ---- geometry (shared across both palettes) --------------------------
  static const rXL = Radius.circular(28);
  static const rL = Radius.circular(24);
  static const rM = Radius.circular(18);
  static const rS = Radius.circular(12);
  static const rBtn = Radius.circular(20);
  static const rPill = Radius.circular(999);

  /// Apple's continuous corner (a rounded superellipse): the shape iOS
  /// draws for cards, sheets and icons. Every drawn corner uses it;
  /// controls use [capsule].
  static ShapeBorder squircle(Radius r, {BorderSide side = BorderSide.none}) =>
      RoundedSuperellipseBorder(side: side, borderRadius: BorderRadius.all(r));

  /// The same corner on the top edge only (sheets).
  static ShapeBorder squircleTop(Radius r) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: r));

  /// Capsule: the shape of every control (buttons, pills, bars).
  static const ShapeBorder capsule = StadiumBorder();

  /// A corner nested inside another stays concentric with it: the outer
  /// radius minus the gap between them, never sharper than 12.
  static Radius inner(Radius outer, double gap) =>
      Radius.circular(math.max(12, outer.x - gap));

  // ---- text ------------------------------------------------------------
  static TextStyle hero(double size,
          {Color? color, FontWeight weight = FontWeight.w800}) =>
      TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          color: _text(color, ink),
          fontWeight: weight,
          height: 1.15,
          letterSpacing: -0.3);

  static TextStyle body(double size,
          {Color? color, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          color: _text(color, ink),
          fontWeight: weight,
          height: 1.4);

  static TextStyle caption(
          {Color? color, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: _text(color, sub),
          fontWeight: weight,
          height: 1.35);

  /// Small uppercase-ish label above a block ("THIS WEEK").
  static TextStyle eyebrow({Color? color}) => TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      color: _text(color, faint),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      height: 1.3);

  static bool get _appleTarget =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static ThemeData theme() {
    final p = _p;
    final brightness = _dark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: inkOf(p.accent),
        onPrimary: p.onAccent,
        surface: p.bg,
        onSurface: p.ink,
        surfaceContainerHighest: p.cardHi,
        outline: p.line,
        secondary: p.sub,
        onSecondary: p.onAccent,
        error: p.danger,
        onError: p.onAccent,
      ),
      dividerColor: p.line,
      hintColor: p.faint,
      // iOS doesn't ripple: presses dim (and Pressable sinks the surface);
      // Android keeps the Material sparkle
      splashFactory:
          _appleTarget ? NoSplash.splashFactory : InkSparkle.splashFactory,
      highlightColor:
          _appleTarget ? p.ink.withValues(alpha: _dark ? 0.08 : 0.05) : null,
      // each platform's native page motion: Android gets predictive back
      // (fade-forwards when not gesturing), Apple devices slide in from the
      // right with edge swipe-back, everything else fades forwards
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      }),
      // Cupertino widgets (nav bars, sheets, pickers, segmented controls)
      // take our palette and Nunito instead of SF + system blue
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: inkOf(p.accent),
        scaffoldBackgroundColor: p.bg,
        barBackgroundColor: p.bg.withValues(alpha: 0.8),
        textTheme: CupertinoTextThemeData(
          primaryColor: inkOf(p.accent),
          textStyle:
              TextStyle(fontFamily: fontFamily, fontSize: 17, color: p.ink),
          navTitleTextStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.ink),
          navLargeTitleTextStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: p.ink),
          actionTextStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: inkOf(p.accent)),
          dateTimePickerTextStyle:
              TextStyle(fontFamily: fontFamily, fontSize: 22, color: p.ink),
          pickerTextStyle:
              TextStyle(fontFamily: fontFamily, fontSize: 21, color: p.ink),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: p.ink),
        iconTheme: IconThemeData(color: p.ink),
        systemOverlayStyle: overlay,
      ),
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(rL)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: inkOf(p.accent),
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.cardHi,
          disabledForegroundColor: p.faint,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          backgroundColor: p.cardHi,
          side: BorderSide.none,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkOf(p.accent),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.sub),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.cardHi,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardHi,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(rM), borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(rM), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(rM),
            borderSide: BorderSide(color: p.accent, width: 2)),
        labelStyle: TextStyle(
            fontFamily: fontFamily,
            color: p.sub,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        hintStyle: TextStyle(fontFamily: fontFamily, color: p.faint),
        helperStyle: TextStyle(
            fontFamily: fontFamily,
            color: p.sub,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.cardHi,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
            fontFamily: fontFamily,
            color: p.sub,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
      listTileTheme: ListTileThemeData(
        textColor: p.ink,
        iconColor: p.sub,
        subtitleTextStyle:
            TextStyle(fontFamily: fontFamily, color: p.sub, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(rXL)),
        titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: p.ink),
        contentTextStyle:
            TextStyle(fontFamily: fontFamily, fontSize: 14, color: p.sub),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.card,
        shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(rXL)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        behavior: SnackBarBehavior.floating,
        shape:
            const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(rM)),
        contentTextStyle: TextStyle(
            fontFamily: fontFamily, color: p.bg, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.faint,
        showDragHandle: true,
        shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.vertical(top: rXL)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? tint(p.accent) : p.card),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? inkOf(p.accent) : p.sub),
          side: WidgetStateProperty.all(BorderSide(color: p.line)),
          textStyle: WidgetStateProperty.all(const TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w800)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onAccent : p.faint),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accent : p.cardHi),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: tint(p.accent),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected) ? p.ink : p.faint)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.accent : p.faint,
            size: 24)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared components. Screens compose these instead of hand-rolling boxes.
// ---------------------------------------------------------------------------

/// Full-width primary action, 56px, rounded 20.
class IronButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color; // defaults to the accent

  const IronButton(
      {super.key, required this.label, this.onPressed, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final style = color == null
        ? null
        : FilledButton.styleFrom(
            backgroundColor: Iron.inkOf(color!),
            foregroundColor: Iron.isDark ? Iron.bg : Colors.white);
    final button = icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
            label: Text(label),
          );
    return Pressable(enabled: onPressed != null, child: button);
  }
}

/// Rounded surface. White (or charcoal) by default; pass [color] for a
/// tinted block. Tappable when [onTap] is set.
class IronCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final Radius radius;
  final bool raised; // soft shadow in light mode

  const IronCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.radius = Iron.rL,
    this.raised = true,
  });

  @override
  Widget build(BuildContext context) {
    final shape = Iron.squircle(radius);
    final card = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: raised && color == null ? Iron.shadow : null,
      ),
      child: Material(
        color: color ?? Iron.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : Pressable(scale: 0.975, child: card);
  }
}

/// Small rounded label. Tinted background in [color]'s hue, text in
/// [color]; neutral grey when no colour is given.
class IronPill extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool solid; // filled with the hue itself (strong emphasis)
  final VoidCallback? onTap;

  const IronPill(this.label,
      {super.key, this.color, this.icon, this.solid = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hue = color;
    final bg = hue == null
        ? Iron.cardHi
        : solid
            ? Iron.inkOf(hue)
            : Iron.tint(hue);
    final fg = hue == null
        ? Iron.sub
        : solid
            ? (Iron.isDark ? Iron.bg : Colors.white)
            : Iron.inkOf(hue);
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: Iron.caption(color: fg, weight: FontWeight.w800)
                    .copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
    final pill = Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
    return onTap == null ? pill : Pressable(scale: 0.94, child: pill);
  }
}

/// Rounded square holding an icon on a soft tint — the friendly stand-in
/// for exercise illustrations and list leading glyphs.
class IconBlob extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final bool onTint; // sitting on a tinted block: use the card surface
  final Radius? radius; // concentric with the parent; default by size

  const IconBlob(this.icon,
      {super.key,
      this.color,
      this.size = 44,
      this.onTint = false,
      this.radius});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: onTint ? Iron.card : Iron.tint(hue),
        shape: Iron.squircle(radius ?? Radius.circular(size * 0.36)),
      ),
      child: Icon(icon, size: size * 0.5, color: hue),
    );
  }
}

/// Section heading with an optional trailing action.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionTitle(this.text,
      {super.key,
      this.trailing,
      this.padding = const EdgeInsets.fromLTRB(4, 8, 4, 10)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(text, style: Iron.hero(19))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ● ● ○ ○ — one dot per set (or per weekly session).
class SetDots extends StatelessWidget {
  final int done;
  final int total;
  final Color? color;
  final double size;

  /// The newest filled dot springs in — the confirmation of a set just done.
  final bool popLast;

  const SetDots(
      {super.key,
      required this.done,
      required this.total,
      this.color,
      this.size = 12,
      this.popLast = false});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    final pop = popLast && !Motion.reduced(context);
    Widget dot(int i, Widget child) => pop && i == done - 1
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.2, end: 1),
            duration: Motion.bouncy.duration,
            curve: Motion.bouncy,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: child,
          )
        : child;
    return Wrap(
      spacing: size * 0.5,
      runSpacing: size * 0.5,
      children: [
        for (var i = 0; i < total; i++)
          dot(
              i,
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? hue : Colors.transparent,
                  border: Border.all(
                      color: i < done ? hue : hue.withValues(alpha: 0.35),
                      width: 2),
                ),
              )),
      ],
    );
  }
}

/// Segmented progress: one rounded segment per exercise.
class BarbellProgress extends StatelessWidget {
  final int current; // 1-based
  final int total;
  final Color? color;

  const BarbellProgress(
      {super.key, required this.current, required this.total, this.color});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 8,
              decoration: BoxDecoration(
                color: i < current ? hue : Iron.tint(hue),
                borderRadius: const BorderRadius.all(Iron.rPill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Thick rounded ring for the rest timer.
class RestRing extends StatelessWidget {
  final double value; // 0..1 remaining
  final double size;
  final Widget child;

  const RestRing(
      {super.key, required this.value, required this.child, this.size = 250});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // soft disc behind the ring
          Container(
            width: size - 40,
            height: size - 40,
            decoration: BoxDecoration(
                color: Iron.card,
                shape: BoxShape.circle,
                boxShadow: Iron.shadow),
          ),
          SizedBox(
            width: size,
            height: size,
            // the timer ticks once a second; a linear 1s tween per tick makes
            // the ring sweep continuously instead of jumping
            // ...and it draws itself in when the rest begins
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: Motion.reduced(context) ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Motion.smooth,
              builder: (context, drawIn, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: value.clamp(0, 1)),
                duration: const Duration(seconds: 1),
                curve: Curves.linear,
                builder: (context, v, _) => CircularProgressIndicator(
                  value: v * drawIn,
                  strokeWidth: 16,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Iron.tint(Iron.accent),
                  valueColor: AlwaysStoppedAnimation(Iron.accent),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Large selectable tile (onboarding answers, settings choices).
class ChoiceTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color; // hue for the icon blob and selected state
  final bool selected;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Pressable(
        child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: ShapeDecoration(
        shape: Iron.squircle(Iron.rM,
            side: BorderSide(
                color: selected ? hue : Colors.transparent, width: 2)),
        shadows: selected ? null : Iron.shadow,
      ),
      child: Material(
        color: selected ? Iron.tint(hue) : Iron.card,
        shape: Iron.squircle(Iron.rM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  IconBlob(icon!, color: hue, size: 40),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Iron.body(16, weight: FontWeight.w700)),
                      if (subtitle != null)
                        Text(subtitle!, style: Iron.caption()),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? Icon(Icons.check_circle_rounded,
                          key: const ValueKey(true), size: 24, color: hue)
                      : Icon(Icons.circle_outlined,
                          key: const ValueKey(false),
                          size: 24,
                          color: Iron.line),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

/// Small stat block: big number, caption under it.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const StatTile(
      {super.key, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: ShapeDecoration(
        color: Iron.tint(hue),
        shape: Iron.squircle(Iron.rM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            // changed values roll into place (e.g. after deleting a log)
            child: RollingText(value, style: Iron.hero(24, color: hue)),
          ),
          const SizedBox(height: 2),
          Text(label, style: Iron.caption()),
        ],
      ),
    );
  }
}

/// Category glyph for an exercise (until illustrations land).
IconData exerciseIcon(String category) => switch (category) {
      'dumbbell' => Icons.fitness_center_rounded,
      'barbell' => Icons.fitness_center_rounded,
      'machine' => Icons.event_seat_rounded,
      'cable' => Icons.cable_rounded,
      _ => Icons.accessibility_new_rounded,
    };
