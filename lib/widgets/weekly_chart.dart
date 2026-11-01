import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import '../utils.dart';
import 'bento.dart';

/// Workouts per week over the last few weeks, as a bento tile. One column
/// per week: the current week in the accent, earlier weeks in a quiet grey
/// (emphasis — the story is this week against the recent run), and a
/// hairline at the weekly goal. Tap a column to read its week; screen
/// readers get every value.
class WeeklyChartTile extends StatefulWidget {
  final List<int> counts; // oldest first; the last is this week
  final List<DateTime> weekStarts; // Monday of each counted week
  final int? goal; // planned sessions per week

  const WeeklyChartTile({
    super.key,
    required this.counts,
    required this.weekStarts,
    this.goal,
  }) : assert(counts.length == weekStarts.length);

  @override
  State<WeeklyChartTile> createState() => _WeeklyChartTileState();
}

class _WeeklyChartTileState extends State<WeeklyChartTile> {
  int? _selected;

  int get _last => widget.counts.length - 1;

  String _weekName(int i) => i == _last
      ? L10n.t('statThisWeek')
      : L10n.tf('weekOf', fmtMonthDay(widget.weekStarts[i]));

  String _sessions(int n) =>
      n == 1 ? L10n.t('sessionsOne') : L10n.tf('sessionsN', n);

  void _tap(Offset at, double width) {
    final i = (at.dx / (width / widget.counts.length))
        .floor()
        .clamp(0, widget.counts.length - 1);
    setState(() => _selected = (_selected == i || i == _last) ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.counts.length;
    final shown = _selected ?? _last;
    final scaler = MediaQuery.textScalerOf(context);
    final labelSize = scaler.scale(11);
    final goal = widget.goal;
    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(L10n.tf('lastNWeeks', n),
                    style: Iron.body(16, weight: FontWeight.w800)),
              ),
              if (goal != null && goal > 0) ...[
                // key for the goal hairline: the same short line, then text
                Container(width: 14, height: 1.5, color: _goalInk),
                const SizedBox(width: 6),
                Text(L10n.tf('weeklyGoal', goal),
                    style: Iron.caption(color: Iron.faint)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${_weekName(shown)} · ${_sessions(widget.counts[shown])}',
            style: Iron.caption(),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: L10n.tf('lastNWeeks', n),
            value: [
              for (var i = 0; i < n; i++)
                '${_weekName(i)}: ${_sessions(widget.counts[i])}'
            ].join('; '),
            child: Builder(
              builder: (box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _tap(d.localPosition, box.size!.width),
                child: SizedBox(
                  width: double.infinity,
                  // plot + room for the cap label + the x-axis band
                  height: 96 + 2 * (labelSize + 8),
                  child: CustomPaint(
                    painter: _ColumnsPainter(
                      counts: widget.counts,
                      labels: [
                        for (var i = 0; i < n; i++)
                          i == _last
                              ? L10n.t('statThisWeek')
                              : fmtMonthDay(widget.weekStarts[i]),
                      ],
                      goal: goal,
                      selected: _selected,
                      scaler: scaler,
                      accent: Iron.inkOf(Iron.accent),
                      quiet: Color.lerp(Iron.card, Iron.faint, 0.4)!,
                      lift: Color.lerp(Iron.card, Iron.faint, 0.85)!,
                      baseline: Iron.line,
                      goalInk: _goalInk,
                      ink: Iron.ink,
                      faint: Iron.faint,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _goalInk => Color.lerp(Iron.card, Iron.faint, 0.6)!;
}

class _ColumnsPainter extends CustomPainter {
  final List<int> counts;
  final List<String> labels;
  final int? goal;
  final int? selected;
  final TextScaler scaler;
  final Color accent, quiet, lift, baseline, goalInk, ink, faint;

  _ColumnsPainter({
    required this.counts,
    required this.labels,
    required this.goal,
    required this.selected,
    required this.scaler,
    required this.accent,
    required this.quiet,
    required this.lift,
    required this.baseline,
    required this.goalInk,
    required this.ink,
    required this.faint,
  });

  TextPainter _label(String text, Color color, {bool bold = false}) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: Iron.fontFamily,
            fontSize: 11,
            height: 1,
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = counts.length;
    final last = n - 1;
    final band = scaler.scale(11) + 8;
    final plotTop = band; // the cap label of the tallest column fits above
    final plotBottom = size.height - band;
    final plotH = plotBottom - plotTop;
    final top = math.max(1, math.max(counts.reduce(math.max), goal ?? 0));
    final slot = size.width / n;
    final barW = math.min(24.0, slot * 0.56);
    double yOf(num v) => plotBottom - v / top * plotH;

    // goal hairline first, so the columns sit in front of it
    if (goal != null && goal! > 0) {
      final y = yOf(goal!).roundToDouble() + 0.5;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = goalInk
            ..strokeWidth = 1);
    }

    // x labels: every week when they fit, else every other (always keeping
    // this week), else just the first and this week
    final painters = [
      for (var i = 0; i < n; i++)
        _label(labels[i], i == last ? ink : faint, bold: i == last)
    ];
    final widest = painters.map((p) => p.width).reduce(math.max);
    bool labelled(int i) {
      if (widest <= slot - 4) return true;
      if (widest <= 2 * slot - 4) return (last - i).isEven;
      return i == 0 || i == last;
    }

    for (var i = 0; i < n; i++) {
      final cx = slot * (i + 0.5);
      final v = counts[i];
      final y = yOf(v);
      if (v > 0) {
        final h = plotBottom - y;
        final r = Radius.circular(math.min(4.0, h / 2));
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(cx - barW / 2, y, barW, h),
              topLeft: r, topRight: r),
          Paint()
            ..color = i == last
                ? accent
                : i == selected
                    ? lift
                    : quiet,
        );
      }
      // the value rides the cap of this week's column and the tapped one
      if (i == last || i == selected) {
        final p = _label('$v', ink, bold: true);
        p.paint(canvas, Offset(cx - p.width / 2, y - 4 - p.height));
      }
      if (labelled(i)) {
        final p = painters[i];
        final x = (cx - p.width / 2).clamp(0.0, size.width - p.width);
        p.paint(canvas, Offset(x, plotBottom + 7));
      }
    }

    // baseline last: a crisp hairline under every column
    final b = plotBottom.roundToDouble() + 0.5;
    canvas.drawLine(
        Offset(0, b),
        Offset(size.width, b),
        Paint()
          ..color = baseline
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ColumnsPainter old) =>
      old.selected != selected ||
      old.goal != goal ||
      old.accent != accent ||
      old.quiet != quiet ||
      old.scaler != scaler ||
      !_same(old.counts, counts) ||
      !_same(old.labels, labels);

  static bool _same<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
