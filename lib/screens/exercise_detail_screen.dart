import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final ex = exercise;
    final hue = Iron.tier(ex.difficulty);
    return Scaffold(
      backgroundColor: Iron.bg,
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          // Placeholder until AI illustrations land (assets/images/<id>.png).
          IronCard(
            color: Iron.tint(hue),
            radius: Iron.rXL,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: IconBlob(exerciseIcon(ex.category),
                      color: hue, size: 96, onTint: true),
                ),
                const SizedBox(height: 18),
                Text(ex.name(zh), style: Iron.hero(28)),
                if (zh) Text(ex.nameEn, style: Iron.caption(color: Iron.faint)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    IronPill(L10n.t(ex.category),
                        color: hue, icon: exerciseIcon(ex.category), solid: true),
                    for (final m in ex.muscles)
                      IronPill(L10n.muscle(m), color: hue),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(L10n.t('difficulty'), style: Iron.caption()),
                    const SizedBox(width: 8),
                    SetDots(done: ex.difficulty, total: 3, color: hue),
                    const Spacer(),
                    Text(
                      '${ex.defSets} × ${ex.defReps} · ${ex.defRest}${L10n.t('seconds')}',
                      style: Iron.caption(color: hue),
                    ),
                  ],
                ),
              ],
            ),
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
