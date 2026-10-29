import 'package:flutter/material.dart';

import '../data/exercises_seed.dart';
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
      3 => 'advanced',
      _ => 'customTier',
    });

/// Friendly glyph per tier: sprout → climbing → on fire; custom = notepad.
IconData tierIcon(int tier) => switch (tier) {
      1 => Icons.eco_rounded,
      2 => Icons.trending_up_rounded,
      3 => Icons.local_fire_department_rounded,
      _ => Icons.edit_note_rounded,
    };

/// "每周 2-4 天" style label for a plan's intended weekly rhythm
/// (collapses to a single number when the range has one value).
String freqLabel(Plan plan) => L10n.tf(
    'freqRange',
    plan.daysMin == plan.daysMax
        ? '${plan.daysMin}'
        : '${plan.daysMin}-${plan.daysMax}');

/// "约 35 分钟 · 6 个动作" — the one-line summary every plan surface shows.
String planMeta(Plan plan) =>
    '${L10n.tf('estDuration', plan.estimatedMinutes())} · ${L10n.tf('exercisesCount', plan.items.length)}';

/// Localized summary of how many exercises need equipment, or '' when all
/// exercises are available.
String unavailableLabel(Plan plan, String? userEquipment) {
  final n = unavailableCount(plan, userEquipment);
  if (n == 0) return '';
  // name the heaviest requirement among the missing moves: any gym-only
  // exercise means dumbbells alone won't cover the plan
  final needsGym = plan.items.any((it) {
    final ex = exerciseMap[it.exerciseId];
    return ex != null &&
        !ex.availableFor(userEquipment) &&
        ex.requiredEquipment() == 'gym';
  });
  final eqName = L10n.t(needsGym ? 'obEqGym' : 'dumbbell');
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
              // stable tiebreak: seed order
              return builtinPlans.indexOf(a).compareTo(builtinPlans.indexOf(b));
            })),
  ];
}

/// Home card for one tier: a soft block in the tier's hue.

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
    final hue = Iron.tier(summary.tier);
    final missing =
        unavailableLabel(plan, Store.instance.settings.userEquipment);
    return IronCard(
      color: Iron.tint(hue),
      onTap: onOpenLibrary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IronPill(tierLabel(summary.tier),
                  color: hue, icon: tierIcon(summary.tier), solid: true),
              if (recommended) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: IronPill(L10n.t('recommendedForYou'),
                      color: hue, icon: Icons.star_rounded),
                ),
              ],
              const Spacer(),
              Text(L10n.tf('plansCount', summary.plans.length),
                  style: Iron.caption(color: hue)),
            ],
          ),
          const SizedBox(height: 14),
          Text(plan.title(zh), style: Iron.hero(19)),
          const SizedBox(height: 4),
          Text('${planMeta(plan)} · ${freqLabel(plan)}',
              style: Iron.caption()),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(missing, style: Iron.caption(color: hue)),
          ],
          const SizedBox(height: 14),
          IronButton(
            label: L10n.t('startWorkout'),
            icon: Icons.play_arrow_rounded,
            color: hue,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Plan row for the library: tier blob, title, meta, chevron.

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;

  const PlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final hue = Iron.tier(plan.builtin ? plan.tier : 0);
    final missing =
        unavailableLabel(plan, Store.instance.settings.userEquipment);
    return IronCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      radius: Iron.rM,
      child: Row(
        children: [
          IconBlob(plan.builtin ? tierIcon(plan.tier) : tierIcon(0),
              color: hue, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title(zh),
                    style: Iron.body(16, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  plan.builtin
                      ? '${planMeta(plan)} · ${freqLabel(plan)}'
                      : planMeta(plan),
                  style: Iron.caption(),
                ),
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(missing, style: Iron.caption(color: hue)),
                ],
              ],
            ),
          ),
          Icon(
            plan.builtin
                ? Icons.chevron_right_rounded
                : Icons.edit_rounded,
            size: 22,
            color: Iron.faint,
          ),
        ],
      ),
    );
  }
}
