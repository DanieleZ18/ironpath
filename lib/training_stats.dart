import 'dart:math' as math;

import 'data/exercises_seed.dart';
import 'models.dart';
import 'weekly_program.dart' show sessionsPerWeek, weekStartOf;

// What the logs add up to: rep targets, volume, the sets each muscle got,
// personal records, streaks. Pure functions over the log list (newest
// first, as the store keeps it), so the screens and tests share them.

/// A plan's rep target, parsed: "8-12" → 8…12, "10" → 10, "30-45s" → a
/// hold of 30…45 seconds. Free text from a custom plan parses to nulls.
class RepTarget {
  final int? low;
  final int? high;
  final bool timed;

  const RepTarget(this.low, this.high, {this.timed = false});

  static final _seconds = RegExp(r'\d\s*(s|sec|secs|seconds|秒)$');

  factory RepTarget.parse(String text) {
    final t = text.trim().toLowerCase();
    final timed = _seconds.hasMatch(t);
    final n = [
      for (final m in RegExp(r'\d+').allMatches(t)) int.parse(m[0]!),
    ];
    if (n.isEmpty) return RepTarget(null, null, timed: timed);
    final a = n.first, b = n.length > 1 ? n[1] : n.first;
    return RepTarget(math.min(a, b), math.max(a, b), timed: timed);
  }

  /// Where the reps field starts without history: the bottom of the range.
  int get start => low ?? (timed ? 30 : 10);

  /// How far one tap of − / + moves it.
  int get step => timed ? 5 : 1;
}

/// Whether [exerciseId] is held for time (plank) rather than counted.
bool isTimed(String exerciseId) {
  final ex = exerciseMap[exerciseId];
  return ex != null && RepTarget.parse(ex.defReps).timed;
}

/// kg × reps over the done, loaded sets of [log] (timed holds don't count).
double sessionVolume(SessionLog log) {
  var v = 0.0;
  for (final item in log.items) {
    if (isTimed(item.exerciseId)) continue;
    for (final s in item.sets) {
      if (s.done && s.weight != null && s.reps != null) {
        v += s.weight! * s.reps!;
      }
    }
  }
  return v;
}

/// Reps done over the counted (not timed) sets of [log].
int sessionReps(SessionLog log) {
  var n = 0;
  for (final item in log.items) {
    if (isTimed(item.exerciseId)) continue;
    for (final s in item.sets) {
      if (s.done && s.reps != null) n += s.reps!;
    }
  }
  return n;
}

/// Working sets per muscle over [logs]: each done set counts fully for the
/// exercise's main muscle and half for the others it works (the shading
/// of a muscle map). With [weighted] off, every set counts once for each
/// muscle it worked: "sets that hit your core".
Map<String, double> setsPerMuscle(Iterable<SessionLog> logs,
    {bool weighted = true}) {
  final m = <String, double>{};
  for (final log in logs) {
    for (final item in log.items) {
      final ex = exerciseMap[item.exerciseId];
      final n = item.doneCount;
      if (ex == null || n == 0) continue;
      for (var i = 0; i < ex.muscles.length; i++) {
        final k = ex.muscles[i];
        m[k] = (m[k] ?? 0) + n * (i == 0 || !weighted ? 1.0 : 0.5);
      }
    }
  }
  return m;
}

/// The muscles [logs] worked most, as (muscle, sets that worked it), most
/// first: ties go to the muscle that led more of those sets, then by name.
List<MapEntry<String, int>> musclesBySets(Iterable<SessionLog> logs,
    [int n = 4]) {
  final shade = setsPerMuscle(logs);
  final hits = setsPerMuscle(logs, weighted: false);
  final list = hits.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) {
      var c = b.value.compareTo(a.value);
      if (c != 0) return c;
      c = (shade[b.key] ?? 0).compareTo(shade[a.key] ?? 0);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return [for (final e in list.take(n)) MapEntry(e.key, e.value.round())];
}

/// Logs that started on or after [from].
Iterable<SessionLog> logsSince(List<SessionLog> logs, DateTime from) =>
    logs.where((l) => !l.startedAt.isBefore(from));

/// This week's logs (since Monday).
Iterable<SessionLog> logsThisWeek(List<SessionLog> logs, {DateTime? now}) =>
    logsSince(logs, weekStartOf(now ?? DateTime.now()));

/// The done sets of the last time [exerciseId] was trained in [logs]
/// (newest first), skipping the log with id [except]; empty if never.
List<SetLog> previousSets(List<SessionLog> logs, String exerciseId,
    {String? except}) {
  for (final log in logs) {
    if (log.id == except) continue;
    for (final item in log.items) {
      if (item.exerciseId != exerciseId) continue;
      final done = item.sets.where((s) => s.done).toList();
      if (done.isNotEmpty) return done;
    }
  }
  return const [];
}

