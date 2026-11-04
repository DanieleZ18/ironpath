import 'package:flutter/material.dart';

import '../theme.dart';
import 'body_paint.dart';

/// A small anatomy chart: the body from the front or the back with every
/// muscle group drawn in, the trained ones lit. The primary muscle (first
/// in the list) decides the view and is drawn full strength; secondary
/// muscles visible from that side are lighter. Below [_zoomBelow] px the
/// figure zooms into the half of the body the primary muscle lives in, so
/// list-size glyphs stay legible. Same silhouette language as the exercise
/// demos (lib/widgets/body_paint.dart).

const _backView = {
  'back',
  'triceps',
  'glutes',
  'hamstrings',
  'lower_back',
  'calves',
  'traps',
  'abductors',
};
const _lowerBody = {
  'quads',
  'hamstrings',
  'adductors',
  'abductors',
  'glutes',
  'calves',
};
const _zoomBelow = 80.0;

/// Visible window of the 100×100 figure for a primary muscle.
Rect _viewFor(String primary, bool zoom) {
  if (!zoom ||
      primary == 'full_body' ||
      primary == 'cardio' ||
      primary.isEmpty) {
    return const Rect.fromLTWH(0, 0, 100, 100);
  }
  return _lowerBody.contains(primary)
      ? const Rect.fromLTWH(22, 50, 56, 56) // hips to feet
      : const Rect.fromLTWH(17, 0, 66, 66); // head to hips
}

class MuscleGlyph extends StatelessWidget {
  final List<String> muscles;
  final Color? color;
  final double size;
  final bool onTint; // sitting on a tinted block: use the card surface
  final Radius? radius; // concentric with the parent; default by size

  const MuscleGlyph(
      {super.key,
      required this.muscles,
      this.color,
      this.size = 44,
      this.onTint = false,
      this.radius});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: onTint ? Iron.card : Iron.tint(hue),
        shape: Iron.squircle(radius ?? Radius.circular(size * 0.36)),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: CustomPaint(
        painter: _BodyPainter(
          muscles: muscles,
          zoom: size < _zoomBelow,
          // deeper shade so the worked muscle pops even at list size
          hue: Iron.inkOf(hue),
          base: Color.lerp(onTint ? Iron.card : Iron.tint(hue), Iron.faint,
              Iron.isDark ? 0.3 : 0.2)!,
          stage: onTint ? Iron.card : Iron.tint(hue),
        ),
      ),
    );
  }
}

/// The muscle shapes of the chart.
enum _M {
  traps,
  delts,
  chest,
  latsFront,
  lats,
  abs,
  obliques,
  erectors,
  biceps,
  triceps,
  forearms,
  glutes,
  abductors,
  quads,
  adductors,
  hamstrings,
  calves,
}

Set<_M> _litFor(String muscle, bool back) => switch (muscle) {
      'chest' => back ? {} : {_M.chest},
      'back' => back ? {_M.lats} : {_M.latsFront},
      'shoulders' => {_M.delts},
      'traps' => {_M.traps},
      'biceps' => back ? {} : {_M.biceps},
      'triceps' => back ? {_M.triceps} : {},
      'forearms' => {_M.forearms},
      'core' => back ? {} : {_M.abs, _M.obliques},
      'lower_back' => back ? {_M.erectors} : {},
      'glutes' => back ? {_M.glutes} : {},
      'quads' => back ? {} : {_M.quads},
      'hamstrings' => back ? {_M.hamstrings} : {},
      'adductors' => {_M.adductors},
      'abductors' => {_M.abductors},
      'calves' => {_M.calves},
      'full_body' || 'cardio' => back
          ? {
              _M.delts,
              _M.triceps,
              _M.lats,
              _M.erectors,
              _M.glutes,
              _M.hamstrings,
              _M.calves,
            }
          : {_M.delts, _M.chest, _M.biceps, _M.abs, _M.quads, _M.calves},
      _ => {},
    };

/// One view of the chart in the 100 × 100 design box: the silhouette, and
/// every muscle's shapes (both sides of the body).
class _Chart {
  final List<Path> body;
  final Path head;
  final Path hair;
  final Map<_M, List<Path>> muscles;
  const _Chart(this.body, this.head, this.hair, this.muscles);
}

