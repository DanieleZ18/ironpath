import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

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

void main() {
  setUp(() async {
    WakelockPlusPlatformInterface.instance = _FakeWakelock();
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
  });

  testWidgets('final set finishes and logs without a rest phase',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionScreen(plan: _plan)));
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
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SessionScreen(plan: empty))),
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
