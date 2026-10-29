import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/screens/onboarding_screen.dart';
import 'package:gym_app/screens/root.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/theme.dart';

/// Renders every top-level screen at phone size in both themes and both
/// languages; any layout overflow or build exception fails the test.
void main() {
  Future<void> seed() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    final s = Store.instance.settings
      ..onboardingDone = true
      ..userTier = 2
      ..userDays = 4
      ..userEquipment = 'dumbbell'
      ..bodyIssues = ['knee'];
    Store.instance.settings = s;
  }

  Widget app(Widget home) => MaterialApp(theme: Iron.theme(), home: home);

  for (final dark in [false, true]) {
    for (final lang in ['en', 'zh']) {
      testWidgets('tabs render (${dark ? 'dark' : 'light'}, $lang)',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await seed();
        L10n.setLang(lang);
        Iron.setAppearance(dark ? 'dark' : 'light');

        await tester.pumpWidget(app(const RootShell()));
        await tester.pumpAndSettle();
        for (final tab in [Icons.list_outlined, Icons.history,
            Icons.settings_outlined, Icons.home_outlined]) {
          await tester.tap(find.byIcon(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('onboarding walks all five questions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(app(const OnboardingPage(reentry: true)));
    for (final answer in ['Beginner', '6 days', 'Adjustable dumbbells',
        '35 – 54', 'None']) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(Store.instance.settings.userDays, 6);
    expect(Store.instance.settings.userEquipment, 'dumbbell');
  });
}
