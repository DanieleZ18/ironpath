import 'package:flutter/material.dart';

import '../data/plans_seed.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../weekly_program.dart'
    show unavailableCount, freqDistance;

String tierLabel(int tier) => L10n.t(switch (tier) {
      1 => 'beginner',
      2 => 'intermediate',
      _ => 'advanced',
    });


/// "每周 2-4 天" style label for a plan's intended weekly rhythm
/// (collapses to a single number when the range has one value).
String freqLabel(Plan plan) => L10n.tf(
    'freqRange',
    plan.daysMin == plan.daysMax
        ? '${plan.daysMin}'
        : '${plan.daysMin}-${plan.daysMax}');


/// Localized summary of how many exercises need equipment, or '' when all
/// exercises are available.
String unavailableLabel(Plan plan, String? userEquipment) {
  final n = unavailableCount(plan, userEquipment);
  if (n == 0) return '';
  final eqName = L10n.t('dumbbell');
  return L10n.tf('unavailableCount', n).replaceFirst('{eq}', eqName);
}

class TierSummary {
  final int tier;
  final List<Plan> plans;
  const TierSummary(this.tier, this.plans);

  /// Plans are sorted by (unavailable count, frequency distance) in
  /// [tierSummaries], so the first plan is the one the user can most fully
  /// follow at their chosen weekly rhythm.
  Plan get bestPlan => plans.first;
}

List<TierSummary> tierSummaries() {
  final eq = Store.instance.settings.userEquipment;
  final days = Store.instance.settings.userDays;
  int score(Plan p) =>
      unavailableCount(p, eq) * 1000 + freqDistance(p, days);
  return [
    for (final tier in [1, 2, 3])
      TierSummary(
          tier,
          builtinPlans
              .where((p) => p.tier == tier)
              .toList()
            ..sort((a, b) {
              final c = score(a).compareTo(score(b));
              if (c != 0) return c;
              // stable tiebreak: seed order (builtin), then custom order
              return builtinPlans.indexOf(a).compareTo(builtinPlans.indexOf(b));
            })),
  ];
}

/// Home card for one tier: matte card, small tier dot, mint action.

class TierCard extends StatelessWidget {
  final TierSummary summary;
  final VoidCallback onStart;
  final VoidCallback onOpenLibrary;
  final bool recommended;

  const TierCard({
    super.key,
    required this.summary,
    required this.onStart,
    required this.onOpenLibrary,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final plan = summary.bestPlan;
    final tierCol = Iron.tierColor[summary.tier] ?? Iron.sub;
    return Container(
      decoration: BoxDecoration(
        color: Iron.card,
        borderRadius: BorderRadius.all(Iron.rL),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: tierCol, borderRadius: const BorderRadius.all(Radius.circular(4))),
              ),
              SizedBox(width: 8),
              Text(tierLabel(summary.tier),
                  style: Iron.body(16, weight: FontWeight.w600)),
              if (recommended) ...[
                SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Iron.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.all(Iron.rS),
                  ),
                  child: Text(L10n.t('recommendedForYou'),
                      style: Iron.caption(color: Iron.accent)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              Text(L10n.tf('plansCount', summary.plans.length),
                  style: Iron.caption(color: Iron.faint)),
            ],
          ),
          SizedBox(height: 8),
          Text(plan.title(zh), style: Iron.body(14, color: Iron.sub)),
          SizedBox(height: 2),
          Text(
            '${L10n.tf('estDuration', plan.estimatedMinutes())} · ${L10n.tf('exercisesCount', plan.items.length)} · ${freqLabel(plan)}',
            style: Iron.caption(color: Iron.faint),
          ),
          if (unavailableLabel(plan, Store.instance.settings.userEquipment)
              .isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              unavailableLabel(
                  plan, Store.instance.settings.userEquipment),
              style: Iron.caption(color: Iron.sub),
            ),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: Icon(Icons.play_arrow, size: 18),
                  label: Text(L10n.t('startWorkout')),
                ),
              ),
              IconButton(
                onPressed: onOpenLibrary,
                icon: Icon(Icons.list, color: Iron.sub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact plan row for the library.

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;

  const PlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    return Material(
      color: Iron.card,
      borderRadius: const BorderRadius.all(Iron.rM),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Iron.rM),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title(zh), style: Iron.body(15)),
                        SizedBox(height: 2),
                        Text(
                          '${L10n.tf('exercisesCount', plan.items.length)} · ${L10n.tf('estDuration', plan.estimatedMinutes())} · ${freqLabel(plan)}',
                          style: Iron.caption(color: Iron.faint),
                        ),
                        if (unavailableLabel(
                                plan, Store.instance.settings.userEquipment)
                            .isNotEmpty)
                          Text(
                            unavailableLabel(plan,
                                Store.instance.settings.userEquipment),
                            style: Iron.caption(color: Iron.sub),
                          ),
                      ],
                    ),
                  ),
              Icon(
                plan.builtin ? Icons.chevron_right : Icons.edit_outlined,
                size: 17,
                color: Iron.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
