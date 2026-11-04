import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../data/exercise_motions.dart';
import '../widgets/bento.dart';
import '../widgets/exercise_motion.dart';
import '../widgets/ios_chrome.dart';
import 'exercise_detail_screen.dart';

/// The exercise library: every move, filtered by muscle and equipment,
/// as a two-column grid of tiles. Tap one for the demo and the how-to.

const muscleFilters = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'forearms',
  'core',
  'lower_back',
  'glutes',
  'quads',
  'hamstrings',
  'adductors',
  'abductors',
  'calves',
  'cardio',
];

const equipmentFilters = ['none', 'dumbbell', 'gym'];

class ExercisesScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const ExercisesScreen({super.key, this.scrollController});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _query = '';
  String? _muscle;
  String? _equipment;

  List<Exercise> get _matches {
    final q = _query.trim().toLowerCase();
    return Store.instance.exercises.where((e) {
      if (_muscle != null && !e.muscles.contains(_muscle)) return false;
      if (_equipment != null && e.requiredEquipment() != _equipment) {
        return false;
      }
      if (q.isEmpty) return true;
      return e.nameEn.toLowerCase().contains(q) ||
          e.nameZh.contains(q) ||
          e.muscles.any((m) => L10n.muscle(m).toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        largeTitleBar(L10n.t('tabExercises')),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: _search(context),
              ),
              _chips(
                [
                  (null, L10n.t('filterAll')),
                  for (final m in muscleFilters) (m, L10n.muscle(m)),
                ],
                _muscle,
                (v) => setState(() => _muscle = v),
              ),
              const SizedBox(height: 8),
              _chips(
                [
                  (null, L10n.t('filterAll')),
                  (
                    'none',
                    L10n.t('bodyweight'),
                  ),
                  ('dumbbell', L10n.t('equipDumbbell')),
                  ('gym', L10n.t('equipGym')),
                ],
                _equipment,
                (v) => setState(() => _equipment = v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                child: Text(L10n.tf('exercisesCount', matches.length),
                    style: Iron.caption(color: Iron.faint)),
              ),
            ],
          ),
        ),
        if (matches.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
              child: Text(L10n.t('noMatches'),
                  textAlign: TextAlign.center, style: Iron.caption()),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset(context)),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: bentoGap,
                crossAxisSpacing: bentoGap,
                // taller tiles when text is larger, so names never clip
                mainAxisExtent: 212 +
                    26 * (MediaQuery.textScalerOf(context).scale(10) - 10),
              ),
              itemCount: matches.length,
              itemBuilder: (context, i) => ExerciseTile(exercise: matches[i]),
            ),
          ),
      ],
    );
  }

  Widget _search(BuildContext context) => isApple(context)
      ? CupertinoSearchTextField(
          placeholder: L10n.t('search'),
          style: Iron.body(16, weight: FontWeight.w600),
          placeholderStyle: Iron.body(16, color: Iron.faint),
          backgroundColor: Iron.card,
          borderRadius: const BorderRadius.all(Iron.rS),
          onChanged: (v) => setState(() => _query = v),
        )
      : TextField(
          onChanged: (v) => setState(() => _query = v),
          style: Iron.body(15, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: L10n.t('search'),
            prefixIcon: Icon(Icons.search_rounded, color: Iron.sub),
          ),
        );

  /// One row of filter chips; the selected one is solid.
  Widget _chips(List<(String?, String)> options, String? value,
          ValueChanged<String?> onChanged) =>
      SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final (key, label) = options[i];
            final selected = key == value;
            return Semantics(
              button: true,
              selected: selected,
              child: IronPill(
                label,
                color: selected ? Iron.accent : null,
                solid: selected,
                onTap: () => onChanged(key),
              ),
            );
          },
        ),
      );
}

/// One exercise as a grid tile: the move itself in its key position (the
/// demo, held still, working muscles lit in the difficulty hue), then the
/// name and its muscles.
class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  const ExerciseTile({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final zh = L10n.zh;
    final hue = Iron.tier(e.difficulty);
    final spec = motionFor(e.id);
    final available = e.availableFor(Store.instance.settings.userEquipment);
    return BentoTile(
      padding: const EdgeInsets.all(8),
      onTap: () => showExerciseDetail(context, e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              decoration: ShapeDecoration(
                color: Iron.tint(hue),
                shape: Iron.squircle(Iron.inner(Iron.rL, 8)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: ExerciseMotionView(
                        spec: spec,
                        muscles: e.muscles,
                        color: hue,
                        at: spec.stillAt,
                      ),
                    ),
                  ),
                  if (!available)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.lock_outline_rounded,
                          size: 16, color: Iron.faint),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name(zh),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Iron.body(15, weight: FontWeight.w800)
                        .copyWith(height: 1.25)),
                const SizedBox(height: 2),
                Text(e.muscles.take(2).map(L10n.muscle).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Iron.caption(color: Iron.faint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
