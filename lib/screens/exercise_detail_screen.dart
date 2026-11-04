import 'package:flutter/material.dart';

import '../data/exercise_motions.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../training_stats.dart';
import '../utils.dart';
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
                      // front and back, so muscles on either side show
                      // (glutes, hamstrings); the primary one is fullest
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            child: MuscleMap(
                              sets: {
                                for (var i = 0; i < ex.muscles.length; i++)
                                  ex.muscles[i]: i == 0 ? 2.0 : 1.2,
                              },
                              full: 2,
                              color: hue,
                              height: 110,
                              onTint: true,
                            ),
                          ),
                        ),
                      ),
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
              ..._records(ex, hue, zh),
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

  /// What you've done with this move, once you have: the best set, last
  /// time, how often, and the trend of your top set (Hevy's exercise page).
  List<Widget> _records(Exercise ex, Color hue, bool zh) {
    final logs = Store.instance.logs;
    final best = bestSet(logs, ex.id);
    if (best == null) return const [];
    final timed = isTimed(ex.id);
    final last = previousSets(logs, ex.id);
    SessionLog? lastLog;
    var times = 0;
    for (final l in logs) {
      if (l.items.any((i) => i.exerciseId == ex.id && i.doneCount > 0)) {
        lastLog ??= l;
        times++;
      }
    }
    SetLog? top;
    for (final s in last) {
      if (top == null ||
          (s.weight ?? -1) > (top.weight ?? -1) ||
          ((s.weight ?? -1) == (top.weight ?? -1) &&
              (s.reps ?? -1) > (top.reps ?? -1))) {
        top = s;
      }
    }
    final trend = trendFor(logs, ex.id);
    Widget fact(String label, String value, {String? note}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      Iron.caption(color: Iron.faint).copyWith(fontSize: 12)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Iron.body(16, weight: FontWeight.w800)),
              if (note != null)
                Text(note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Iron.caption(color: Iron.faint).copyWith(fontSize: 12)),
            ],
          ),
        );
    return [
      BentoTile(
        hue: hue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BentoLabel(L10n.t('yourRecords'),
                icon: Icons.insights_rounded, hue: hue),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fact(L10n.t('bestSet'), setLabel(best.set, timed: timed),
                    note: fmtDayHeader(best.at, zh)),
                fact(L10n.t('lastTimeLabel'),
                    top == null ? '—' : setLabel(top, timed: timed),
                    note: lastLog == null
                        ? null
                        : L10n.tf('setsDone', last.length)),
                fact(L10n.t('timesTrained'), L10n.tf('timesN', times)),
              ],
            ),
            if (trend.length >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: CustomPaint(
                  painter: _Sparkline(trend,
                      color: Iron.inkOf(hue), track: Iron.card),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
    ];
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

/// Your top set per session for this move, oldest to newest: a line that
/// should climb, the latest point marked.
class _Sparkline extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color track;

  _Sparkline(this.values, {required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    const pad = 6.0;
    Offset at(int i) => Offset(
          pad + (size.width - 2 * pad) * i / (values.length - 1),
          size.height -
              pad -
              (size.height - 2 * pad) *
                  (hi == lo ? 0.5 : (values[i] - lo) / span),
        );
    final base = Paint()
      ..color = track
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(size.width - pad, size.height - pad), base);
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    final end = at(values.length - 1);
    canvas.drawCircle(end, 5, Paint()..color = track);
    canvas.drawCircle(end, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Sparkline old) =>
      old.color != color || old.track != track || old.values != values;
}
