import 'package:flutter/material.dart';

import '../theme.dart';

/// Tiny body figure with the trained muscles highlighted — the stand-in for
/// exercise illustrations. The primary muscle (first in the list) decides
/// front or back view and is drawn full strength; secondary muscles that
/// are visible from that side are drawn lighter. Below [_zoomBelow] px the
/// figure zooms into the half of the body the primary muscle lives in, so
/// list-size glyphs stay legible.

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

/// Regions visible per view. Shared regions (shoulders, arms, legs…) exist
/// in both; muscle keys map onto them below.
enum _R {
  head,
  traps,
  shoulders,
  chest,
  upperBack,
  core,
  lowerBack,
  upperArms,
  forearms,
  glutes,
  outerHips,
  thighs,
  innerThighs,
  calves,
}

Set<_R> _regionsFor(String muscle, bool back) => switch (muscle) {
      'chest' => back ? {} : {_R.chest},
      'back' => back ? {_R.upperBack} : {},
      'shoulders' => {_R.shoulders},
      'traps' => {_R.traps},
      'biceps' => back ? {} : {_R.upperArms},
      'triceps' => back ? {_R.upperArms} : {},
      'core' => back ? {} : {_R.core},
      'lower_back' => back ? {_R.lowerBack} : {},
      'glutes' => back ? {_R.glutes} : {},
      // the thigh block is the quads from the front, the hamstrings behind
      'quads' => back ? {} : {_R.thighs},
      'hamstrings' => back ? {_R.thighs} : {},
      'adductors' => back ? {} : {_R.innerThighs},
      'abductors' => {_R.outerHips},
      'forearms' => {_R.forearms},
      'calves' => {_R.calves},
      'full_body' || 'cardio' => {
          _R.shoulders,
          _R.upperArms,
          back ? _R.upperBack : _R.chest,
          back ? _R.lowerBack : _R.core,
          if (back) _R.glutes,
          _R.thighs,
          _R.calves,
        },
      _ => {},
    };

class MuscleGlyph extends StatelessWidget {
  final List<String> muscles;
  final Color? color;
  final double size;
  final bool onTint; // sitting on a tinted block: use the card surface

  const MuscleGlyph(
      {super.key,
      required this.muscles,
      this.color,
      this.size = 44,
      this.onTint = false});

  @override
  Widget build(BuildContext context) {
    final hue = color ?? Iron.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onTint ? Iron.card : Iron.tint(hue),
        borderRadius: BorderRadius.all(Radius.circular(size * 0.36)),
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
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final List<String> muscles;
  final Color hue;
  final Color base;
  final bool zoom;

  _BodyPainter(
      {required this.muscles,
      required this.hue,
      required this.base,
      required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final primary = muscles.isEmpty ? '' : muscles.first;
    final back = _backView.contains(primary);
    final strong = _regionsFor(primary, back);
    final soft = <_R>{
      for (final m in muscles.skip(1)) ..._regionsFor(m, back),
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

    Paint paintFor(_R r) => Paint()
      ..isAntiAlias = true
      ..color = strong.contains(r)
          ? hue
          : soft.contains(r)
              ? Color.lerp(base, hue, 0.45)!
              : base;

    void rr(_R r, double l, double t, double w, double h, double radius) =>
        canvas.drawRRect(
            RRect.fromLTRBR(l, t, l + w, t + h, Radius.circular(radius)),
            paintFor(r));

    // head + neck
    canvas.drawCircle(const Offset(50, 9), 7.5, paintFor(_R.head));
    rr(_R.head, 46.5, 15, 7, 5, 2);

    // traps: a soft cap between neck and shoulders
    final traps = Path()
      ..moveTo(39, 23)
      ..quadraticBezierTo(50, 15, 61, 23)
      ..lineTo(57, 25)
      ..lineTo(43, 25)
      ..close();
    canvas.drawPath(traps, paintFor(_R.traps));

    // shoulders (delts)
    canvas.drawCircle(const Offset(33.5, 26.5), 6.5, paintFor(_R.shoulders));
    canvas.drawCircle(const Offset(66.5, 26.5), 6.5, paintFor(_R.shoulders));

    // torso: chest + core (front) or upper + lower back (back)
    if (back) {
      final lats = Path()
        ..moveTo(39.5, 25.5)
        ..lineTo(60.5, 25.5)
        ..quadraticBezierTo(62, 36, 57, 44)
        ..lineTo(43, 44)
        ..quadraticBezierTo(38, 36, 39.5, 25.5)
        ..close();
      canvas.drawPath(lats, paintFor(_R.upperBack));
      rr(_R.lowerBack, 42.5, 45.5, 15, 9, 3);
    } else {
      rr(_R.chest, 39.5, 25.5, 10, 11, 4);
      rr(_R.chest, 50.5, 25.5, 10, 11, 4);
      rr(_R.core, 42, 38, 16, 17, 4);
    }

    // arms
    rr(_R.upperArms, 26, 33.5, 7, 15, 3.5);
    rr(_R.upperArms, 67, 33.5, 7, 15, 3.5);
    rr(_R.forearms, 24.5, 50, 6.5, 14, 3.25);
    rr(_R.forearms, 69, 50, 6.5, 14, 3.25);

    // hips / glutes
    if (back) {
      canvas.drawCircle(const Offset(45, 61), 6.5, paintFor(_R.glutes));
      canvas.drawCircle(const Offset(55, 61), 6.5, paintFor(_R.glutes));
    } else {
      rr(_R.head, 41.5, 56.5, 17, 7, 3); // pelvis, neutral
    }

    // hips: the abductors sit on the outer edge of the pelvis
    canvas.drawCircle(const Offset(38.5, 60), 3.6, paintFor(_R.outerHips));
    canvas.drawCircle(const Offset(61.5, 60), 3.6, paintFor(_R.outerHips));

    // legs
    rr(_R.thighs, 39.5, 66, 9.5, 17, 4.5);
    rr(_R.thighs, 51, 66, 9.5, 17, 4.5);
    if (!back) {
      rr(_R.innerThighs, 46.5, 67, 2.8, 14, 1.4);
      rr(_R.innerThighs, 50.7, 67, 2.8, 14, 1.4);
    }
    rr(_R.calves, 40.5, 84.5, 7.5, 14, 3.75);
    rr(_R.calves, 52, 84.5, 7.5, 14, 3.75);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.hue != hue ||
      old.base != base ||
      old.zoom != zoom ||
      old.muscles != muscles;
}
