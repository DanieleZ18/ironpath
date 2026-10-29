import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // ---- light palette (grey-beige paper, dusty hues) --------------------
  static const _lightPalette = _Palette(
    bg: Color(0xFFF4F2EE),
    card: Color(0xFFFFFFFF),
    cardHi: Color(0xFFECE9E3),
    ink: Color(0xFF2E302E),
    sub: Color(0xFF61635E),
    faint: Color(0xFF6F716B),
    accent: Color(0xFF5E7F6A), // sage
    onAccent: Color(0xFFFFFFFF),
    line: Color(0x1A2E302E),
    tier1: Color(0xFF6F8BA6), // mist blue
    tier2: Color(0xFF8A7AA0), // grey violet
    tier3: Color(0xFFB07A6A), // clay rose
    danger: Color(0xFFB07A6A),
    tintAmount: 0.14,
    overlayBrightness: Brightness.dark, // dark icons on light bg
  );

  // ---- dark palette (grey charcoal, lifted dusty hues) -------------------
  static const _darkPalette = _Palette(
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
      splashFactory: InkSparkle.splashFactory,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(rL)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: inkOf(p.accent),
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.cardHi,
          disabledForegroundColor: p.faint,
          minimumSize: const Size.fromHeight(56),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(rBtn)),
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
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(rBtn)),
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
        shape:
            const RoundedRectangleBorder(borderRadius: BorderRadius.all(rXL)),
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
        shape:
            const RoundedRectangleBorder(borderRadius: BorderRadius.all(rXL)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(rM)),
        contentTextStyle: TextStyle(
            fontFamily: fontFamily, color: p.bg, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.faint,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
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
    if (icon == null) {
      return FilledButton(
          style: style, onPressed: onPressed, child: Text(label));
    }
    return FilledButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
    );
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
    final r = BorderRadius.all(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: raised && color == null ? Iron.shadow : null,
      ),
      child: Material(
        color: color ?? Iron.card,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
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
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Rounded square holding an icon on a soft tint — the friendly stand-in
/// for exercise illustrations and list leading glyphs.
class IconBlob extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final bool onTint; // sitting on a tinted block: use the card surface

  const IconBlob(this.icon,
      {super.key, this.color, this.size = 44, this.onTint = false});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onTint ? Iron.card : Iron.tint(hue),
        borderRadius: BorderRadius.all(Radius.circular(size * 0.36)),
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

  const SetDots(
      {super.key,
      required this.done,
      required this.total,
      this.color,
      this.size = 12});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Wrap(
      spacing: size * 0.5,
      runSpacing: size * 0.5,
      children: [
        for (var i = 0; i < total; i++)
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
          ),
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0, 1)),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 16,
                strokeCap: StrokeCap.round,
                backgroundColor: Iron.tint(Iron.accent),
                valueColor: AlwaysStoppedAnimation(Iron.accent),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Iron.rM),
        border:
            Border.all(color: selected ? hue : Colors.transparent, width: 2),
        boxShadow: selected ? null : Iron.shadow,
      ),
      child: Material(
        color: selected ? Iron.tint(hue) : Iron.card,
        borderRadius: const BorderRadius.all(Iron.rM),
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
    );
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
      decoration: BoxDecoration(
        color: Iron.tint(hue),
        borderRadius: const BorderRadius.all(Iron.rM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Iron.hero(24, color: hue)),
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
