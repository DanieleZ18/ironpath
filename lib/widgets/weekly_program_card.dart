import 'package:flutter/material.dart';

import '../l10n.dart';
import '../store.dart';
import '../theme.dart';
import '../weekly_program.dart';

/// "Your weekly plan" card: the derived day-by-day rotation for this week,
/// with per-day done state and the suggested next session highlighted.

class WeeklyProgramCard extends StatelessWidget {
  final WeeklyProgram program;
  const WeeklyProgramCard({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final done = completedThisWeek(Store.instance.settings, Store.instance.logs);
    final suggested = done < program.slots.length ? done : null;

    return Container(
      decoration: BoxDecoration(
        color: Iron.card,
        borderRadius: const BorderRadius.all(Iron.rL),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, size: 16, color: Iron.accent),
              const SizedBox(width: 8),
              Text(L10n.t('weeklyPlan'),
                  style: Iron.body(16, weight: FontWeight.w600)),
              const Spacer(),
              Text(L10n.tf('freqRange', '${program.slots.length}'),
                  style: Iron.caption(color: Iron.accent)),
            ],
          ),
          if (program.alternates) ...[
            const SizedBox(height: 4),
            Text(L10n.t('altNote'), style: Iron.caption(color: Iron.faint)),
          ],
          const SizedBox(height: 10),
          for (var i = 0; i < program.slots.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _dayRow(context, i, i < done, suggested == i, zh),
            ),
        ],
      ),
    );
  }

  Widget _dayRow(
      BuildContext context, int index, bool done, bool suggested, bool zh) {
    final plan = program.slots[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: suggested
            ? Iron.accent.withValues(alpha: 0.10)
            : Iron.cardHi,
        borderRadius: const BorderRadius.all(Iron.rM),
        border: Border.all(
          color: suggested ? Iron.accent : Iron.line,
          width: suggested ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(L10n.tf('dayN', index + 1),
                style: Iron.caption(
                    color: suggested ? Iron.accent : Iron.faint)),
          ),
          Expanded(
            child: Text(
              plan.title(zh),
              style: Iron.body(14,
                  weight: suggested ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
          if (done)
            Row(
              children: [
                Icon(Icons.check, size: 14, color: Iron.accent),
                const SizedBox(width: 4),
                Text(L10n.t('weekDone'), style: Iron.caption()),
              ],
            )
          else if (suggested)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Iron.accent.withValues(alpha: 0.16),
                borderRadius: const BorderRadius.all(Iron.rS),
              ),
              child: Text(L10n.t('startHere'),
                  style: Iron.caption(color: Iron.accent)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}