/// "12.5 × 10", "10", "12.5 kg" or "45 s": one set as the log shows it.
String setLabel(SetLog s, {bool timed = false}) {
  String w(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
  final reps = s.reps == null ? null : (timed ? '${s.reps} s' : '${s.reps}');
  if (s.weight != null && reps != null) return '${w(s.weight!)} × $reps';
  if (s.weight != null) return '${w(s.weight!)} kg';
  return reps ?? '—';
}

/// Whether last time every planned set reached the top of the range, so
/// it's time to add weight (or a harder variant): the double-progression
/// rule the plans describe.
bool readyToProgress(List<SetLog> previous, RepTarget target, int sets) {
  final top = target.high;
  if (top == null || previous.length < sets) return false;
  return previous.take(sets).every((s) => s.reps != null && s.reps! >= top);
}

/// A best beaten: the heaviest set for a loaded move, the most reps for a
/// bodyweight one.
class PersonalRecord {
  final String exerciseId;
  final bool byWeight;
  final double value;
  final double previous;

  const PersonalRecord(
      this.exerciseId, this.byWeight, this.value, this.previous);
}

double? _bestWeight(Iterable<SetLog> sets) {
  double? best;
  for (final s in sets) {
    if (!s.done || s.weight == null) continue;
    if (best == null || s.weight! > best) best = s.weight;
  }
  return best;
}

int? _bestReps(Iterable<SetLog> sets) {
  int? best;
  for (final s in sets) {
    if (!s.done || s.weight != null || s.reps == null) continue;
    if (best == null || s.reps! > best) best = s.reps;
  }
  return best;
}

/// The records [log] set against everything logged before it (a first
/// time sets the baseline, not a record).
List<PersonalRecord> recordsIn(SessionLog log, List<SessionLog> logs) {
  final earlier = logs
      .where((l) => l.id != log.id && l.startedAt.isBefore(log.startedAt))
      .toList();
  final out = <PersonalRecord>[];
  final seen = <String>{};
  for (final item in log.items) {
    if (!seen.add(item.exerciseId)) continue;
    final before = [
      for (final l in earlier)
        for (final it in l.items)
          if (it.exerciseId == item.exerciseId) ...it.sets,
    ];
    final now = [
      for (final it in log.items)
        if (it.exerciseId == item.exerciseId) ...it.sets,
    ];
    final w = _bestWeight(now), wBefore = _bestWeight(before);
    if (w != null && wBefore != null && w > wBefore) {
      out.add(PersonalRecord(item.exerciseId, true, w, wBefore));
      continue;
    }
    final r = _bestReps(now), rBefore = _bestReps(before);
    if (w == null && r != null && rBefore != null && r > rBefore) {
      out.add(PersonalRecord(
          item.exerciseId, false, r.toDouble(), rBefore.toDouble()));
    }
  }
  return out;
}

/// The best set ever logged for [exerciseId] and its date.
({SetLog set, DateTime at})? bestSet(List<SessionLog> logs, String exerciseId) {
  ({SetLog set, DateTime at})? best;
  for (final log in logs) {
    for (final item in log.items) {
      if (item.exerciseId != exerciseId) continue;
      for (final s in item.sets) {
        if (!s.done) continue;
        final b = best?.set;
        final better = b == null ||
            (s.weight ?? -1) > (b.weight ?? -1) ||
            ((s.weight ?? -1) == (b.weight ?? -1) &&
                (s.reps ?? -1) > (b.reps ?? -1));
        if (better) best = (set: s, at: log.startedAt);
      }
    }
  }
  return best;
}

/// The top weight (or, unloaded, the top reps) of each session that
/// trained [exerciseId], oldest first, at most [n].
List<double> trendFor(List<SessionLog> logs, String exerciseId, {int n = 8}) {
  final out = <double>[];
  for (final log in logs) {
    final sets = [
      for (final it in log.items)
        if (it.exerciseId == exerciseId) ...it.sets.where((s) => s.done),
    ];
    if (sets.isEmpty) continue;
    final w = _bestWeight(sets);
    final r = _bestReps(sets);
    final v = w ?? r?.toDouble();
    if (v != null) out.add(v);
    if (out.length == n) break;
  }
  return out.reversed.toList();
}

/// Weeks in a row with at least [goal] workouts (one by default, the way
/// trackers count a streak). The week under way counts once it is met and
/// never breaks the streak while it is still open.
int weekStreak(List<SessionLog> logs, {int? goal, DateTime? now}) {
  final need = goal == null || goal <= 0 ? 1 : goal;
  final counts = sessionsPerWeek(logs, weeks: 104, now: now);
  var streak = counts.last >= need ? 1 : 0;
  for (var i = counts.length - 2; i >= 0; i--) {
    if (counts[i] < need) break;
    streak++;
  }
  return streak;
}
