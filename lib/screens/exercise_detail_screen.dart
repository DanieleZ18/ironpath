import 'package:flutter/material.dart';

import '../data/exercise_motions.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/exercise_motion.dart';
import '../widgets/ios_chrome.dart';
import '../widgets/muscle_glyph.dart';
import '../widgets/plan_card.dart' show tierLabel;

/// Exercise details as an iOS card sheet over the current page; drag down
/// or tap "Done" to close.
Future<void> showExerciseDetail(BuildContext context, Exercise exercise) =>
    showIronSheet<void>(
      context,
      (context, controller) =>
          ExerciseDetailView(exercise: exercise, controller: controller),
    );

class ExerciseDetailView extends StatelessWidget {
  final Exercise exercise;
  final ScrollController? controller;
  const ExerciseDetailView(
      {super.key, required this.exercise, this.controller});

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final ex = exercise;
    final hue = Iron.tier(ex.difficulty);
    return Column(
      children: [
        SheetHeader(
          title: L10n.t('description'),
          trailing: BarTextButton(L10n.t('done'),
              bold: true, onPressed: () => Navigator.of(context).pop()),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
                20, 4, 20, 28 + MediaQuery.paddingOf(context).bottom),
            children: [
              // ---- the move itself, looping (a still pose under Reduce
              // Motion), working muscles lit in the difficulty hue
              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                decoration: ShapeDecoration(
                  color: Iron.tint(hue),
                  shape: Iron.squircle(Iron.rXL),
                ),
                child: Semantics(
                  image: true,
                  label: L10n.tf('demoOf', ex.name(zh)),
                  // tap to watch it again
                  child: ExerciseMotionView(
                      spec: motionFor(ex.id),
                      muscles: ex.muscles,
                      color: hue,
                      repeats: 4,
                      replayOnTap: true),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name(zh), style: Iron.hero(28)),
                    if (zh)
                      Text(ex.nameEn, style: Iron.caption(color: Iron.faint)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BentoSplit(
                lead: BentoTile(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BentoLabel(L10n.t('muscles'),
                          icon: Icons.accessibility_new_rounded),
                      const SizedBox(height: 10),
                      const Spacer(),
                      Center(
                        child: MuscleGlyph(
                            muscles: ex.muscles,
                            color: hue,
                            size: 120,
                            radius: Iron.inner(Iron.rL, 16)),
                      ),
                      const Spacer(),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in ex.muscles)
                            IronPill(L10n.muscle(m), color: hue),
                        ],
                      ),
                    ],
                  ),
                ),
                stack: [
                  BentoTile(
                    hue: hue,
                    child: BentoStat(
                      icon: Icons.repeat_rounded,
                      label: L10n.t('target'),
                      value: '${ex.defSets} × ${ex.defReps}',
                      note:
                          '${L10n.t('rest')} ${ex.defRest}${L10n.t('seconds')}',
                      hue: hue,
                      size: 20,
                    ),
                  ),
                  BentoTile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BentoLabel(L10n.t('difficulty'),
                            icon: Icons.signal_cellular_alt_rounded),
                        const SizedBox(height: 8),
                        const Spacer(),
                        Text(tierLabel(ex.difficulty),
                            style: Iron.body(15, weight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        SetDots(
                            done: ex.difficulty,
                            total: 3,
                            color: hue,
                            size: 10),
                      ],
                    ),
                  ),
                  BentoTile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BentoLabel(L10n.t('equipment'),
                            icon: exerciseIcon(ex.category)),
                        const SizedBox(height: 8),
                        const Spacer(),
                        Text(L10n.t(ex.category),
                            style: Iron.body(15, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(Icons.menu_book_rounded, L10n.t('description'),
                  [ex.desc(zh)], Iron.accent),
              _section(Icons.check_circle_rounded, L10n.t('formCues'),
                  ex.cues(zh), Iron.accent,
                  numbered: true),
              _section(Icons.error_outline_rounded, L10n.t('commonMistakes'),
                  ex.mistakes(zh), Iron.danger),
              _section(Icons.trending_up_rounded, L10n.t('progression'),
                  [ex.prog(zh)], Iron.tier(3)),
              _section(Icons.trending_down_rounded, L10n.t('regression'),
                  [ex.reg(zh)], Iron.tier(1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(IconData icon, String title, List<String> lines, Color hue,
      {bool numbered = false}) {
    final visible = lines.where((l) => l.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IronCard(
        radius: Iron.rM,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBlob(icon, color: hue, size: 34),
                const SizedBox(width: 10),
                Text(title, style: Iron.body(16, weight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < visible.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (visible.length > 1)
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Iron.tint(hue), shape: BoxShape.circle),
                        child: numbered
                            ? Text('${i + 1}',
                                style: Iron.caption(
                                        color: hue, weight: FontWeight.w800)
                                    .copyWith(fontSize: 11, height: 1))
                            : Icon(Icons.close_rounded, size: 13, color: hue),
                      ),
                    Expanded(
                      child: Text(visible[i],
                          style: Iron.body(14, color: Iron.sub)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
