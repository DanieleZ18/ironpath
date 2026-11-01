import 'data/exercises_seed.dart';
import 'data/plans_seed.dart';
import 'models.dart';

/// Weekly program derivation: after onboarding (tier / days / equipment),
/// expand the recommended rotation into day-by-day slots for the week.
/// Pure function of settings + the const seed data — no Store, testable.

class WeeklyProgram {
  final List<Plan> slots; // day 1..N
  final bool
      alternates; // odd-day weeks flip the starting session (A-B-A / B-A-B)
  final bool oddStart; // this ISO week starts with slots.first

  const WeeklyProgram({
    required this.slots,
    required this.alternates,
    required this.oddStart,
  });
}

// ---- rotation families -----------------------------------------------------

const Map<String, String> _pairs = {
  'builtin_beginner_gym_a': 'builtin_beginner_gym_b',
  'builtin_beginner_gym_b': 'builtin_beginner_gym_a',
  'builtin_beginner_bodyweight_a': 'builtin_beginner_bodyweight_b',
  'builtin_beginner_bodyweight_b': 'builtin_beginner_bodyweight_a',
  'builtin_beginner_full_a': 'builtin_beginner_full_b',
  'builtin_beginner_full_b': 'builtin_beginner_full_a',
  'builtin_intermediate_upper': 'builtin_intermediate_lower',
  'builtin_intermediate_lower': 'builtin_intermediate_upper',
  'builtin_intermediate_gym_upper': 'builtin_intermediate_gym_lower',
  'builtin_intermediate_gym_lower': 'builtin_intermediate_gym_upper',
};

const List<String> _ppl = [
  'builtin_advanced_push',
  'builtin_advanced_pull',
  'builtin_advanced_legs',
];

const List<String> _bro = [
  'builtin_advanced_chest',
  'builtin_advanced_back',
  'builtin_advanced_shoulders',
  'builtin_advanced_arms',
  'builtin_advanced_legs',
];

Plan? _byId(String id) {
  for (final p in builtinPlans) {
    if (p.id == id) return p;
  }
  return null;
}

/// Equipment availability: how many of a plan's exercises the user cannot
/// perform (0 = fully followable).
int unavailableCount(Plan plan, String? userEquipment) =>
    plan.items.fold(0, (n, it) {
      final ex = exerciseMap[it.exerciseId];
      return n + ((ex == null || ex.availableFor(userEquipment)) ? 0 : 1);
    });

/// Distance from the user's planned weekly days to a plan's designed rhythm.
int freqDistance(Plan plan, int? userDays) {
  if (userDays == null) return 0;
  if (plan.idealDays.isNotEmpty) {
    return plan.idealDays
        .map((d) => (d - userDays).abs())
        .reduce((a, b) => a < b ? a : b);
  }
  if (userDays < plan.daysMin) return plan.daysMin - userDays;
  if (userDays > plan.daysMax) return userDays - plan.daysMax;
  return 0;
}

/// The unified recommendation score: equipment dominates, then frequency
/// fit, then tier proximity.
int recommendationScore(Plan plan, AppSettings s) =>
    unavailableCount(plan, s.userEquipment) * 100 +
    freqDistance(plan, s.userDays) * 10 +
    (plan.tier - (s.userTier ?? 2)).abs();

/// Derive the user's weekly program. Returns null when onboarding answers
/// are missing (skipped) or no rotation can be built.
WeeklyProgram? deriveWeeklyProgram(AppSettings s) {
  if (s.userTier == null || s.userDays == null) return null;
  final days = s.userDays!;

  Plan? best;
  for (final p in builtinPlans) {
    if (best == null ||
        recommendationScore(p, s) < recommendationScore(best, s)) {
      best = p;
    }
  }
  if (best == null) return null;

  final isoWeek = isoWeekNumber(DateTime.now());
  final odd = isoWeek % 2 == 1;

  // pair families alternate the two sessions
  final sibling = _pairs[best.id];
  if (sibling != null) {
    final other = _byId(sibling);
    if (other != null) {
      var first = best;
      var second = other;
      if (odd) {
        // B-start weeks flip so the pair stays balanced across weeks
        final tmp = first;
        first = second;
        second = tmp;
      }
      final slots = <Plan>[
        for (var i = 0; i < days; i++) i % 2 == 0 ? first : second,
      ];
      return WeeklyProgram(
          slots: slots, alternates: days % 2 == 1, oddStart: odd);
    }
  }

  // five-way split (exactly 5 days; shared legs day resolves to bro at 5)
  if (_bro.contains(best.id) && days == 5) {
    final slots = <Plan>[
      for (final id in _bro)
        if (_byId(id) != null) _byId(id)!,
    ];
    return WeeklyProgram(slots: slots, alternates: false, oddStart: odd);
  }

  // PPL rotation (3 or 6 days; other counts cycle from Push)
  if (_ppl.contains(best.id)) {
    final slots = <Plan>[
      for (var i = 0; i < days; i++)
        if (_byId(_ppl[i % 3]) != null) _byId(_ppl[i % 3])!,
    ];
    return WeeklyProgram(slots: slots, alternates: false, oddStart: odd);
  }

  // lone plan (no rotation family): repeat it
  return WeeklyProgram(
      slots: [for (var i = 0; i < days; i++) best],
      alternates: false,
      oddStart: odd);
}

/// ISO-8601 week number (weeks start Monday; week 1 holds the year's first
/// Thursday). Computed in UTC so DST shifts never skew the day count.
int isoWeekNumber(DateTime date) {
  // the Thursday of this date's week decides which year the week belongs to
  final thursday =
      DateTime.utc(date.year, date.month, date.day + 4 - date.weekday);
  final jan1 = DateTime.utc(thursday.year, 1, 1);
  return thursday.difference(jan1).inDays ~/ 7 + 1;
}

/// Sessions logged since the start of the current week (Monday).
int completedThisWeek(AppSettings s, List<SessionLog> logs, {DateTime? now}) {
  final weekStart = weekStartOf(now ?? DateTime.now());
  return logs.where((l) => !l.startedAt.isBefore(weekStart)).length;
}

/// Monday 00:00 (local) of the week [weeksAgo] weeks before [now]'s week.
DateTime weekStartOf(DateTime now, {int weeksAgo = 0}) =>
    // calendar arithmetic, not Duration: stays at local midnight across DST
    DateTime(now.year, now.month, now.day - (now.weekday - 1) - 7 * weeksAgo);

/// Sessions per calendar week for the last [weeks] weeks, oldest first;
/// the last entry is the current week.
List<int> sessionsPerWeek(List<SessionLog> logs,
    {int weeks = 8, DateTime? now}) {
  final n = now ?? DateTime.now();
  final starts = [
    for (var i = weeks - 1; i >= 0; i--) weekStartOf(n, weeksAgo: i)
  ];
  final counts = List.filled(weeks, 0);
  for (final l in logs) {
    for (var i = weeks - 1; i >= 0; i--) {
      if (!l.startedAt.isBefore(starts[i])) {
        // future-dated logs (clock changes) still count as this week
        counts[i]++;
        break;
      }
    }
  }
  return counts;
}