Offset _mx(Offset p) => Offset(100 - p.dx, p.dy);

_Chart _build(bool back) {
  final body = <Path>[];
  final m = <_M, List<Path>>{for (final k in _M.values) k: []};
  void add(_M k, Path p) => m[k]!.add(p);

  // ---- silhouette
  final head = ellipse(const Offset(50, 8.6), const Offset(0, 1), 7.2, 6.0);
  body.add(Segment(const Offset(50, 14.5), const Offset(50, 21),
      const Profile.even([2.9, 2.7, 2.8])).outline());
  // pelvis floor → hips → waist → chest → shoulders → neck base
  body.add(Segment(const Offset(50, 62), const Offset(50, 20),
          const Profile.even([4.6, 10.2, 8.6, 8.0, 8.5, 10.0, 11.4, 4.0]))
      .outline());
  for (final left in [true, false]) {
    Offset p(double x, double y) => left ? Offset(x, y) : _mx(Offset(x, y));
    final out = left ? const Offset(-1, 0) : const Offset(1, 0);
    final armDir = unit(p(33.2, 45.5) - p(37.0, 27.5));
    final delt = ellipse(p(38.2, 25.8), armDir, 5.6, 4.6);
    final upper = Segment(p(37.0, 27.5), p(33.2, 45.5),
        const Profile([3.6, 3.9, 3.6, 3.0, 2.6], [3.3, 3.6, 3.4, 2.9, 2.5]),
        aSide: out);
    final fore = Segment(p(33.2, 45.5), p(30.0, 62.0),
        const Profile([3.0, 3.3, 2.8, 2.2, 1.8], [2.8, 3.0, 2.6, 2.1, 1.8]),
        aSide: out);
    final hand = Segment(
        p(30.0, 61.5), p(29.2, 68.0), const Profile.even([1.9, 2.3, 2.1, 1.6]));
    final thigh = Segment(p(44.6, 59.5), p(44.0, 80.0),
        const Profile([5.6, 5.4, 4.9, 4.1, 3.4], [4.6, 4.8, 4.3, 3.6, 3.2]),
        aSide: out);
    final shin = Segment(p(44.0, 80.0), p(44.2, 95.0),
        const Profile([3.3, 3.7, 3.3, 2.5, 2.0], [3.4, 3.9, 3.4, 2.5, 2.0]),
        aSide: out);
    final foot = Segment(
        p(44.2, 95.0), p(41.8, 98.4), const Profile.even([2.0, 2.0, 1.6]));
    body.addAll([
      delt,
      upper.outline(),
      fore.outline(),
      hand.outline(),
      thigh.outline(),
      shin.outline(),
      foot.outline(),
    ]);

    // ---- muscles on both views
    add(_M.delts, ellipse(p(38.2, 26.4), armDir, 4.8, 3.8));
    add(_M.forearms, fore.region(onA: true, t0: 0.04, t1: 0.8, depth: 2));
    add(_M.adductors,
        thigh.region(onA: false, t0: 0.04, t1: back ? 0.5 : 0.68, depth: 0.9));
    add(
        _M.abductors,
        ellipse(
            p(back ? 40.6 : 39.2, back ? 56.2 : 58.6),
            unit(p(back ? 40.2 : 39.2, 60) - p(back ? 41.4 : 39.2, 53)),
            3.4,
            back ? 2.5 : 2.2));
    if (!back) {
      add(
          _M.chest,
          smoothClosed([
            p(49.6, 24.8),
            p(44.0, 24.0),
            p(39.8, 25.6),
            p(38.8, 29.0),
            p(41.4, 33.6),
            p(46.2, 34.6),
            p(49.6, 33.2),
          ]));
      add(_M.latsFront,
          ellipse(p(39.8, 36.2), unit(p(40.6, 41) - p(39.4, 31)), 5.2, 1.5));
      add(
          _M.traps,
          Segment(p(47.6, 19.8), p(41.6, 23.4),
              const Profile([1.6, 1.4, 0.9], [1.4, 1.2, 0.8])).outline());
      add(_M.obliques,
          ellipse(p(42.1, 45.6), unit(p(42.6, 54) - p(41.4, 37)), 8.0, 1.6));
      add(_M.biceps, upper.region(onA: true, t0: 0.15, t1: 0.88, depth: 1.7));
      add(_M.quads, thigh.region(onA: true, t0: 0.08, t1: 0.92, depth: 1.7));
      add(_M.calves, shin.region(onA: true, t0: 0.08, t1: 0.55, depth: 0.7));
      add(_M.calves, shin.region(onA: false, t0: 0.06, t1: 0.55, depth: 0.8));
      // six blocks of the abdominal wall
      final cx = left ? 47.0 : 53.0;
      for (final (top, bottom) in [(36.2, 41.4), (42.4, 47.4), (48.4, 54.4)]) {
        add(
            _M.abs,
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  Rect.fromLTRB(cx - 2.4, top, cx + 2.4, bottom),
                  const Radius.circular(1.6))));
      }
    } else {
      add(
          _M.lats,
          smoothClosed([
            p(48.8, 31.4),
            p(44.2, 27.6),
            p(40.2, 27.8),
            p(39.4, 33.0),
            p(41.4, 40.2),
            p(45.4, 46.2),
            p(48.8, 44.4),
          ]));
      add(
          _M.erectors,
          Segment(p(47.4, 43.8), p(47.4, 57.0),
              const Profile.even([1.2, 2.2, 2.4, 1.8])).outline());
      add(_M.triceps, upper.region(onA: true, t0: 0.1, t1: 0.88, depth: 1.75));
      add(_M.glutes,
          ellipse(p(45.3, 61.4), unit(p(45.8, 66) - p(44.8, 56)), 5.6, 4.8));
      add(_M.hamstrings,
          thigh.region(onA: true, t0: 0.12, t1: 0.9, depth: 1.85));
      // the calf's two heads
      add(_M.calves, shin.region(onA: true, t0: 0.04, t1: 0.58, depth: 0.95));
      add(_M.calves, shin.region(onA: false, t0: 0.04, t1: 0.64, depth: 0.95));
    }
  }
  if (back) {
    add(
        _M.traps,
        smoothClosed(const [
          Offset(50, 17.2),
          Offset(44.6, 21.0),
          Offset(40.2, 23.8),
          Offset(44.0, 26.6),
          Offset(47.6, 30.8),
          Offset(50, 37.8),
          Offset(52.4, 30.8),
          Offset(56.0, 26.6),
          Offset(59.8, 23.8),
          Offset(55.4, 21.0),
        ]));
  }
  // hair: the crown from the front, most of the head from behind
  final hair = back
      ? ellipse(const Offset(50, 6.4), const Offset(0, 1), 7.4, 6.6)
      : ellipse(const Offset(50, 3.6), const Offset(0, 1), 5.0, 6.6);
  return _Chart(body, head, hair, m);
}

