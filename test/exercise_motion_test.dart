import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/data/exercise_motions.dart';
import 'package:gym_app/data/exercises_seed.dart';
import 'package:gym_app/theme.dart';
import 'package:gym_app/widgets/exercise_motion.dart';

void main() {
  setUp(() {
    Iron.setAppearance('light');
    Iron.setTheme('sage');
  });

  test('every exercise has its own demo', () {
    final missing = [
      for (final e in exercisesSeed)
        if (!hasMotion(e.id)) e.id
    ];
    expect(missing, isEmpty);
  });

  test('unknown ids fall back to a standing figure', () {
    final spec = motionFor('no_such_move');
    expect(spec.bounds.isFinite, isTrue);
    expect(identical(spec, motionFor('no_such_move')), isTrue); // cached
  });

  test('every demo stays finite, on stage and out of the floor', () {
    final problems = <String>[];
    for (final e in exercisesSeed) {
      final spec = motionFor(e.id);
      final b = spec.bounds;
      if (!b.isFinite || b.width < 20 || b.height < 15) {
        problems.add('${e.id}: bounds $b');
      }
      frames:
      for (var i = 0; i < 48; i++) {
        final t = i / 48;
        final rig = spec.rigAt(t);
        for (final p in rig.points) {
          // nothing sinks into the floor (joint centres; strokes are round)
          if (!p.isFinite || p.dy > ground + 2.5) {
            problems.add('${e.id} @${t.toStringAsFixed(2)}: joint at $p');
            break frames;
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.take(12).join('\n'));
  });

  test('limbs keep their length (the solver never stretches a bone)', () {
    for (final e in exercisesSeed) {
      final spec = motionFor(e.id);
      for (final t in [0.0, 0.3, 0.55, 0.8]) {
        final pose = spec.pose(t);
        final r = spec.rigAt(t);
        final thigh = thighLen * pose.thighScale;
        final shin = shinLen * pose.shinScale;
        final arm = upperArm * pose.armScale;
        expect((r.kneeN - r.hipN).distance, closeTo(thigh, 0.01));
        expect((r.ankleN - r.kneeN).distance, closeTo(shin, 0.01));
        expect((r.elbowF - r.shF).distance, closeTo(arm, 0.01));
      }
    }
  });

  testWidgets('every demo paints at any moment, in both appearances',
      (tester) async {
    for (final appearance in ['light', 'dark']) {
      Iron.setAppearance(appearance);
      for (final t in [0.0, 0.42, 0.77]) {
        await tester.pumpWidget(MaterialApp(
          theme: Iron.theme(),
          home: Wrap(children: [
            for (final e in exercisesSeed)
              SizedBox(
                width: 40,
                height: 40,
                child: ExerciseMotionView(
                    spec: motionFor(e.id), muscles: e.muscles, at: t),
              ),
          ]),
        ));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'plays a few reps, settles on the key pose; still under '
      'Reduce Motion', (tester) async {
    final e = exerciseMap['squat_bw']!;
    final spec = motionFor(e.id);
    Widget demo({bool reduce = false}) => MaterialApp(
          theme: Iron.theme(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: ExerciseMotionView(spec: spec, muscles: e.muscles),
              ),
            ),
          ),
        );
    // the painter's animation is the demo's clock
    Animation<double> clock() => (tester
            .widget<CustomPaint>(find.descendant(
                of: find.byType(ExerciseMotionView),
                matching: find.byType(CustomPaint)))
            .painter as dynamic)
        .anim as Animation<double>;

    await tester.pumpWidget(demo());
    await tester.pump(spec.period * 1.5);
    expect(tester.binding.transientCallbackCount, greaterThan(0)); // playing

    // three reps and the ease into the key pose, then nothing ticks
    await tester.pump(spec.period * 3);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(clock().value, closeTo(spec.stillAt, 1e-6));

    await tester.pumpWidget(demo(reduce: true));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
