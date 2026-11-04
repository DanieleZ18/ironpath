import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/data/exercises_seed.dart';
import 'package:gym_app/l10n.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/screens/exercise_detail_screen.dart';
import 'package:gym_app/screens/exercises_screen.dart';
import 'package:gym_app/screens/library_screen.dart';
import 'package:gym_app/screens/settings_screen.dart';
import 'package:gym_app/widgets/ios_chrome.dart';
import 'package:gym_app/screens/onboarding_screen.dart';
import 'package:gym_app/screens/plan_detail.dart';
import 'package:gym_app/screens/root.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/theme.dart';
import 'package:gym_app/widgets/plan_card.dart';
import 'package:gym_app/widgets/weekly_chart.dart';

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
    // a few weeks of history, so the history bento and chart render
    final now = DateTime.now();
    for (final daysAgo in [0, 2, 8, 9, 15, 23, 30, 44]) {
      Store.instance.logs.add(SessionLog(
        id: 'log$daysAgo',
        planId: 'unknown',
        planTitleEn: 'Full Body',
        planTitleZh: '全身',
        startedAt: now.subtract(Duration(days: daysAgo)),
        durationSeconds: 2700,
        items: const [
          ItemLog(exerciseId: 'goblet_squat', sets: [
            SetLog(index: 0, done: true),
            SetLog(index: 1, done: true),
          ]),
        ],
      ));
    }
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
        for (final tab in [
          CupertinoIcons.square_list,
          CupertinoIcons.square_grid_2x2,
          CupertinoIcons.clock,
          CupertinoIcons.sun_max
        ]) {
          await tester.tap(find.byIcon(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        // settings open from the gear on Today and come back
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(IronBackButton));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsNothing);
      });
    }
  }

  testWidgets('bento grids grow with large text instead of clipping',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(MaterialApp(
      theme: Iron.theme(),
      home: const RootShell(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.6)),
        child: child!,
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(CupertinoIcons.clock).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // a plan's detail page, then one exercise's sheet
    await tester.tap(find.byIcon(CupertinoIcons.square_list).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TierCard).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // scroll through the whole page (bento tiles and exercise rows)
    await tester.drag(
        find
            .descendant(
                of: find.byType(PlanDetailPage),
                matching: find.byType(Scrollable))
            .first,
        const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    showExerciseDetail(tester.element(find.byType(PlanDetailPage)),
        exerciseMap['db_bentover_row']!);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercises tab filters by muscle and equipment', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.square_grid_2x2).last);
    await tester.pumpAndSettle();
    String count(int n) => L10n.tf('exercisesCount', n);
    expect(find.text(count(exercisesSeed.length)), findsOneWidget);

    // one muscle
    final adductors =
        exercisesSeed.where((e) => e.muscles.contains('adductors')).toList();
    expect(adductors.length, greaterThanOrEqualTo(8));
    // the chip sits off the right edge of its row: scroll the row (held by
    // identity, since the first chips unbuild as they leave the viewport)
    final row = tester.widget(find
        .ancestor(
            of: find.text(L10n.muscle('chest')),
            matching: find.byType(Scrollable))
        .first);
    await tester.scrollUntilVisible(find.text(L10n.muscle('adductors')), 120,
        scrollable: find.byWidget(row));
    await tester.pumpAndSettle();
    await tester.tap(find.text(L10n.muscle('adductors')));
    await tester.pumpAndSettle();
    expect(find.text(count(adductors.length)), findsOneWidget);

    // plus equipment
    final bw = adductors.where((e) => e.category == 'bodyweight').length;
    await tester.tap(find.text(L10n.t('bodyweight')).last);
    await tester.pumpAndSettle();
    expect(find.text(count(bw)), findsOneWidget);

    // a tile opens the exercise sheet
    await tester.tap(find.byType(ExerciseTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history chart reads out the week you tap', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.clock).last);
    await tester.pumpAndSettle();
    expect(find.text('This week · 2 workouts'), findsOneWidget);

    // the chart's first column is the week seven weeks back
    final chart = find.byType(WeeklyChartTile);
    final box = tester.getRect(
        find.descendant(of: chart, matching: find.byType(CustomPaint)).last);
    await tester.tapAt(Offset(box.left + 8, box.center.dy));
    await tester.pump();
    expect(find.textContaining('Week of '), findsOneWidget);

    // tapping it again goes back to this week
    await tester.tapAt(Offset(box.left + 8, box.center.dy));
    await tester.pump();
    expect(find.text('This week · 2 workouts'), findsOneWidget);
  });

  testWidgets('onboarding walks all five questions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(app(const OnboardingPage(reentry: true)));
    for (final answer in [
      'Beginner',
      '6 days',
      'Adjustable dumbbells',
      '35 – 54',
      'None'
    ]) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(Store.instance.settings.userDays, 6);
    expect(Store.instance.settings.userEquipment, 'dumbbell');
  });

  testWidgets('re-tapping the active tab scrolls it back to the top',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    // Plans is the long tab
    await tester.tap(find.byIcon(CupertinoIcons.square_list).last);
    await tester.pumpAndSettle();
    final list = find
        .descendant(
            of: find.byType(LibraryScreen), matching: find.byType(Scrollable))
        .first;
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    final pos = tester.state<ScrollableState>(list).position;
    expect(pos.pixels, greaterThan(0));

    await tester.tap(find.byIcon(CupertinoIcons.square_list_fill)); // active
    await tester.pumpAndSettle();
    expect(pos.pixels, 0);
  });

  testWidgets('onboarding back button returns to the previous question',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    L10n.setLang('en');
    Iron.setAppearance('light');

    await tester.pumpWidget(app(const OnboardingPage(reentry: true)));
    await tester.tap(find.text('Beginner'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('6 days'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('6 days'), findsNothing);
    expect(find.text('Beginner'), findsOneWidget);
  });

  test('page transitions: native per platform', () {
    final builders = Iron.theme().pageTransitionsTheme.builders;
    expect(builders[TargetPlatform.android],
        isA<PredictiveBackPageTransitionsBuilder>());
    expect(
        builders[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());
  });
}
