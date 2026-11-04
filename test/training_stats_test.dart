import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/models.dart';
import 'package:gym_app/training_stats.dart';
import 'package:gym_app/utils.dart';

SetLog s(double? w, int? r, {bool done = true, int i = 0}) =>
    SetLog(index: i, done: done, weight: w, reps: r);

SessionLog log(String id, DateTime at, List<ItemLog> items) => SessionLog(
    id: id,
    planId: 'p',
    planTitleEn: 'p',
    planTitleZh: 'p',
    startedAt: at,
    durationSeconds: 1800,
    items: items);

void main() {
  test('rep targets parse ranges, single counts and holds', () {
    final r = RepTarget.parse('8-12');
    expect((r.low, r.high, r.timed), (8, 12, false));
    expect(r.start, 8);
    expect(r.step, 1);
    final one = RepTarget.parse('10');
    expect((one.low, one.high), (10, 10));
    final hold = RepTarget.parse('30-45s');
    expect((hold.low, hold.high, hold.timed), (30, 45, true));
    expect(hold.step, 5);
    expect(RepTarget.parse('45 秒').timed, isTrue);
    // free text from a custom plan
    final free = RepTarget.parse('max reps');
    expect((free.low, free.high, free.timed), (null, null, false));
    expect(free.start, 10);
  });

  test('reps survive a JSON round trip; old logs have none', () {
    final back = SetLog.fromJson(s(12.5, 10).toJson());
    expect((back.weight, back.reps), (12.5, 10));
    final old = SetLog.fromJson({'index': 0, 'done': true, 'weight': 20});
    expect(old.reps, isNull);
    expect(s(null, null).toJson().containsKey('reps'), isFalse);
  });

  test('volume is kg × reps over done loaded sets, holds excluded', () {
    final l = log('a', DateTime(2026, 11, 2), [
      ItemLog(exerciseId: 'goblet_squat', sets: [
        s(14, 12),
        s(14, 10),
        s(14, 12, done: false), // not done
      ]),
      ItemLog(exerciseId: 'pushup', sets: [s(null, 12)]),
      ItemLog(exerciseId: 'plank', sets: [s(10, 40)]), // a hold, not reps
    ]);
    expect(sessionVolume(l), 14 * 12 + 14 * 10);
    expect(sessionReps(l), 12 + 10 + 12);
  });

  test('sets per muscle: main muscle full, the others half or whole', () {
    final l = log('a', DateTime(2026, 11, 2), [
      ItemLog(exerciseId: 'pushup', sets: [s(null, 10), s(null, 10)]),
    ]);
    final weighted = setsPerMuscle([l]);
    final hits = setsPerMuscle([l], weighted: false);
    expect(weighted['chest'], 2); // push-ups lead with the chest
    expect(weighted['triceps'], 1);
    expect(hits['triceps'], 2);
    final top = musclesBySets([l], 2);
    // tie on sets that hit it: the muscle that led them comes first
    expect(top.first.key, 'chest');
    expect(top.first.value, 2);
  });

  test('previous sets come from the newest log that did the move', () {
    final logs = [
      log('new', DateTime(2026, 11, 3), [
        ItemLog(exerciseId: 'goblet_squat', sets: [s(null, null, done: false)]),
      ]),
      log('mid', DateTime(2026, 11, 1), [
        ItemLog(exerciseId: 'goblet_squat', sets: [s(14, 12), s(14, 11)]),
      ]),
      log('old', DateTime(2026, 10, 28), [
        ItemLog(exerciseId: 'goblet_squat', sets: [s(12, 12)]),
      ]),
    ];
    final prev = previousSets(logs, 'goblet_squat');
    expect(prev.map((e) => e.reps), [12, 11]);
    expect(previousSets(logs, 'goblet_squat', except: 'mid').single.weight, 12);
    expect(previousSets(logs, 'pushup'), isEmpty);
  });

  test('ready to progress only when every planned set hit the top', () {
    final t = RepTarget.parse('8-12');
    expect(readyToProgress([s(14, 12), s(14, 12), s(14, 13)], t, 3), isTrue);
    expect(readyToProgress([s(14, 12), s(14, 11), s(14, 12)], t, 3), isFalse);
    expect(readyToProgress([s(14, 12), s(14, 12)], t, 3), isFalse);
    expect(readyToProgress([s(14, null)], t, 1), isFalse);
    expect(readyToProgress([s(14, 12)], RepTarget.parse('amrap'), 1), isFalse);
  });

  test('records beat earlier logs; a first time is not a record', () {
    final earlier = log('e', DateTime(2026, 10, 30), [
      ItemLog(exerciseId: 'goblet_squat', sets: [s(14, 12)]),
      ItemLog(exerciseId: 'pushup', sets: [s(null, 12)]),
    ]);
    final now = log('n', DateTime(2026, 11, 2), [
      ItemLog(exerciseId: 'goblet_squat', sets: [s(16, 8)]),
      ItemLog(exerciseId: 'pushup', sets: [s(null, 15)]),
      ItemLog(exerciseId: 'plank', sets: [s(null, 60)]), // never done before
    ]);
    final records = recordsIn(now, [now, earlier]);
    expect(records, hasLength(2));
    final squat = records.firstWhere((r) => r.exerciseId == 'goblet_squat');
    expect((squat.byWeight, squat.value, squat.previous), (true, 16.0, 14.0));
    final push = records.firstWhere((r) => r.exerciseId == 'pushup');
    expect((push.byWeight, push.value, push.previous), (false, 15.0, 12.0));
    // the same weight again is no record
    final same = log('s', DateTime(2026, 11, 4), [
      ItemLog(exerciseId: 'goblet_squat', sets: [s(16, 9)]),
    ]);
    expect(recordsIn(same, [same, now, earlier]), isEmpty);
  });

  test('best set, trend and labels', () {
    final logs = [
      log('b', DateTime(2026, 11, 2), [
        ItemLog(exerciseId: 'goblet_squat', sets: [s(16, 8), s(14, 12)]),
      ]),
      log('a', DateTime(2026, 10, 30), [
        ItemLog(exerciseId: 'goblet_squat', sets: [s(14, 12)]),
      ]),
    ];
    final best = bestSet(logs, 'goblet_squat')!;
    expect((best.set.weight, best.set.reps), (16.0, 8));
    expect(best.at, DateTime(2026, 11, 2));
    expect(trendFor(logs, 'goblet_squat'), [14.0, 16.0]); // oldest first
    expect(setLabel(s(12.5, 10)), '12.5 × 10');
    expect(setLabel(s(null, 12)), '12');
    expect(setLabel(s(20, null)), '20 kg');
    expect(setLabel(s(null, 45), timed: true), '45 s');
    expect(fmtThousands(12480), '12,480');
    expect(fmtThousands(999), '999');
  });

  test('week streak counts weeks in a row; the open week never breaks it', () {
    final now = DateTime(2026, 11, 4, 20); // Wednesday
    SessionLog at(int y, int m, int d) =>
        log('$y$m$d', DateTime(y, m, d, 9), const []);
    final logs = [
      at(2026, 10, 30), // last week
      at(2026, 10, 21), // two weeks ago
      at(2026, 10, 7), // a gap before it
    ];
    // nothing yet this week: still 2 (this week is open)
    expect(weekStreak(logs, now: now), 2);
    expect(weekStreak([at(2026, 11, 2), ...logs], now: now), 3);
    // with a goal of two a week, last week's single workout ends it
    expect(weekStreak(logs, goal: 2, now: now), 0);
    expect(weekStreak(const [], now: now), 0);
  });
}
