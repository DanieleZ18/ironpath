import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/screens/plan_detail.dart';
import 'package:gym_app/screens/plan_editor.dart';
import 'package:gym_app/screens/root.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/theme.dart';

void main() {
  Widget app(Widget home) => MaterialApp(theme: Iron.theme(), home: home);

  // adaptive components: Cupertino on Apple, Material elsewhere — run the
  // interaction tests on both
  final platforms =
      TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});
  bool apple() => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> setUpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    Store.instance.settings.onboardingDone = true;
    L10n.setLang('en');
    Iron.setAppearance('light');
  }

  testWidgets('history: swipe left deletes, undo restores', variant: platforms,
      (tester) async {
    await setUpPhone(tester);
    Store.instance.logs = [
      SessionLog(
        id: 'l1',
        planId: 'builtin_beginner_gym_a',
        planTitleEn: 'Swipe Me',
        planTitleZh: 'Swipe Me',
        startedAt: DateTime(2026, 10, 26, 9),
        durationSeconds: 600,
        items: const [],
      ),
    ];
    await tester.pumpWidget(app(const RootShell()));
    await tester.tap(find.byIcon(CupertinoIcons.clock));
    await tester.pumpAndSettle();

    // tabs stay alive, so the hidden home tab shows the title too — scope
    // to the swipeable row
    Finder row() => find.descendant(
        of: find.byType(Dismissible), matching: find.text('Swipe Me'));
    await tester.drag(row(), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(Store.instance.logs, isEmpty);
    expect(find.text('Workout deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(Store.instance.logs, hasLength(1));
    expect(row(), findsOneWidget);
  });

  testWidgets('editor: exercise picker sheet adds the picked exercise',
      variant: platforms, (tester) async {
    await setUpPhone(tester);
    await tester.pumpWidget(app(const PlanEditorPage()));
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    expect(find.text('Pick an exercise'), findsOneWidget);

    expect(find.byType(apple() ? CupertinoSearchTextField : TextField),
        findsWidgets);
    await tester.enterText(
        find.descendant(
            of: find.byType(ExercisePickerSheet),
            matching: find.byType(EditableText)),
        'inverted');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inverted Row'));
    await tester.pumpAndSettle();
    expect(find.text('Pick an exercise'), findsNothing); // sheet closed
    expect(find.text('Inverted Row'), findsOneWidget); // now in the plan
  });

  testWidgets('plan detail: delete from the … menu', variant: platforms,
      (tester) async {
    await setUpPhone(tester);
    final plan = Store.instance.builtin.first
        .copyAsCustom('custom_t', titleEn: 'Mine', titleZh: 'Mine');
    Store.instance.customPlans = [plan];
    await tester.pumpWidget(app(Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlanDetailPage(plan: plan))),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find
        .byIcon(apple() ? CupertinoIcons.ellipsis_circle : Icons.more_vert));
    await tester.pumpAndSettle();
    // iOS action sheet vs Material overflow menu
    if (apple()) {
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
    } else {
      expect(find.byType(PopupMenuItem<String>), findsNWidgets(2));
    }
    await tester.tap(find.text('Delete plan').last);
    await tester.pumpAndSettle();

    expect(Store.instance.customPlans, isEmpty);
    expect(find.text('open'), findsOneWidget); // popped back
  });
}
