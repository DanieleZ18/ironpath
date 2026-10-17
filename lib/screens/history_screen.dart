import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';

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
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(L10n.t('noWorkoutsYet'),
              textAlign: TextAlign.center, style: Iron.caption()),
        ),
      );
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final log in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Iron.card,
                  borderRadius: BorderRadius.all(Iron.rL),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: Iron.accent,
                    collapsedIconColor: Iron.sub,
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    title: Text(log.planTitle(zh), style: Iron.body(15)),
                    subtitle: Text(
                        '${fmtDate(log.startedAt)} · ${fmtDuration(log.durationSeconds)} · ${log.doneSets()}/${log.totalSets()}',
                        style: Iron.caption(color: Iron.faint)),
                    children: [
                      for (final item in log.items)
                        ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                              Store.instance
                                      .exerciseById(item.exerciseId)
                                      ?.name(zh) ??
                                  item.exerciseId,
                              style: Iron.body(13)),
                          subtitle: Text(
                              '${item.doneCount}/${item.sets.length}${_weights(item)}',
                              style: Iron.caption(color: Iron.faint)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _weights(ItemLog item) {
    final ws = item.sets
        .where((s) => s.weight != null)
        .map((s) => '${_fmtWeight(s.weight!)}kg')
        .toSet()
        .toList();
    return ws.isEmpty ? '' : ' · ${ws.join(', ')}';
  }

  String _fmtWeight(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
}
