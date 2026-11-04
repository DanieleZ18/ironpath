import 'package:flutter/material.dart';

import '../data/exercise_motions.dart';
import '../l10n.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../theme.dart';
import '../weekly_program.dart';
import 'exercise_motion.dart';
import 'plan_card.dart';

/// Home hero: the session to do next, in its tier's hue, with the week's
/// progress as dots. When the week is done it turns into a celebration.

class TodayCard extends StatelessWidget {
  final Plan? plan; // null = week complete
  final int dayIndex; // 0-based slot of [plan] in the week
  final int done;
  final int total;
  final bool recommended; // no weekly program: plain recommendation
  final VoidCallback? onStart;

  /// Opens the plan; gets the card's own context so the page can zoom out
  /// of it.
  final void Function(BuildContext source)? onOpen;

  const TodayCard({
    super.key,
    required this.plan,
    required this.dayIndex,
    required this.done,
    required this.total,
    this.recommended = false,
    this.onStart,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final p = plan;
    if (p == null) {
      return IronCard(
        color: Iron.tint(Iron.accent),
        padding: const EdgeInsets.all(22),
        radius: Iron.rXL,
        child: Row(
          children: [
            IconBlob(Icons.celebration_rounded, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.t('weekAllDone'), style: Iron.hero(19)),
                  const SizedBox(height: 4),
                  Text(L10n.t('weekAllDoneBody'), style: Iron.caption()),
                  const SizedBox(height: 10),
                  SetDots(done: done, total: total),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final hue = Iron.tier(p.tier);
    final first = p.items.isEmpty
        ? null
        : Store.instance.exerciseById(p.items.first.exerciseId);
    return Builder(
        builder: (card) => IronCard(
              color: Iron.tint(hue),
              padding: const EdgeInsets.all(20),
              radius: Iron.rXL,
              onTap: onOpen == null ? null : () => onOpen!(card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IronPill(tierLabel(p.tier),
                                color: hue,
                                icon: tierIcon(p.tier),
                                solid: true),
                            const SizedBox(height: 14),
                            Text(
                                recommended
                                    ? L10n.t('recommendedForYou')
                                    : '${L10n.t('todayPlan')} · ${L10n.tf('dayN', dayIndex + 1)}',
                                style: Iron.eyebrow(color: hue)),
                            const SizedBox(height: 4),
                            Text(p.title(zh), style: Iron.hero(24)),
                            const SizedBox(height: 6),
                            Text(planMeta(p), style: Iron.caption()),
                          ],
                        ),
                      ),
                      // the first move, demonstrated: what the session
                      // opens with, moving
                      if (first != null) ...[
                        const SizedBox(width: 12),
                        _FirstMove(exercise: first, hue: hue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  IronButton(
                    label: L10n.t('startWorkout'),
                    icon: Icons.play_arrow_rounded,
                    color: hue,
                    onPressed: onStart,
                  ),
                ],
              ),
            ));
  }
}

/// The session's first exercise as a looping demo on the card surface,
/// named underneath.
class _FirstMove extends StatelessWidget {
  final Exercise exercise;
  final Color hue;
  const _FirstMove({required this.exercise, required this.hue});

  @override
  Widget build(BuildContext context) {
    final name = exercise.name(L10n.zh);
    return SizedBox(
      width: 112,
      child: Column(
        children: [
          Container(
            height: 112,
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: Iron.card,
              shape: Iron.squircle(Iron.inner(Iron.rXL, 20)),
            ),
            child: Semantics(
              image: true,
              label: L10n.tf('demoOf', name),
              child: ExerciseMotionView(
                spec: motionFor(exercise.id),
                muscles: exercise.muscles,
                color: hue,
                onTint: true,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Iron.caption(color: Iron.sub).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// "Your weekly plan": the derived day-by-day rotation, with per-day done
/// state and the suggested next session highlighted. Rows open the plan.

class WeeklyProgramCard extends StatelessWidget {
  final WeeklyProgram program;
  final int done;
  final void Function(BuildContext source, Plan plan) onOpen;

  const WeeklyProgramCard({
    super.key,
    required this.program,
    required this.done,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final suggested = done < program.slots.length ? done : null;

    return IronCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(L10n.t('weeklyPlan'),
                      style: Iron.body(17, weight: FontWeight.w800)),
                ),
                IronPill(L10n.tf('freqRange', '${program.slots.length}'),
                    color: Iron.accent, icon: Icons.calendar_month_rounded),
              ],
            ),
          ),
          if (program.alternates)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Text(L10n.t('altNote'), style: Iron.caption()),
            ),
          const SizedBox(height: 12),
          for (var i = 0; i < program.slots.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _dayRow(i, i < done, suggested == i, zh),
            ),
        ],
      ),
    );
  }

  Widget _dayRow(int index, bool isDone, bool suggested, bool zh) {
    final plan = program.slots[index];
    final hue = Iron.tier(plan.tier);
    return Pressable(
        child: Builder(
            builder: (row) => Material(
                  color: suggested ? Iron.tint(hue) : Colors.transparent,
                  shape: Iron.squircle(Iron.rM),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpen(row, plan),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          // day badge: check when done, number otherwise
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Iron.accent
                                  : suggested
                                      ? Iron.inkOf(hue)
                                      : Iron.cardHi,
                              shape: BoxShape.circle,
                            ),
                            child: isDone
                                ? Icon(Icons.check_rounded,
                                    size: 20, color: Iron.onAccent)
                                : Text('${index + 1}',
                                    style: Iron.body(14,
                                        weight: FontWeight.w800,
                                        color: suggested
                                            ? (Iron.isDark
                                                ? Iron.bg
                                                : Colors.white)
                                            : Iron.sub)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(L10n.tf('dayN', index + 1),
                                    style: Iron.caption(
                                        color: suggested ? hue : Iron.faint)),
                                Text(
                                  plan.title(zh),
                                  style: Iron.body(15,
                                      weight: FontWeight.w700,
                                      color: isDone ? Iron.sub : Iron.ink),
                                ),
                              ],
                            ),
                          ),
                          if (isDone)
                            IronPill(L10n.t('weekDone'), color: Iron.accent)
                          else if (suggested)
                            IronPill(L10n.t('startHere'),
                                color: hue, solid: true)
                          else
                            Icon(Icons.chevron_right_rounded,
                                color: Iron.faint),
                        ],
                      ),
                    ),
                  ),
                )));
  }
}