final _front = _build(false);
final _back = _build(true);

/// The front and the back side by side, each muscle shaded by how many
/// working sets it got (Strava's muscle map, Fitbod's heat map): untouched
/// muscles stay a quiet shade, [full] sets or more light it fully.
class MuscleMap extends StatelessWidget {
  final Map<String, double> sets; // muscle key → working sets
  final double full;
  final Color? color;
  final double height;
  final bool onTint; // sitting on a tinted block: use the card surface

  const MuscleMap({
    super.key,
    required this.sets,
    this.full = 6,
    this.color,
    this.height = 120,
    this.onTint = false,
  });

  /// Width of the pair at [height]: two figures cropped to the body.
  static double widthFor(double height) =>
      height * (2 * _HeatPainter.span + _HeatPainter.gap) / 100;

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    final stage = onTint ? Iron.card : Iron.tint(hue);
    return SizedBox(
      width: widthFor(height),
      height: height,
      child: CustomPaint(
        painter: _HeatPainter(
          sets: sets,
          full: full,
          hue: Iron.inkOf(hue),
          base: Color.lerp(stage, Iron.faint, Iron.isDark ? 0.3 : 0.2)!,
          stage: stage,
        ),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  /// Each figure is cropped to x ∈ [left, left + span] of its 100 × 100 box.
  static const left = 23.0;
  static const span = 54.0;
  static const gap = 6.0;

  final Map<String, double> sets;
  final double full;
  final Color hue;
  final Color base;
  final Color stage;

  _HeatPainter({
    required this.sets,
    required this.full,
    required this.hue,
    required this.base,
    required this.stage,
  });

  Map<_M, double> _levels(bool back) {
    final out = <_M, double>{};
    for (final e in sets.entries) {
      if (e.value <= 0) continue;
      final level = (e.value / full).clamp(0.0, 1.0);
      for (final m in _litFor(e.key, back)) {
        if (level > (out[m] ?? 0)) out[m] = level;
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 100;
    final dark = stage.computeLuminance() < 0.4;
    Paint fill(Color c) => Paint()
      ..color = c
      ..isAntiAlias = true;
    final skin = fill(base);
    final quiet = Color.lerp(
        base, dark ? Colors.white : Colors.black, dark ? 0.07 : 0.05)!;
    final hair = fill(Color.lerp(base, dark ? stage : Colors.black, 0.18)!);
    for (final back in [false, true]) {
      final chart = back ? _back : _front;
      final levels = _levels(back);
      canvas.save();
      canvas.scale(s);
      canvas.translate((back ? span + gap : 0) - left, 0);
      canvas.clipRect(const Rect.fromLTWH(left, 0, span, 100));
      for (final p in [...chart.body, chart.head]) {
        canvas.drawPath(p, skin);
      }
      canvas.save();
      canvas.clipPath(chart.head);
      canvas.drawPath(chart.hair, hair);
      canvas.restore();
      for (final e in chart.muscles.entries) {
        final level = levels[e.key];
        // a muscle that got any work reads as lit; more sets, deeper
        final paint = fill(level == null
            ? quiet
            : Color.lerp(quiet, hue, 0.35 + 0.65 * level)!);
        for (final p in e.value) {
          canvas.drawPath(p, paint);
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.hue != hue ||
      old.base != base ||
      old.stage != stage ||
      old.full != full ||
      !_sameSets(old.sets, sets);

  static bool _sameSets(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

class _BodyPainter extends CustomPainter {
  final List<String> muscles;
  final Color hue;
  final Color base;
  final Color stage;
  final bool zoom;

  _BodyPainter({
    required this.muscles,
    required this.hue,
    required this.base,
    required this.stage,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primary = muscles.isEmpty ? '' : muscles.first;
    final back = _backView.contains(primary);
    final chart = back ? _back : _front;
    final strong = _litFor(primary, back);
    final soft = <_M>{
      for (final mm in muscles.skip(1)) ..._litFor(mm, back),
    }..removeAll(strong);

    // drawn in a 100×100 box; [view] is the window shown, fitted + centred
    final view = _viewFor(primary, zoom);
    final s = size.shortestSide / view.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
        (size.width - view.width * s) / 2, (size.height - view.height * s) / 2);
    canvas.scale(s);
    canvas.translate(-view.left, -view.top);

    final dark = stage.computeLuminance() < 0.4;
    Paint fill(Color c) => Paint()
      ..color = c
      ..isAntiAlias = true;
    final skin = fill(base);
    for (final p in [...chart.body, chart.head]) {
      canvas.drawPath(p, skin);
    }
    canvas.save();
    canvas.clipPath(chart.head);
    canvas.drawPath(
        chart.hair, fill(Color.lerp(base, dark ? stage : Colors.black, 0.18)!));
    canvas.restore();

    // every muscle drawn in, a shade off the skin; the trained ones lit
    final quiet = fill(Color.lerp(
        base, dark ? Colors.white : Colors.black, dark ? 0.07 : 0.05)!);
    final lit = fill(hue);
    final half = fill(Color.lerp(base, hue, 0.45)!);
    for (final e in chart.muscles.entries) {
      final paint = strong.contains(e.key)
          ? lit
          : soft.contains(e.key)
              ? half
              : quiet;
      for (final p in e.value) {
        canvas.drawPath(p, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.hue != hue ||
      old.base != base ||
      old.stage != stage ||
      old.zoom != zoom ||
      old.muscles != muscles;
}
