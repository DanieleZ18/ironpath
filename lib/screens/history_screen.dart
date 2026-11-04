import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ios_chrome.dart';
import '../utils.dart';
import '../weekly_program.dart'
    show completedThisWeek, sessionsPerWeek, weekStartOf;
import '../widgets/bento.dart';
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
                icon: Icons.calendar_month_rounded,
                label: L10n.t('statThisWeek'),
                value: '${completedThisWeek(settings, logs)}',
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
    final complete = log.doneSets() == log.totalSets();
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: Iron.squircle(Iron.rM),
        shadows: Iron.shadow,
      ),
      child: Material(
        color: Iron.card,
        shape: Iron.squircle(Iron.rM),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: hue,
            collapsedIconColor: Iron.faint,
            tilePadding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: _dateBlob(log.startedAt, hue, zh),
            title: Text(log.planTitle(zh),
                style: Iron.body(15, weight: FontWeight.w800)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  IronPill(fmtTime(log.startedAt),
                      icon: Icons.schedule_rounded),
                  IronPill(fmtDuration(log.durationSeconds),
                      icon: Icons.timer_outlined),
                  IronPill('${log.doneSets()}/${log.totalSets()}',
                      color: complete ? Iron.accent : null,
                      icon: Icons.check_rounded),
                ],
              ),
            ),
            children: [
              for (final item in log.items)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: ShapeDecoration(
                    color: Iron.cardHi,
                    shape: Iron.squircle(Iron.rS),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            Store.instance
                                    .exerciseById(item.exerciseId)
                                    ?.name(zh) ??
                                item.exerciseId,
                            style: Iron.body(14, weight: FontWeight.w700)),
                      ),
                      Text(
                          '${item.doneCount}/${item.sets.length}${_weights(item)}',
                          style: Iron.caption()),
                    ],
                  ),
                ),
            ],
          ),
        ),
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

  String _weights(ItemLog item) {
    final ws = item.sets
        .where((s) => s.weight != null)
        .map((s) => '${fmtWeight(s.weight!)}kg')
        .toSet()
        .toList();
    return ws.isEmpty ? '' : ' · ${ws.join(', ')}';
  }
}
