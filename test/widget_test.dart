import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/data/exercises_seed.dart';
import 'package:gym_app/data/plans_seed.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/weekly_program.dart';

void main() {
  test('exercise seed is internally consistent', () {
    expect(exercisesSeed.length, greaterThanOrEqualTo(59));
    final ids = exercisesSeed.map((e) => e.id).toSet();
    expect(ids.length, exercisesSeed.length, reason: 'duplicate exercise ids');
    for (final e in exercisesSeed) {
      expect(e.cuesEn.length, e.cuesZh.length, reason: e.id);
      expect(e.mistakesEn.length, e.mistakesZh.length, reason: e.id);
    }
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
}