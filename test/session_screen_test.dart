import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/screens/session_screen.dart';
import 'package:gym_app/store.dart';

class _FakeWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

const _plan = Plan(
  id: 'test_plan',
  titleEn: 'Test',
  titleZh: 'Test',
  descEn: '',
  descZh: '',
  tier: 1,
  builtin: false,
  daysMin: 2,
  daysMax: 5,
  items: [
    PlanItem(exerciseId: 'pushup', sets: 1, reps: '10', restSeconds: 60),
  ],
);

const _two = Plan(
  id: 'two',
  titleEn: 'Two',
  titleZh: 'Two',
  descEn: '',
  descZh: '',
  tier: 1,
  builtin: false,
  daysMin: 2,
  daysMax: 5,
  items: [
    PlanItem(
        exerciseId: 'goblet_squat', sets: 3, reps: '8-12', restSeconds: 60),
    PlanItem(exerciseId: 'pushup', sets: 2, reps: '8-12', restSeconds: 60),
  ],
);

/// Last time: every goblet squat set at 14 kg × 12, the top of 8-12.
SessionLog _lastTime() => SessionLog(
      id: 'before',
      planId: 'two',
      planTitleEn: 'Two',
      planTitleZh: 'Two',
      startedAt: DateTime.now().subtract(const Duration(days: 2)),
      durationSeconds: 1500,
      items: const [
        ItemLog(exerciseId: 'goblet_squat', sets: [
          SetLog(index: 0, done: true, weight: 14, reps: 12),
          SetLog(index: 1, done: true, weight: 14, reps: 12),
          SetLog(index: 2, done: true, weight: 14, reps: 12),
        ]),
      ],
    );

void main() {
  setUp(() async {
    WakelockPlusPlatformInterface.instance = _FakeWakelock();
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    L10n.setLang('en');
  });

  // a few frames: sheets close, the futures they return complete, and the
  // screen rebuilds (no pumpAndSettle: demos and the rest timer keep going)
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('last time fills the previous column and suggests more weight',
      (tester) async {
    Store.instance.logs.add(_lastTime());
    await tester.pumpWidget(const MaterialApp(home: SessionScreen(plan: _two)));
    await tester.pump();
    expect(find.text('14 × 12'), findsNWidgets(3)); // one per set
    expect(find.text(L10n.tf('progressAddWeight', 12)), findsOneWidget);
    // the fields start where last time ended
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.map((f) => f.controller!.text), ['14', '12']);

    await tester.enterText(find.byType(TextField).first, '16');
    await tester.enterText(find.byType(TextField).last, '10');
    await tester.tap(find.text('Complete set'));
    await settle(tester);
    expect(find.text('+15 s'), findsOneWidget); // resting
    expect(find.text('16 × 10'), findsOneWidget); // the set just logged

    // quit early, keeping what was done
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.maybePop();
    await settle(tester);
    await tester.tap(find.text(L10n.t('finishAndSave')));
    await settle(tester);
    expect(find.text('Finish'), findsOneWidget);
    final saved = Store.instance.logs.first;
    expect(saved.id, isNot('before'));
    expect(saved.doneSets(), 1);
    expect(saved.totalSets(), 5); // the planned sets left undone are kept
    final first = saved.items.first.sets.first;
    expect((first.weight, first.reps), (16.0, 10));
    // 16 kg beats last time's 14 kg
    expect(find.text(L10n.t('newRecords')), findsOneWidget);
  });

  testWidgets('the workout list jumps to another exercise', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionScreen(plan: _two)));
    await tester.pump();
    await tester.tap(find.byTooltip(L10n.t('workoutOverview')));
    await settle(tester);
    await tester.tap(find.text('Push-Up').last);
    await settle(tester);
    expect(find.text('Exercise 2 / 2'), findsOneWidget);
    // a bodyweight move logs reps only
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('discarding saves nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionScreen(plan: _two)));
    await tester.pump();
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.maybePop();
    await settle(tester);
    // nothing done yet: only discard is offered
    expect(find.text(L10n.t('finishAndSave')), findsNothing);
    await tester.tap(find.text(L10n.t('discardWorkout')));
    await settle(tester);
    expect(Store.instance.logs, isEmpty);
  });

  testWidgets('−15 s on a short rest ends it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionScreen(plan: _two)));
    await tester.pump();
    await tester.tap(find.text('Complete set'));
    await settle(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('−15 s'));
      await tester.pump();
    }
    await settle(tester);
    expect(find.text('+15 s'), findsNothing);
    expect(find.text('Complete set'), findsOneWidget);
  });

  testWidgets('final set finishes and logs without a rest phase',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: SessionScreen(plan: _plan)));
    await tester.tap(find.text('Complete set'));
    await tester.pump();

    expect(find.text('+15 s'), findsNothing); // no rest screen
    expect(find.text('Finish'), findsOneWidget);
    expect(Store.instance.logs, hasLength(1));
    expect(Store.instance.logs.first.doneSets(), 1);
  });

  testWidgets('empty plan pops instead of crashing', (tester) async {
    const empty = Plan(
      id: 'empty',
      titleEn: 'Empty',
      titleZh: 'Empty',
      descEn: '',
      descZh: '',
      tier: 1,
      builtin: false,
      daysMin: 2,
      daysMax: 5,
      items: [],
    );
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SessionScreen(plan: empty))),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SessionScreen), findsNothing);
    expect(find.text('go'), findsOneWidget);
  });
}
