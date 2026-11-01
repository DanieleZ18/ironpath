import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/screens/root.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/theme.dart';
import 'package:gym_app/widgets/theme_crossfade.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  tearDown(() {
    Iron.setAppearance('light');
    Iron.setTheme('sage');
  });

  test('default theme reproduces the original palette exactly', () {
    Iron.setAppearance('light');
    Iron.setTheme('sage');
    expect(Iron.bg, const Color(0xFFF4F2EE));
    expect(Iron.accent, const Color(0xFF5E7F6A));
    expect(Iron.tier(1), const Color(0xFF6F8BA6));
    expect(Iron.tier(3), const Color(0xFFB07A6A));
    Iron.setAppearance('dark');
    expect(Iron.bg, const Color(0xFF191A19));
    expect(Iron.accent, const Color(0xFF8FB09A));
  });

  // every theme a user can pick — presets and the custom hue wheel — must
  // keep fills visible and text readable in both appearances
  final themes = <(String, double?)>[
    for (final p in Iron.presets) (p.id, null),
    for (var h = 0; h < 360; h += 15) ('custom', h.toDouble()),
  ];
  for (final dark in [false, true]) {
    test('contrast holds for every theme (${dark ? 'dark' : 'light'})', () {
      Iron.setAppearance(dark ? 'dark' : 'light');
      for (final (id, hue) in themes) {
        Iron.setTheme(id, hue: hue);
        final name = '$id${hue == null ? '' : ' @$hue'}';
        for (final c in [
          Iron.accent,
          Iron.tier(1),
          Iron.tier(2),
          Iron.tier(3)
        ]) {
          // graphics (dots, rings, fills) — WCAG 1.4.11
          expect(contrast(c, Iron.tint(c)), greaterThanOrEqualTo(2.99),
              reason: '$name fill vs its tint');
          expect(contrast(c, Iron.card), greaterThanOrEqualTo(2.99),
              reason: '$name fill vs card');
          // text in that hue — WCAG 1.4.3
          final ink = Iron.inkOf(c);
          for (final bg in [Iron.tint(c), Iron.bg, Iron.card]) {
            expect(contrast(ink, bg), greaterThanOrEqualTo(4.5),
                reason: '$name text vs surface');
          }
        }
        expect(contrast(Iron.ink, Iron.bg), greaterThanOrEqualTo(7),
            reason: '$name ink');
        expect(contrast(Iron.sub, Iron.bg), greaterThanOrEqualTo(4.5),
            reason: '$name sub');
      }
    });
  }

  test('custom tiers are distinct hues, not one colour three times', () {
    for (var h = 0; h < 360; h += 30) {
      final s = ThemeSpec.custom(h.toDouble());
      final hues = s.light.map((c) => HSLColor.fromColor(c).hue).toList();
      for (var i = 0; i < hues.length; i++) {
        for (var j = i + 1; j < hues.length; j++) {
          final d = (hues[i] - hues[j]).abs() % 360;
          expect(d > 180 ? 360 - d : d, greaterThan(40), reason: 'hue $h');
        }
      }
    }
  });

  test('theme choice persists, old saves fall back to the default', () {
    final s = AppSettings(themeId: 'custom', customHue: 212);
    final back = AppSettings.fromJson(s.toJson());
    expect(back.themeId, 'custom');
    expect(back.customHue, 212);
    final old = AppSettings.fromJson({'lang': 'zh'});
    expect(old.themeId, 'sage');
    expect(old.customHue, 150);
    // an id that no longer exists resolves to the default preset
    expect(Iron.specFor('gone').id, 'sage');
  });

  Future<BuildContext> pumpApp(WidgetTester tester,
      {bool reduce = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    Store.instance.settings.onboardingDone = true;
    L10n.setLang('en');
    await tester.pumpWidget(AnimatedBuilder(
      animation: Iron.notifier,
      builder: (context, _) => MaterialApp(
        theme: Iron.theme(),
        home: const RootShell(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: ThemeCrossfade(child: child!),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return tester.element(find.byType(RootShell));
  }

  testWidgets('crossfade applies the change and cleans up', (tester) async {
    final ctx = await pumpApp(tester);
    late Future<void> done;
    // the snapshot is real async work; the fade itself runs on test frames
    await tester.runAsync(() async {
      done = ThemeCrossfade.run(ctx, () => Iron.setTheme('pool'));
      for (var i = 0; i < 200 && Iron.themeId != 'pool'; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(Iron.themeId, 'pool');
    await tester.pump();
    expect(find.byType(RawImage), findsOneWidget); // old frame on top
    await tester.pumpAndSettle(); // the dissolve plays out
    // started in the real-async zone, so its cleanup completes there
    await tester.runAsync(() => done);
    await tester.pump();
    expect(find.byType(RawImage), findsNothing); // dissolved and freed
  });

  testWidgets('reduce motion: theme changes apply instantly', (tester) async {
    final ctx = await pumpApp(tester, reduce: true);
    await ThemeCrossfade.run(ctx, () => Iron.setTheme('trail'));
    expect(Iron.themeId, 'trail');
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
  });
}
