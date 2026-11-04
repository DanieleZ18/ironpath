import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/substitutions.dart' as subs;
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/ios_chrome.dart';
import '../widgets/zoom_route.dart';
import '../widgets/muscle_glyph.dart';
import 'exercise_detail_screen.dart';
import 'plan_editor.dart';
import 'session_screen.dart';
import '../widgets/plan_card.dart';

/// Opens a plan's detail page by zooming it out of the tapped card
/// ([source] is the card's context; [radius] and [color] describe the card
/// so the page grows out of its exact shape).
Future<void> openPlanDetail(BuildContext source, Plan plan,
        {double radius = 24, Color? color}) =>
    openZoomed<void>(source, (_) => PlanDetailPage(plan: plan),
        radius: radius, color: color);

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

  /// iOS pattern: the destructive action sheet is the confirmation.
  Future<void> _deletePlan() async {
    final ok = await showIronActionSheet<bool>(
      context,
      message: L10n.t('deleteConfirm'),
      actions: [SheetAction(L10n.t('deletePlan'), true, destructive: true)],
      cancelLabel: L10n.t('cancel'),
    );
    if (ok == true && mounted) {
      Store.instance.customPlans.removeWhere((p) => p.id == plan.id);
      await Store.instance.save();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _edit(Plan p) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlanEditorPage(existing: p),
    ));
    if (mounted) setState(() {});
  }

  /// The plan's secondary actions: (label, value, destructive).
  List<(String, String, bool)> _moreEntries(Plan p) => [
        if (p.builtin)
          (L10n.t('copyPlan'), 'copy', false)
        else ...[
          (L10n.t('editPlan'), 'edit', false),
          (L10n.t('deletePlan'), 'delete', true),
        ],
      ];

  /// "…" on Apple devices: the secondary actions in an iOS action sheet.
  Future<void> _more(Plan p) async {
    final choice = await showIronActionSheet<String>(
      context,
      title: p.title(L10n.zh),
      actions: [
        for (final (label, value, destructive) in _moreEntries(p))
          SheetAction(label, value, destructive: destructive),
      ],
      cancelLabel: L10n.t('cancel'),
    );
    if (choice != null) await _onMore(p, choice);
  }

  Future<void> _onMore(Plan p, String choice) async {
    if (!mounted) return;
    switch (choice) {
      case 'copy':
        _copyPlan();
      case 'edit':
        await _edit(p);
      case 'delete':
        Store.instance.customPlans.removeWhere((x) => x.id == p.id);
        await Store.instance.save();
        if (mounted) Navigator.of(context).pop();
    }
  }

  void _start(Plan p) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      // a workout is a modal task: it slides up full screen
      fullscreenDialog: true,
      builder: (_) => SessionScreen(plan: p),
    ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final p = plan;
    final hue = Iron.tier(p.builtin ? p.tier : 0);
    final missing = unavailableLabel(p, Store.instance.settings.userEquipment);
    return IronPage(
      title: p.title(zh),
      // the hero card carries the big title; the bar's small one fades in
      // once that has scrolled away
      revealTitleAt: 70,
      actions: [
        if (isApple(context))
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(44, 44),
            onPressed: () => _more(p),
            child: Icon(CupertinoIcons.ellipsis_circle,
                size: 26, color: Iron.inkOf(Iron.accent)),
          )
        else
          // Android: overflow menu dropping down from the ⋮ button
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Iron.ink),
            tooltip: L10n.t('more'),
            onSelected: (choice) => _onMore(p, choice),
            itemBuilder: (context) => [
              for (final (label, value, destructive) in _moreEntries(p))
                PopupMenuItem(
                  value: value,
                  child: Text(label,
                      style: Iron.body(15,
                          color: destructive ? Iron.danger : Iron.ink,
                          weight: FontWeight.w600)),
                ),
            ],
          ),
      ],
      builder: (context, insets) => ListView(
        padding: EdgeInsets.fromLTRB(20, insets.top + 4, 20, 24),
        children: [
          // ---- hero block in the tier's hue
          IronCard(
            color: Iron.tint(hue),
            radius: Iron.rXL,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IronPill(p.builtin ? tierLabel(p.tier) : L10n.t('myPlans'),
                    color: hue,
                    icon: tierIcon(p.builtin ? p.tier : 0),
                    solid: true),
                const SizedBox(height: 14),
                Text(p.title(zh), style: Iron.hero(28)),
                if (p.desc(zh).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.desc(zh), style: Iron.body(14, color: Iron.sub)),
                ],
                if (p.builtin) ...[
                  const SizedBox(height: 14),
                  IronPill(freqLabel(p),
                      color: hue, icon: Icons.calendar_month_rounded),
                ],
              ],
            ),
          ),
          // ---- what it trains, how long, how much, with what
          const SizedBox(height: bentoGap),
          BentoSplit(
            lead: _focusTile(p, hue),
            stack: [
              BentoTile(
                child: BentoStat(
                  icon: Icons.schedule_rounded,
                  label: L10n.t('duration'),
                  value: L10n.tf('estDuration', p.estimatedMinutes()),
                  size: 20,
                ),
              ),
              BentoTile(
                child: BentoStat(
                  icon: Icons.format_list_numbered_rounded,
                  label: L10n.t('volume'),
                  value: L10n.tf(
                      'setsN', p.items.fold<int>(0, (a, i) => a + i.sets)),
                  note: L10n.tf('exercisesCount', p.items.length),
                  size: 20,
                ),
              ),
              BentoTile(
                child: BentoStat(
                  icon: Icons.fitness_center_rounded,
                  label: L10n.t('equipment'),
                  value: _equipmentLabel(p),
                  size: 20,
                ),
              ),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _notice(Icons.info_outline_rounded, missing, Iron.tier(3)),
          ],
          if (Store.instance.settings.ageBand == 'older' && p.tier >= 2) ...[
            const SizedBox(height: 12),
            _notice(Icons.self_improvement_rounded, L10n.t('olderDeloadHint'),
                Iron.tier(2)),
          ],
          const SizedBox(height: 20),
          for (var i = 0; i < p.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _itemTile(context, i, hue),
            ),
          const SizedBox(height: 4),
          if (p.builtin)
            OutlinedButton.icon(
              onPressed: _copyPlan,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(L10n.t('copyPlan')),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _edit(p),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(L10n.t('editPlan')),
            ),
          if (!p.builtin) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _deletePlan,
              child: Text(L10n.t('deletePlan'),
                  style: Iron.body(16,
                      color: Iron.danger, weight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      bottomBar: Frosted(
        border: Border(top: BorderSide(color: Iron.line, width: 0.5)),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: IronButton(
            label: L10n.t('startWorkout'),
            icon: Icons.play_arrow_rounded,
            color: hue,
            onPressed: () => _start(p),
          ),
        ),
      ),
    );
  }

  /// The muscles this plan works, most-trained first: a body figure with
  /// all of them lit and the top three named.
  Widget _focusTile(Plan p, Color hue) {
    final score = <String, int>{};
    for (final item in p.items) {
      final ex = Store.instance.exerciseById(item.exerciseId);
      if (ex == null) continue;
      for (var i = 0; i < ex.muscles.length; i++) {
        // the primary muscle counts double
        score[ex.muscles[i]] = (score[ex.muscles[i]] ?? 0) + (i == 0 ? 2 : 1);
      }
    }
    final ranked = score.keys.toList()
      ..sort((a, b) => score[b]!.compareTo(score[a]!));
    return BentoTile(
      hue: hue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoLabel(L10n.t('muscleFocus'),
              icon: Icons.accessibility_new_rounded, hue: hue),
          const SizedBox(height: 10),
          // front and back, shaded by how much of the plan hits each
          // muscle, grown to fill the tile the stats beside it make tall
          Expanded(
            child: Center(
              child: FittedBox(
                child: MuscleMap(
                  sets: {
                    for (final e in score.entries) e.key: e.value.toDouble()
                  },
                  full: ranked.isEmpty ? 1 : score[ranked.first]!.toDouble(),
                  color: hue,
                  height: 110,
                  onTint: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(ranked.take(3).map(L10n.muscle).join(' · '),
              style: Iron.body(14, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  /// The most any exercise in the plan needs.
  String _equipmentLabel(Plan p) {
    var need = 'none';
    for (final item in p.items) {
      final req =
          Store.instance.exerciseById(item.exerciseId)?.requiredEquipment();
      if (req == 'gym') need = 'gym';
      if (req == 'dumbbell' && need == 'none') need = 'dumbbell';
    }
    return L10n.t(switch (need) {
      'gym' => 'equipGym',
      'dumbbell' => 'equipDumbbell',
      _ => 'equipNone',
    });
  }

  Widget _notice(IconData icon, String text, Color hue) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: Iron.tint(hue),
        shape: Iron.squircle(Iron.rM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: hue),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Iron.body(13, color: Iron.ink))),
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
      IronPill(L10n.tf('warnIssue', label),
          color: Iron.danger, icon: Icons.warning_amber_rounded),
      if (altEx != null)
        IronPill(L10n.tf('swapTo', altEx.name(L10n.zh)),
            color: Iron.accent,
            icon: Icons.swap_horiz_rounded,
            onTap: () => _applySwap(index, altId!)),
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

  Widget _itemTile(BuildContext context, int i, Color hue) {
    final zh = L10n.zh;
    final item = plan.items[i];
    final ex = Store.instance.exerciseById(item.exerciseId);
    final chips = <Widget>[
      if (ex != null && !ex.availableFor(Store.instance.settings.userEquipment))
        IronPill(
            L10n.tf(
                'needsEquipment',
                L10n.t(ex.requiredEquipment() == 'dumbbell'
                    ? 'dumbbell'
                    : 'obEqGym')),
            icon: Icons.lock_outline_rounded),
      if (ex != null) ..._issueWidgets(context, i, ex),
    ];
    return IronCard(
      radius: Iron.rM,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      onTap: ex == null
          ? null
          : () {
              showExerciseDetail(context, ex);
            },
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              MuscleGlyph(
                  muscles: ex?.muscles ?? const [], color: hue, size: 48),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Iron.inkOf(hue),
                      shape: BoxShape.circle,
                      border: Border.all(color: Iron.card, width: 2)),
                  child: Text('${i + 1}',
                      style: Iron.caption(
                              color: Iron.isDark ? Iron.bg : Colors.white,
                              weight: FontWeight.w800)
                          .copyWith(fontSize: 10, height: 1)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex?.name(zh) ?? item.exerciseId,
                    style: Iron.body(15, weight: FontWeight.w800)),
                Text(
                    '${item.sets} × ${item.reps} · ${L10n.t('rest')} ${item.restSeconds}${L10n.t('seconds')}',
                    style: Iron.caption()),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Iron.faint),
        ],
      ),
    );
  }
}
