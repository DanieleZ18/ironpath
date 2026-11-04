import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ios_chrome.dart';
import '../utils.dart';
import '../weekly_program.dart' show sessionsPerWeek, weekStartOf;
import '../training_stats.dart';
import '../widgets/bento.dart';
import '../widgets/muscle_glyph.dart';
import '../widgets/weekly_chart.dart';

class HistoryScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const HistoryScreen({super.key, this.scrollController});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final logs = Store.instance.logs;
    // header widgets first, then one lazily built card per log — history
    // grows without bound, so only visible cards are built
    final settings = Store.instance.settings;
    final now = DateTime.now();
    final header = <Widget>[
      if (logs.isEmpty)
        _empty()
      else ...[
        // headline numbers: the running total leads, this week and sets
        // done stack beside it
        BentoSplit(
          lead: BentoTile(
            hue: Iron.accent,
            child: BentoStat(
              icon: Icons.emoji_events_rounded,
              label: L10n.t('statSessions'),
              value: '${logs.length}',
              hue: Iron.accent,
              size: 40,
              extra: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.t('totalTime'),
                      style: Iron.caption(color: Iron.faint)),
                  Text(
                      fmtHoursMinutes(
                          logs.fold<int>(0, (a, l) => a + l.durationSeconds),
                          zh),
                      style: Iron.body(15, weight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          stack: [
            BentoTile(
              hue: Iron.tier(1),
              child: BentoStat(
                icon: Icons.local_fire_department_rounded,
                label: L10n.t('streak'),
                value: _weeks(weekStreak(logs, now: now)),
                hue: Iron.tier(1),
              ),
            ),
            BentoTile(
              hue: Iron.tier(2),
              child: BentoStat(
                icon: Icons.check_circle_rounded,
                label: L10n.t('statSets'),
                value: '${logs.fold<int>(0, (a, l) => a + l.doneSets())}',
                hue: Iron.tier(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: bentoGap),
        WeeklyChartTile(
          counts: sessionsPerWeek(logs, now: now),
          weekStarts: [
            for (var i = 7; i >= 0; i--) weekStartOf(now, weeksAgo: i)
          ],
          goal: settings.userDays,
        ),
        const SizedBox(height: bentoGap),
        _musclesTile(logs, now),
        const SizedBox(height: 18),
      ],
    ];
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        largeTitleBar(L10n.t('tabHistory')),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset(context)),
          sliver: SliverList.builder(
            itemCount: header.length + logs.length,
            itemBuilder: (context, i) => i < header.length
                ? header[i]
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _swipeToDelete(logs[i - header.length], zh),
                  ),
          ),
        ),
      ],
    );
  }

  /// iOS-style swipe left to delete, with an undo snackbar instead of a
  /// confirmation dialog.
  Widget _swipeToDelete(SessionLog log, bool zh) {
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: ShapeDecoration(
          color: Iron.inkOf(Iron.danger),
          shape: Iron.squircle(Iron.rM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.delete_solid,
                color: Iron.isDark ? Iron.bg : Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(L10n.t('delete'),
                style: Iron.body(15,
                    weight: FontWeight.w800,
                    color: Iron.isDark ? Iron.bg : Colors.white)),
          ],
        ),
      ),
      onDismissed: (_) => _delete(log),
      child: _logCard(log, zh),
    );
  }

  void _delete(SessionLog log) {
    final logs = Store.instance.logs;
    final index = logs.indexOf(log);
    setState(() => logs.remove(log));
    Store.instance.save();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(L10n.t('logDeleted')),
      action: SnackBarAction(
        label: L10n.t('undo'),
        textColor:
            Iron.isDark ? Iron.inkOf(Iron.accent) : Iron.tint(Iron.accent),
        onPressed: () {
          if (!mounted) return;
          setState(() => logs.insert(index.clamp(0, logs.length), log));
          Store.instance.save();
        },
      ),
    ));
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          IconBlob(Icons.event_note_rounded, size: 96, color: Iron.tier(1)),
          const SizedBox(height: 18),
          Text(L10n.t('emptyHistoryTitle'),
              textAlign: TextAlign.center, style: Iron.hero(20)),
          const SizedBox(height: 6),
          Text(L10n.t('noWorkoutsYet'),
              textAlign: TextAlign.center, style: Iron.caption()),
        ],
      ),
    );
  }

  Widget _logCard(SessionLog log, bool zh) {
    final plan = Store.instance.planById(log.planId);
    final hue = Iron.tier(plan == null || !plan.builtin ? 0 : plan.tier);
    final volume = sessionVolume(log);
    final reps = sessionReps(log);
    final done = log.doneSets(), total = log.totalSets();
    final d = log.startedAt;
    final when =
        '${zh ? '周${fmtWeekdayShort(d.weekday, true)}' : fmtWeekdayShort(d.weekday, false)} ${fmtTime(d)}';
    return IronCard(
      radius: Iron.rM,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dateBlob(d, hue, zh),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.planTitle(zh),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Iron.body(15, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(when, style: Iron.caption(color: Iron.faint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // the workout's numbers, labelled, the way trackers sum a session
          Row(
            children: [
              _fact(
                  L10n.t('duration'), fmtHoursMinutes(log.durationSeconds, zh)),
              _fact(
                  L10n.t('statSets'), done == total ? '$done' : '$done/$total',
                  hue: done == total ? Iron.accent : null),
              if (volume > 0)
                _fact(L10n.t('tonnage'), '${fmtThousands(volume)} kg')
              else if (reps > 0)
                _fact(L10n.t('totalReps'), '$reps'),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: Iron.line),
          const SizedBox(height: 6),
          for (final item in log.items) _exerciseLine(item, zh),
        ],
      ),
    );
  }

  Widget _fact(String label, String value, {Color? hue}) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Iron.caption(color: Iron.faint).copyWith(fontSize: 12)),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Iron.body(15, weight: FontWeight.w800, color: hue)),
          ],
        ),
      );

  /// One exercise of a logged workout: sets done and its best set.
  Widget _exerciseLine(ItemLog item, bool zh) {
    final name = Store.instance.exerciseById(item.exerciseId)?.name(zh) ??
        item.exerciseId;
    final n = item.doneCount;
    final best = _best(item);
    final timed = isTimed(item.exerciseId);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Iron.body(14,
                    weight: FontWeight.w700,
                    color: n == 0 ? Iron.faint : Iron.ink)),
          ),
          const SizedBox(width: 8),
          Text(
              n == item.sets.length
                  ? L10n.tf('setsDone', n)
                  : '$n/${item.sets.length}',
              style: Iron.caption(color: Iron.faint)),
          if (best != null) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 74,
              child: Text(setLabel(best, timed: timed),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Iron.caption(color: Iron.sub)),
            ),
          ],
        ],
      ),
    );
  }

  /// The set worth showing: heaviest, then most reps.
  SetLog? _best(ItemLog item) {
    SetLog? b;
    for (final s in item.sets) {
      if (!s.done || (s.weight == null && s.reps == null)) continue;
      if (b == null ||
          (s.weight ?? -1) > (b.weight ?? -1) ||
          ((s.weight ?? -1) == (b.weight ?? -1) &&
              (s.reps ?? -1) > (b.reps ?? -1))) {
        b = s;
      }
    }
    return b;
  }

  String _weeks(int n) =>
      n == 1 ? L10n.t('streakOneWeek') : L10n.tf('streakWeeks', n);

  /// What the last 30 days trained, as a muscle map and the top muscles.
  Widget _musclesTile(List<SessionLog> logs, DateTime now) {
    final recent =
        logsSince(logs, DateTime(now.year, now.month, now.day - 29)).toList();
    final shade = setsPerMuscle(recent);
    final top = musclesBySets(recent, 5);
    return BentoTile(
      child: Row(
        children: [
          MuscleMap(sets: shade, full: 12, height: 150, onTint: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BentoLabel(L10n.t('last30Muscles'),
                    icon: Icons.accessibility_new_rounded),
                const SizedBox(height: 10),
                if (top.isEmpty)
                  Text(L10n.t('noMusclesYet'), style: Iron.caption())
                else
                  for (final m in top)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(L10n.muscle(m.key),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Iron.body(14, weight: FontWeight.w700)),
                          ),
                          Text(L10n.tf('setsDone', m.value),
                              style: Iron.caption(color: Iron.faint)),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBlob(DateTime d, Color hue, bool zh) {
    return Container(
      width: 50,
      height: 54,
      decoration: ShapeDecoration(
        color: Iron.tint(hue),
        shape: Iron.squircle(Iron.inner(Iron.rM, 6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${d.day}', style: Iron.hero(20, color: hue)),
          Text(fmtMonthShort(d, zh),
              style: Iron.caption(color: hue).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
