import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../weekly_program.dart' show completedThisWeek;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(L10n.t('tabHistory'), style: Iron.hero(28)),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            _empty()
          else ...[
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        value: '${logs.length}',
                        label: L10n.t('statSessions'))),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        value:
                            '${completedThisWeek(Store.instance.settings, logs)}',
                        label: L10n.t('statThisWeek'),
                        color: Iron.tier(1))),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        value:
                            '${logs.fold<int>(0, (a, l) => a + l.doneSets())}',
                        label: L10n.t('statSets'),
                        color: Iron.tier(2))),
              ],
            ),
            const SizedBox(height: 18),
            for (final log in logs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _logCard(log, zh),
              ),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
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
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Iron.rM),
        boxShadow: Iron.shadow,
      ),
      child: Material(
        color: Iron.card,
        borderRadius: const BorderRadius.all(Iron.rM),
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
                  IronPill(fmtTime(log.startedAt), icon: Icons.schedule_rounded),
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
                  decoration: BoxDecoration(
                    color: Iron.cardHi,
                    borderRadius: const BorderRadius.all(Iron.rS),
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
      decoration: BoxDecoration(
        color: Iron.tint(hue),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
