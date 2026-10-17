import 'package:flutter/material.dart';

import '../data/substitutions.dart' as subs;
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'exercise_detail_screen.dart';
import 'plan_editor.dart';
import 'session_screen.dart';
import '../widgets/plan_card.dart';

class PlanDetailPage extends StatefulWidget {
  final Plan plan;
  const PlanDetailPage({super.key, required this.plan});

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  Plan get plan => Store.instance.planById(widget.plan.id) ?? widget.plan;

  void _copyPlan() {
    final copy =
        plan.copyAsCustom('custom_${DateTime.now().millisecondsSinceEpoch}');
    Store.instance.customPlans.add(copy);
    Store.instance.save();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(L10n.t('copyDone'))));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanEditorPage(existing: copy)),
    );
  }

  Future<void> _deletePlan() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.t('deletePlan')),
        content: Text(L10n.t('deleteConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(L10n.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(L10n.t('deletePlan'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      Store.instance.customPlans.removeWhere((p) => p.id == plan.id);
      await Store.instance.save();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final p = plan;
    return Scaffold(
      backgroundColor: Iron.bg,
      appBar: AppBar(
        title: Text(p.title(zh)),
        actions: [
          if (!p.builtin)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20),
              tooltip: L10n.t('deletePlan'),
              onPressed: _deletePlan,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.desc(zh).isNotEmpty) ...[
            Text(p.desc(zh), style: Iron.caption()),
            const SizedBox(height: 8),
            Text(freqLabel(p),
                style: Iron.caption(color: Iron.accent)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ],
          if (unavailableLabel(p, Store.instance.settings.userEquipment)
              .isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Iron.cardHi,
                  borderRadius: const BorderRadius.all(Iron.rS),
                ),
                child: Text(
                  unavailableLabel(
                      p, Store.instance.settings.userEquipment),
                  style: Iron.caption(color: Iron.sub),
                ),
              ),
            ),
          if (Store.instance.settings.ageBand == 'older' && p.tier >= 2) ...[
            IronCard(
              padding: const EdgeInsets.all(12),
              child: Text(L10n.t('olderDeloadHint'),
                  style: Iron.caption(color: Iron.sub)),
            ),
            const SizedBox(height: 14),
          ],
          for (var i = 0; i < p.items.length; i++) _itemTile(context, i),
          const SizedBox(height: 16),
          IronButton(
            label: L10n.t('startWorkout'),
            icon: Icons.play_arrow,
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (_) => SessionScreen(plan: p),
                  ))
                  .then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          const SizedBox(height: 10),
          if (p.builtin)
            OutlinedButton.icon(
              onPressed: _copyPlan,
              icon: const Icon(Icons.copy, size: 17),
              label: Text(L10n.t('copyPlan')),
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PlanEditorPage(existing: p),
                ));
                if (mounted) setState(() {});
              },
              icon: Icon(Icons.edit, size: 17),
              label: Text(L10n.t('editPlan')),
            ),
        ],
      ),
    );
  }

  /// Warning chip + (when a clean substitute exists) a one-tap swap chip
  /// for exercises that conflict with the user's flagged body issues.
  List<Widget> _issueWidgets(BuildContext context, int index, Exercise ex) {
    final issues = Store.instance.settings.bodyIssues;
    String? label;
    for (final issue in issues) {
      if (ex.contraindications.contains(issue)) {
        label = L10n.t(switch (issue) {
          'knee' => 'issueKnee',
          'shoulder' => 'issueShoulder',
          _ => 'issueLowerBack',
        });
        break;
      }
    }
    if (label == null) return const [];
    final altId = subs.substituteFor(ex.id, issues);
    final altEx = altId == null ? null : Store.instance.exerciseById(altId);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Iron.accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Iron.rS),
                ),
                child: Text(L10n.tf('warnIssue', label),
                    style: Iron.caption(color: Iron.sub)),
              ),
            ),
            if (altEx != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _applySwap(index, altId!),
                borderRadius: const BorderRadius.all(Iron.rS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Iron.cardHi,
                    borderRadius: const BorderRadius.all(Iron.rS),
                  ),
                  child: Text(L10n.tf('swapTo', altEx.name(L10n.zh)),
                      style: Iron.caption(color: Iron.accent)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// Builtin plans are duplicated to "my plans" first, then the
  /// contraindicated item is replaced with the suggested alternative.
  Future<void> _applySwap(int itemIndex, String altId) async {
    Plan p = plan;
    if (p.builtin) {
      p = p.copyAsCustom('custom_${DateTime.now().millisecondsSinceEpoch}');
      Store.instance.customPlans.add(p);
    }
    final old = p.items[itemIndex];
    p.items[itemIndex] = PlanItem(
      exerciseId: altId,
      sets: old.sets,
      reps: old.reps,
      restSeconds: old.restSeconds,
    );
    await Store.instance.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(L10n.t('copyDone'))));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanEditorPage(existing: p)),
    );
  }

  Widget _itemTile(BuildContext context, int i) {
    final zh = L10n.zh;
    final item = plan.items[i];
    final ex = Store.instance.exerciseById(item.exerciseId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Iron.card,
        borderRadius: const BorderRadius.all(Iron.rM),
        child: InkWell(
          onTap: ex == null
              ? null
              : () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ExerciseDetailPage(exercise: ex),
                  ));
                },
          borderRadius: const BorderRadius.all(Iron.rM),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style: Iron.body(13,
                          color: Iron.faint, weight: FontWeight.w600)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex?.name(zh) ?? item.exerciseId,
                          style: Iron.body(14)),
                      Text(
                          '${item.sets} × ${item.reps} · ${L10n.t('rest')} ${item.restSeconds}${L10n.t('seconds')}',
                          style: Iron.caption(color: Iron.faint)),
                      if (ex != null &&
                          !ex.availableFor(
                              Store.instance.settings.userEquipment))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Iron.cardHi,
                              borderRadius:
                                  const BorderRadius.all(Iron.rS),
                            ),
                            child: Text(
                              L10n.tf('needsEquipment',
                                  L10n.t(ex.requiredEquipment() == 'dumbbell'
                                      ? 'dumbbell'
                                      : 'obEqGym')),
                              style: Iron.caption(color: Iron.sub),
                            ),
                          ),
                        ),
                      if (ex != null) ..._issueWidgets(context, i, ex),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 17, color: Iron.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
