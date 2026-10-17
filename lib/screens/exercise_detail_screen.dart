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
    return Scaffold(
      backgroundColor: Iron.bg,
      appBar: AppBar(title: Text(ex.name(zh))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Placeholder until AI illustrations land (assets/images/<id>.png).
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Iron.card,
              borderRadius: BorderRadius.all(Iron.rL),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ex.category == 'dumbbell'
                      ? Icons.fitness_center
                      : Icons.accessibility_new,
                  size: 40,
                  color: Iron.faint,
                ),
                SizedBox(height: 6),
                Text(ex.nameEn,
                    style: Iron.caption(color: Iron.faint)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(label: Text(L10n.t(ex.category))),
              for (final m in ex.muscles) Chip(label: Text(L10n.muscle(m))),
              Chip(
                  label: Text(
                      '${L10n.t('difficulty')} ${'★' * ex.difficulty}')),
            ],
          ),
          SizedBox(height: 16),
          _section(context, L10n.t('description'), [ex.desc(zh)]),
          _section(context, L10n.t('formCues'), ex.cues(zh)),
          _section(context, L10n.t('commonMistakes'), ex.mistakes(zh)),
          _section(context, L10n.t('progression'), [ex.prog(zh)]),
          _section(context, L10n.t('regression'), [ex.reg(zh)]),
          SizedBox(height: 8),
          Text(
            '${ex.defSets} × ${ex.defReps} · ${L10n.t('rest')} ${ex.defRest}${L10n.t('seconds')}',
            style: Iron.caption(color: Iron.faint),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<String> lines) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Iron.body(15, color: Iron.accent,
                  weight: FontWeight.w600)),
          SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: Iron.body(13, color: Iron.sub)),
            ),
        ],
      ),
    );
  }
}
