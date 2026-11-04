import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/data/exercises_seed.dart';
import 'package:gym_app/data/plans_seed.dart';
import 'package:gym_app/data/substitutions.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/weekly_program.dart';
import 'package:gym_app/widgets/plan_card.dart';

void main() {
  test('exercise seed is internally consistent', () {
    expect(exercisesSeed.length, greaterThanOrEqualTo(101));
    final ids = exercisesSeed.map((e) => e.id).toSet();
    expect(ids.length, exercisesSeed.length, reason: 'duplicate exercise ids');
    for (final e in exercisesSeed) {
      expect(e.cuesEn.length, e.cuesZh.length, reason: e.id);
      expect(e.mistakesEn.length, e.mistakesZh.length, reason: e.id);
    }
  });

  test('exercise copy is complete and muscles are known', () {
    const muscles = {
      'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms', 'core',
      'quads', 'hamstrings', 'adductors', 'abductors', 'glutes', 'calves',
      'lower_back', 'cardio', 'full_body', 'traps',
    };
    const categories = {'bodyweight', 'dumbbell', 'barbell', 'machine', 'cable'};
    for (final e in exercisesSeed) {
      expect(categories, contains(e.category), reason: e.id);
      expect(e.muscles, isNotEmpty, reason: e.id);
      expect(muscles.containsAll(e.muscles), isTrue, reason: e.id);
      for (final text in [e.nameEn, e.nameZh, e.descEn, e.descZh, e.progEn,
          e.progZh, e.regEn, e.regZh]) {
        expect(text.trim(), isNotEmpty, reason: e.id);
      }
      expect(e.cuesEn, isNotEmpty, reason: e.id);
      expect(e.difficulty, inInclusiveRange(1, 3), reason: e.id);
    }
  });

  test('injury swaps are valid and never need more equipment', () {
    const rank = {'none': 0, 'dumbbell': 1, 'gym': 2};
    substitutions.forEach((from, byIssue) {
      final src = exerciseMap[from];
      expect(src, isNotNull, reason: 'unknown source $from');
      byIssue.forEach((issue, to) {
        final alt = exerciseMap[to];
        expect(alt, isNotNull, reason: '$from → unknown $to');
        expect(src!.contraindications, contains(issue),
            reason: '$from is not flagged for $issue');
        expect(alt!.contraindications, isNot(contains(issue)),
            reason: '$from → $to is flagged for $issue too');
        expect(rank[alt.requiredEquipment()]!,
            lessThanOrEqualTo(rank[src.requiredEquipment()]!),
            reason: '$from → $to needs more equipment');
      });
    });
  });

  test('builtin plans only reference existing exercises', () {
    final ids = exercisesSeed.map((e) => e.id).toSet();
    for (final p in builtinPlans) {
      for (final item in p.items) {
        expect(ids.contains(item.exerciseId), isTrue,
            reason: '${p.id} references missing ${item.exerciseId}');
      }
    }
  });

  group('weekly program derivation', () {
    AppSettings settings(
        {int? tier, int? days, String? eq = 'gym', String? age}) {
      return AppSettings(
          userTier: tier, userDays: days, userEquipment: eq, ageBand: age);
    }

    test('gym beginner, 3 days → gym A/B/A rotation (dumbbell+machine)', () {
      final p = deriveWeeklyProgram(settings(tier: 1, days: 3))!;
      expect(p.slots.map((s) => s.id).toSet(),
          {'builtin_beginner_gym_a', 'builtin_beginner_gym_b'});
      expect(p.slots.length, 3);
      expect(p.alternates, isTrue); // odd day count flips weekly
    });

    test('dumbbell intermediate, 4 days → upper/lower ×2', () {
      final p = deriveWeeklyProgram(
          settings(tier: 2, days: 4, eq: 'dumbbell'))!;
      expect(p.slots.length, 4);
      final ids = p.slots.map((s) => s.id).toList();
      expect(ids[0] == ids[2], isTrue);
      expect(ids[1] == ids[3], isTrue);
      expect(ids[0] != ids[1], isTrue);
    });

    test('advanced, 3 days → PPL rotation; 6 days → PPL ×2', () {
      final p3 = deriveWeeklyProgram(settings(tier: 3, days: 3))!;
      expect(p3.slots.map((s) => s.id).toList(), [
        'builtin_advanced_push',
        'builtin_advanced_pull',
        'builtin_advanced_legs',
      ]);
      final p6 = deriveWeeklyProgram(settings(tier: 3, days: 6))!;
      expect(p6.slots.length, 6);
      expect(p6.slots[3].id, 'builtin_advanced_push'); // second rotation
    });

    test('advanced, 5 days → five-way split in order', () {
      final p = deriveWeeklyProgram(settings(tier: 3, days: 5))!;
      expect(p.slots.map((s) => s.id).toList(), [
        'builtin_advanced_chest',
        'builtin_advanced_back',
        'builtin_advanced_shoulders',
        'builtin_advanced_arms',
        'builtin_advanced_legs',
      ]);
      expect(p.alternates, isFalse);
    });

    test('bodyweight-only beginner, 2 days → bodyweight A/B', () {
      final p =
          deriveWeeklyProgram(settings(tier: 1, days: 2, eq: 'none'))!;
      expect(p.slots.length, 2);
      expect(p.slots.map((s) => s.id).toSet(), {
        'builtin_beginner_bodyweight_a',
        'builtin_beginner_bodyweight_b'
      });
    });

    test('skipped onboarding → null', () {
      expect(deriveWeeklyProgram(AppSettings()), isNull);
    });
  });

  group('ISO week number', () {
    test('changes on Monday, not Thursday', () {
      // 2026-10-26 (Mon) .. 2026-11-01 (Sun) is ISO week 44
      for (var d = 26; d <= 32; d++) {
        expect(isoWeekNumber(DateTime(2026, 10, d)), 44, reason: 'day $d');
      }
      expect(isoWeekNumber(DateTime(2026, 10, 25)), 43);
      expect(isoWeekNumber(DateTime(2026, 11, 2)), 45);
    });

    test('year boundaries', () {
      expect(isoWeekNumber(DateTime(2025, 12, 29)), 1); // belongs to 2026
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumber(DateTime(2026, 12, 31)), 53);
      expect(isoWeekNumber(DateTime(2027, 1, 1)), 53); // still 2026's week
      expect(isoWeekNumber(DateTime(2027, 1, 4)), 1);
    });
  });

  test('completedThisWeek counts from Monday 00:00', () {
    SessionLog log(DateTime at) => SessionLog(
        id: '$at',
        planId: 'p',
        planTitleEn: 'p',
        planTitleZh: 'p',
        startedAt: at,
        durationSeconds: 60,
        items: const []);
    final logs = [
      log(DateTime(2026, 10, 29, 8)), // Thu
      log(DateTime(2026, 10, 26, 0, 0)), // Mon midnight
      log(DateTime(2026, 10, 25, 23, 59)), // previous Sun
    ];
    expect(
        completedThisWeek(AppSettings(), logs,
            now: DateTime(2026, 10, 29, 20)),
        2);
  });

  test('sessionsPerWeek buckets by calendar week, oldest first', () {
    SessionLog log(DateTime at) => SessionLog(
        id: '$at',
        planId: 'p',
        planTitleEn: 'p',
        planTitleZh: 'p',
        startedAt: at,
        durationSeconds: 60,
        items: const []);
    final now = DateTime(2026, 10, 29, 20); // Thu
    final logs = [
      log(DateTime(2026, 10, 29, 8)), // this week
      log(DateTime(2026, 10, 26, 0, 0)), // this week's Monday midnight
      log(DateTime(2026, 10, 25, 23, 59)), // last week (Sun)
      log(DateTime(2026, 10, 19, 7)), // last week (Mon)
      log(DateTime(2026, 9, 2, 7)), // 8 weeks back: outside the window
    ];
    expect(sessionsPerWeek(logs, now: now), [0, 0, 0, 0, 0, 0, 2, 2]);
    expect(weekStartOf(now, weeksAgo: 7), DateTime(2026, 9, 7));
    expect(sessionsPerWeek(const [], now: now, weeks: 3), [0, 0, 0]);
  });

  group('unavailable label names the right equipment', () {
    final gymPlan =
        builtinPlans.firstWhere((p) => p.id == 'builtin_beginner_gym_a');

    test('dumbbell owner on a gym plan → gym, not dumbbell', () {
      final label = unavailableLabel(gymPlan, 'dumbbell');
      expect(label, contains('gym'));
      expect(label, isNot(contains('Dumbbell')));
    });

    test('bodyweight-only user on a dumbbell-only plan → dumbbell', () {
      final dbPlan = builtinPlans.firstWhere((p) =>
          p.items.isNotEmpty &&
          p.items.every((it) =>
              exerciseMap[it.exerciseId]!.requiredEquipment() != 'gym') &&
          p.items.any((it) =>
              exerciseMap[it.exerciseId]!.requiredEquipment() ==
              'dumbbell'));
      expect(unavailableLabel(dbPlan, 'none'), contains('Dumbbell'));
    });

    test('full gym → no label', () {
      expect(unavailableLabel(gymPlan, 'gym'), isEmpty);
    });
  });
}
