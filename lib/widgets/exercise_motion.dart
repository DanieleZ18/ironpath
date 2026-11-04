import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme.dart';

// Exercise demos as native vector skeletal animation — the same idea as
// SVG / Lottie keyframes, but drawn and driven in code: a rounded figure
// whose poses are authored by where the hips, hands and feet go; a
// two-bone solver works out knees and elbows. Motions live in
// lib/data/exercise_motions.dart; this file is the rig and the painter.
//
// Units: a 100 × 100 design box, ground at y = 92, figure facing right in
// side view. The painter fits whatever a motion needs into the stage.

const double ground = 92;
const double ankleY = 90;
const double torsoLen = 26;
const double neckLen = 4;
const double headR = 6.5;
const double upperArm = 14;
const double foreArm = 14;
const double thighLen = 20;
const double shinLen = 19;
const double footLen = 6.5;
const double standHipY = ankleY - thighLen - shinLen; // 51

double _rad(double d) => d * math.pi / 180;

/// Unit vector for an angle in degrees: 0 = up, 90 = forward (right),
/// 180 = down, -90 = backward.
Offset dirOf(double deg) => Offset(math.sin(_rad(deg)), -math.cos(_rad(deg)));

/// The angle (same convention) pointing from [a] to [b].
double angleTo(Offset a, Offset b) {
  final d = b - a;
  return math.atan2(d.dx, -d.dy) * 180 / math.pi;
}

Offset shoulderOf(Offset hip, double torso, [double shrug = 0]) =>
    hip + dirOf(torso) * (torsoLen + shrug);

/// The chest-facing normal of a torso at [torso] degrees.
Offset frontOf(double torso) => dirOf(torso + 90);

double lerpD(double a, double b, double t) => a + (b - a) * t;
Offset lerpO(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

/// One frame of a motion: where the body is and where its ends reach.
class Pose {
  final Offset hip;
  final double torso; // degrees, 0 = upright, + leans toward facing side
  final double torsoScale; // front-view foreshortening (bent toward camera)
  // foreshortening of limbs aimed at the camera (front / top views)
  final double thighScale, shinScale, armScale;
  final double shrug; // shoulder elevation
  final double head; // extra head tilt, degrees
  final Offset footN, footF; // ankle targets: near / far (front: right / left)
  final Offset handN, handF; // wrist targets
  final Offset kneeN, kneeF; // preferred side for each knee to bend toward
  final Offset elbowN, elbowF;
  final double toeN, toeF; // foot direction, degrees (90 = flat forward)

  const Pose({
    required this.hip,
    this.torso = 0,
    this.torsoScale = 1,
    this.thighScale = 1,
    this.shinScale = 1,
    this.armScale = 1,
    this.shrug = 0,
    this.head = 0,
    required this.footN,
    required this.footF,
    required this.handN,
    required this.handF,
    this.kneeN = const Offset(1, 0),
    this.kneeF = const Offset(1, 0),
    this.elbowN = const Offset(-0.4, 1),
    this.elbowF = const Offset(-0.4, 1),
    this.toeN = 90,
    this.toeF = 90,
  });

  Offset get shoulder => hip + dirOf(torso) * ((torsoLen + shrug) * torsoScale);
  Offset get front => frontOf(torso);
  Offset get axis => dirOf(torso);

  Pose copyWith({
    Offset? hip,
    double? torso,
    double? torsoScale,
    double? thighScale,
    double? shinScale,
    double? armScale,
    double? shrug,
    double? head,
    Offset? footN,
    Offset? footF,
    Offset? handN,
    Offset? handF,
    Offset? kneeN,
    Offset? kneeF,
    Offset? elbowN,
    Offset? elbowF,
    double? toeN,
    double? toeF,
  }) =>
      Pose(
        hip: hip ?? this.hip,
        torso: torso ?? this.torso,
        torsoScale: torsoScale ?? this.torsoScale,
        thighScale: thighScale ?? this.thighScale,
        shinScale: shinScale ?? this.shinScale,
        armScale: armScale ?? this.armScale,
        shrug: shrug ?? this.shrug,
        head: head ?? this.head,
        footN: footN ?? this.footN,
        footF: footF ?? this.footF,
        handN: handN ?? this.handN,
        handF: handF ?? this.handF,
        kneeN: kneeN ?? this.kneeN,
        kneeF: kneeF ?? this.kneeF,
        elbowN: elbowN ?? this.elbowN,
        elbowF: elbowF ?? this.elbowF,
        toeN: toeN ?? this.toeN,
        toeF: toeF ?? this.toeF,
      );

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        hip: lerpO(a.hip, b.hip, t),
        torso: lerpD(a.torso, b.torso, t),
        torsoScale: lerpD(a.torsoScale, b.torsoScale, t),
        thighScale: lerpD(a.thighScale, b.thighScale, t),
        shinScale: lerpD(a.shinScale, b.shinScale, t),
        armScale: lerpD(a.armScale, b.armScale, t),
        shrug: lerpD(a.shrug, b.shrug, t),
        head: lerpD(a.head, b.head, t),
        footN: lerpO(a.footN, b.footN, t),
        footF: lerpO(a.footF, b.footF, t),
        handN: lerpO(a.handN, b.handN, t),
        handF: lerpO(a.handF, b.handF, t),
        kneeN: lerpO(a.kneeN, b.kneeN, t),
        kneeF: lerpO(a.kneeF, b.kneeF, t),
        elbowN: lerpO(a.elbowN, b.elbowN, t),
        elbowF: lerpO(a.elbowF, b.elbowF, t),
        toeN: lerpD(a.toeN, b.toeN, t),
        toeF: lerpD(a.toeF, b.toeF, t),
      );
}

/// Two-bone IK: the middle joint for a limb from [root] reaching [target],
/// on the side [pref] points to. Returns (joint, end) — the end is the
/// target, or as far toward it as the limb reaches.
(Offset, Offset) solveLimb(
    Offset root, Offset target, double l1, double l2, Offset pref) {
  final d = target - root;
  final len = d.distance;
  final dir = len < 1e-6 ? const Offset(0, 1) : d / len;
  final dist = len.clamp((l1 - l2).abs() + 0.01, l1 + l2 - 0.01);
  final cosA =
      ((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)).clamp(-1.0, 1.0);
  final a = math.acos(cosA);
  Offset rot(Offset v, double ang) => Offset(
      v.dx * math.cos(ang) - v.dy * math.sin(ang),
      v.dx * math.sin(ang) + v.dy * math.cos(ang));
  final j1 = root + rot(dir, a) * l1;
  final j2 = root + rot(dir, -a) * l1;
  final mid = root + dir * (dist / 2);
  double score(Offset j) => (j - mid).dx * pref.dx + (j - mid).dy * pref.dy;
  final joint = score(j1) >= score(j2) ? j1 : j2;
  return (joint, root + dir * dist);
}

/// A solved pose: every joint in design-box coordinates.
class Rig {
  final bool frontView;
  final Offset hip, shoulder, head, axis, front;
  final Offset hipN, hipF, shN, shF;
  final Offset kneeN, ankleN, toeN, kneeF, ankleF, toeF;
  final Offset elbowN, wristN, elbowF, wristF;

  Rig._({
    required this.frontView,
    required this.hip,
    required this.shoulder,
    required this.head,
    required this.axis,
    required this.front,
    required this.hipN,
    required this.hipF,
    required this.shN,
    required this.shF,
    required this.kneeN,
    required this.ankleN,
    required this.toeN,
    required this.kneeF,
    required this.ankleF,
    required this.toeF,
    required this.elbowN,
    required this.wristN,
    required this.elbowF,
    required this.wristF,
  });

  factory Rig.solve(Pose p, {bool frontView = false}) {
    final axis = p.axis;
    final front = p.front;
    final shoulder = p.shoulder;
    final head = shoulder +
        dirOf(p.torso + p.head) *
            ((neckLen + headR) * p.torsoScale.clamp(0.6, 1));
    // front view: limbs hang from shoulder and hip corners; the "front"
    // vector is the body's right side there
    final shN = frontView ? shoulder + front * 9 : shoulder;
    final shF = frontView ? shoulder - front * 9 : shoulder;
    final hipN = frontView ? p.hip + front * 5 : p.hip;
    final hipF = frontView ? p.hip - front * 5 : p.hip;
    final thigh = thighLen * p.thighScale;
    final shin = shinLen * p.shinScale;
    final (kneeN, ankleN) = solveLimb(hipN, p.footN, thigh, shin, p.kneeN);
    final (kneeF, ankleF) = solveLimb(hipF, p.footF, thigh, shin, p.kneeF);
    final up = upperArm * p.armScale;
    final fore = foreArm * p.armScale;
    final (elbowN, wristN) = solveLimb(shN, p.handN, up, fore, p.elbowN);
    final (elbowF, wristF) = solveLimb(shF, p.handF, up, fore, p.elbowF);
    // feet seen from the front point at the camera: draw them short
    final foot = frontView ? footLen * 0.6 : footLen;
    return Rig._(
      frontView: frontView,
      hip: p.hip,
      shoulder: shoulder,
      head: head,
      axis: axis,
      front: front,
      hipN: hipN,
      hipF: hipF,
      shN: shN,
      shF: shF,
      kneeN: kneeN,
      ankleN: ankleN,
      toeN: ankleN + dirOf(p.toeN) * foot,
      kneeF: kneeF,
      ankleF: ankleF,
      toeF: ankleF + dirOf(frontView ? -p.toeF : p.toeF) * foot,
      elbowN: elbowN,
      wristN: wristN,
      elbowF: elbowF,
      wristF: wristF,
    );
  }

  Iterable<Offset> get points => [
        hip,
        shoulder,
        head - const Offset(0, headR),
        head + const Offset(0, headR),
        head - const Offset(headR, 0),
        head + const Offset(headR, 0),
        kneeN,
        ankleN,
        toeN,
        kneeF,
        ankleF,
        toeF,
        elbowN,
        wristN,
        elbowF,
        wristF,
        shN,
        shF,
        hipN,
        hipF,
      ];
}

/// Colours a prop draws with, derived from the stage.
class PropInk {
  final Color light, mid, dark, stage;
  final double unit; // stroke scale (design units → pixels handled by canvas)
  const PropInk(
      {required this.light,
      required this.mid,
      required this.dark,
      required this.stage,
      this.unit = 1});

  Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Paint fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;
}

typedef RigPoint = Offset Function(Rig r);

/// Something in the scene that isn't the body. Back-layer props sit behind
/// the figure (benches, bars, cables); front-layer props in front of it
/// (what the near hand holds).
abstract class Prop {
  const Prop();
  bool get inFront => false;
  void paint(Canvas c, Rig r, PropInk ink);
  Iterable<Offset> extent(Rig r) => const [];
}

/// A thick rounded slab between two points: bench pads, seats, back rests,
/// sled plates, platforms, frames.
class Slab extends Prop {
  final RigPoint a, b;
  final double width;
  final bool dark;
  final bool front;
  const Slab(this.a, this.b,
      {this.width = 4.5, this.dark = false, this.front = false});

  @override
  bool get inFront => front;

  @override
  void paint(Canvas c, Rig r, PropInk ink) =>
      c.drawLine(a(r), b(r), ink.stroke(dark ? ink.dark : ink.mid, width));

  @override
  Iterable<Offset> extent(Rig r) => [a(r), b(r)];
}

/// A flat bench (pad + two legs to the ground). [a]–[b] is the pad's top.
class Bench extends Prop {
  final Offset a, b;
  const Bench(this.a, this.b);

  @override
  void paint(Canvas c, Rig r, PropInk ink) {
    final legs = ink.stroke(ink.light, 2.6);
    final y = math.max(a.dy, b.dy) + 2.5;
    c.drawLine(Offset(lerpD(a.dx, b.dx, 0.2), y),
        Offset(lerpD(a.dx, b.dx, 0.2), ground), legs);
    c.drawLine(Offset(lerpD(a.dx, b.dx, 0.8), y),
        Offset(lerpD(a.dx, b.dx, 0.8), ground), legs);
    c.drawLine(a + const Offset(0, 2.2), b + const Offset(0, 2.2),
        ink.stroke(ink.mid, 4.6));
  }

  @override
  Iterable<Offset> extent(Rig r) => [a, b, Offset(a.dx, ground)];
}

/// A box / step to stand on.
class Box extends Prop {
  final Rect rect;
  const Box(this.rect);

  @override
  void paint(Canvas c, Rig r, PropInk ink) => c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
      ink.fill(ink.light));

  @override
  Iterable<Offset> extent(Rig r) => [rect.topLeft, rect.bottomRight];
}

/// A bar seen end-on or along its length: pull-up bar, dip bars, a table
/// edge. [posts] drops supports to the ground.
class Bar extends Prop {
  final Offset a, b;
  final bool posts;
  const Bar(this.a, this.b, {this.posts = true});

  @override
  void paint(Canvas c, Rig r, PropInk ink) {
    if (posts) {
      final p = ink.stroke(ink.light, 2.4);
      c.drawLine(a, Offset(a.dx, ground), p);
      c.drawLine(b, Offset(b.dx, ground), p);
    }
    c.drawLine(a, b, ink.stroke(ink.dark, 2.8));
  }

  @override
  Iterable<Offset> extent(Rig r) => [a, b];
}

/// A wall to lean on.
class Wall extends Prop {
  final double x;
  final double top;
  const Wall(this.x, {this.top = 14});

  @override
  void paint(Canvas c, Rig r, PropInk ink) => c.drawRRect(
      RRect.fromLTRBR(x - 6, top, x, ground, const Radius.circular(2)),
      ink.fill(ink.light));

  @override
  Iterable<Offset> extent(Rig r) => [Offset(x - 6, top), Offset(x, ground)];
}

/// A cable from a pulley [anchor] to the hands (or near hand only).
class Cable extends Prop {
  final Offset anchor;
  final bool bothHands;
  final bool rope; // short rope ends at the hands
  final bool far; // runs to the far hand only
  final bool ankle; // an ankle cuff on the near leg
  const Cable(this.anchor,
      {this.bothHands = true,
      this.rope = false,
      this.far = false,
      this.ankle = false});

  @override
  void paint(Canvas c, Rig r, PropInk ink) {
    final line = ink.stroke(ink.dark, 1.2);
    final grip = ankle
        ? r.ankleN
        : far
            ? r.wristF
            : bothHands
                ? (r.wristN + r.wristF) / 2
                : r.wristN;
    if (ankle) c.drawCircle(grip, 3.2, ink.stroke(ink.dark, 1.6));
    c.drawLine(anchor, grip, line);
    c.drawCircle(anchor, 3, ink.fill(ink.mid));
    if (rope) {
      final rp = ink.stroke(ink.dark, 1.8);
      c.drawLine(grip, r.wristN, rp);
      c.drawLine(grip, r.wristF, rp);
    }
  }

  @override
  Iterable<Offset> extent(Rig r) => [anchor];
}

enum DumbbellStyle {
  end, // handle pointing at the camera: a disc
  along, // handle along the body's facing direction
  vertical, // held upright (goblet, hammer)
}

/// Dumbbells at the wrists. The near one is drawn in front of the body,
/// the far one behind.
class Dumbbells extends Prop {
  final DumbbellStyle style;
  final bool near, far;
  final bool front;
  const Dumbbells(this.style,
      {this.near = true, this.far = true, this.front = true});

  @override
  bool get inFront => front;

  void _one(Canvas c, Offset at, Offset forward, PropInk ink, bool behind) {
    final body = behind ? ink.mid : ink.dark;
    switch (style) {
      case DumbbellStyle.end:
        c.drawCircle(at, 4.6, ink.fill(body));
        c.drawCircle(at, 1.6, ink.fill(ink.light));
      case DumbbellStyle.along:
      case DumbbellStyle.vertical:
        final d =
            style == DumbbellStyle.vertical ? const Offset(0, 1) : forward;
        final n = Offset(-d.dy, d.dx);
        c.drawLine(at - d * 4, at + d * 4, ink.stroke(body, 1.6));
        for (final end in [at - d * 5, at + d * 5]) {
          c.drawLine(end - n * 3.4, end + n * 3.4, ink.stroke(body, 3.4));
        }
    }
  }

  @override
  void paint(Canvas c, Rig r, PropInk ink) {
    final fwd = r.frontView ? const Offset(1, 0) : const Offset(1, 0);
    if (far) _one(c, r.wristF, fwd, ink, true);
    if (near) _one(c, r.wristN, fwd, ink, false);
  }

  @override
  Iterable<Offset> extent(Rig r) => [
        r.wristN + const Offset(6, 6),
        r.wristN - const Offset(6, 6),
        r.wristF + const Offset(6, 6),
        r.wristF - const Offset(6, 6),
      ];
}

enum PlateAt { hands, shoulders, frontRack, hip }

/// A barbell seen from the side: the near plate, with the bar's end.
class Plate extends Prop {
  final PlateAt at;
  const Plate(this.at);

  @override
  bool get inFront => true;

  Offset centre(Rig r) => switch (at) {
        PlateAt.hands => (r.wristN + r.wristF) / 2,
        PlateAt.shoulders => r.shoulder - r.front * 4.5 + r.axis * 0.5,
        PlateAt.frontRack => r.shoulder + r.front * 4.5 + r.axis * 1,
        PlateAt.hip => r.hip + r.front * 6.5,
      };

  @override
  void paint(Canvas c, Rig r, PropInk ink) {
    final o = centre(r);
    c.drawCircle(o, 10, ink.fill(ink.dark.withValues(alpha: 0.92)));
    c.drawCircle(o, 6.2, ink.stroke(ink.mid, 1.2));
    c.drawCircle(o, 2, ink.fill(ink.light));
  }

  @override
  Iterable<Offset> extent(Rig r) {
    final o = centre(r);
    return [o - const Offset(10, 10), o + const Offset(10, 10)];
  }
}

/// A barbell seen from the front: the bar across the hands with a plate
/// at each end.
class FrontBarbell extends Prop {
  final double halfWidth;
  const FrontBarbell({this.halfWidth = 40});

  @override
  bool get inFront => true;

  @override
  void paint(Canvas c, Rig r, PropInk ink) {
    final o = (r.wristN + r.wristF) / 2;
    c.drawLine(Offset(o.dx - halfWidth, o.dy), Offset(o.dx + halfWidth, o.dy),
        ink.stroke(ink.dark, 2.2));
    for (final x in [o.dx - halfWidth + 3, o.dx + halfWidth - 3]) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, o.dy), width: 5, height: 16),
              const Radius.circular(2)),
          ink.fill(ink.dark.withValues(alpha: 0.92)));
    }
  }

  @override
  Iterable<Offset> extent(Rig r) {
    final o = (r.wristN + r.wristF) / 2;
    return [o - Offset(halfWidth, 8), o + Offset(halfWidth, 8)];
  }
}

/// A round machine pad (leg extension / curl rollers, ankle anchors).
class Roller extends Prop {
  final RigPoint at;
  final double radius;
  final bool front;
  const Roller(this.at, {this.radius = 3.6, this.front = true});

  @override
  bool get inFront => front;

  @override
  void paint(Canvas c, Rig r, PropInk ink) =>
      c.drawCircle(at(r), radius, ink.fill(ink.mid));

  @override
  Iterable<Offset> extent(Rig r) => [at(r)];
}

/// Which highlight a body part takes.
enum Part {
  chest,
  back,
  traps,
  shoulders,
  arms,
  core,
  lowerBack,
  glutes,
  thighs,
  hamstrings,
  adductors,
  abductors,
  forearms,
  calves
}

Set<Part> partsFor(String muscle) => switch (muscle) {
      'chest' => {Part.chest},
      'back' => {Part.back},
      'traps' => {Part.traps},
      'shoulders' => {Part.shoulders},
      'biceps' || 'triceps' => {Part.arms},
      'core' => {Part.core},
      'lower_back' => {Part.lowerBack},
      'glutes' => {Part.glutes},
      'quads' => {Part.thighs},
      'hamstrings' => {Part.hamstrings},
      'adductors' => {Part.adductors},
      'abductors' => {Part.abductors},
      'forearms' => {Part.forearms},
      'calves' => {Part.calves},
      'full_body' || 'cardio' => {
          Part.thighs,
          Part.hamstrings,
          Part.calves,
          Part.core,
          Part.arms,
          Part.shoulders,
          Part.glutes,
          Part.chest,
        },
      _ => {},
    };

/// One exercise's demo: a pose for every moment of a looping cycle.
class MotionSpec {
  final Pose Function(double t) pose; // t in [0, 1)
  final Duration period;
  final bool frontView;
  final List<Prop> props;
  final bool showGround;

  /// The moment shown when motion is reduced (a representative mid pose).
  final double stillAt;

  MotionSpec(
    this.pose, {
    this.period = const Duration(milliseconds: 2800),
    this.frontView = false,
    this.props = const [],
    this.showGround = true,
    this.stillAt = 0.5,
  });

  Rig rigAt(double t) => Rig.solve(pose(t), frontView: frontView);

  Rect? _bounds;

  /// Everything the motion touches over a cycle, for fitting the stage.
  Rect get bounds => _bounds ??= () {
        var r = Rect.fromLTRB(1e9, 1e9, -1e9, -1e9);
        void add(Offset o) => r = Rect.fromLTRB(
            math.min(r.left, o.dx),
            math.min(r.top, o.dy),
            math.max(r.right, o.dx),
            math.max(r.bottom, o.dy));
        for (var i = 0; i < 24; i++) {
          final rig = rigAt(i / 24);
          rig.points.forEach(add);
          for (final p in props) {
            p.extent(rig).forEach(add);
          }
        }
        if (showGround) add(const Offset(50, ground));
        return r.inflate(7);
      }();
}

// ---- timing helpers motions compose ----------------------------------------

/// 0 → 1 → 0 with holds: rest at the start, move, hold, return.
double pingpong(double t,
    {double rest = 0.12, double go = 0.38, double hold = 0.1}) {
  if (t < rest) return 0;
  if (t < rest + go) return Curves.easeInOutCubic.transform((t - rest) / go);
  if (t < rest + go + hold) return 1;
  final back = 1 - rest - go - hold;
  return 1 -
      Curves.easeInOutCubic
          .transform(((t - rest - go - hold) / back).clamp(0.0, 1.0));
}

/// Smooth 0 → 1 → 0 over a cycle.
double wave(double t) => 0.5 - 0.5 * math.cos(2 * math.pi * t);

/// -1 … 1 alternation over a cycle (for left/right moves).
double swing(double t) => math.sin(2 * math.pi * t);

/// Pose sequence: keyframes at times (0..1, ascending), eased between.
Pose keyframes(List<(double, Pose)> keys, double t) {
  for (var i = 0; i < keys.length - 1; i++) {
    final (t0, p0) = keys[i];
    final (t1, p1) = keys[i + 1];
    if (t <= t1) {
      final u = t1 == t0 ? 1.0 : ((t - t0) / (t1 - t0)).clamp(0.0, 1.0);
      return Pose.lerp(p0, p1, Curves.easeInOutCubic.transform(u));
    }
  }
  return keys.last.$2;
}

// ---- painting -----------------------------------------------------------------

class _FigurePainter extends CustomPainter {
  final MotionSpec spec;
  final Animation<double>? anim;
  final double still;
  final Color hue;
  final Color stage;
  final Color neutral;
  final Color ink;
  final Set<Part> strong;
  final Set<Part> soft;

  _FigurePainter({
    required this.spec,
    required this.anim,
    required this.still,
    required this.hue,
    required this.stage,
    required this.neutral,
    required this.ink,
    required this.strong,
    required this.soft,
  }) : super(repaint: anim);

  Color _tone(Part p, {bool far = false}) {
    final c = strong.contains(p)
        ? hue
        : soft.contains(p)
            ? Color.lerp(neutral, hue, 0.5)!
            : neutral;
    return far ? Color.lerp(c, stage, 0.38)! : c;
  }

  Paint _limb(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  bool _lit(Part p) => strong.contains(p) || soft.contains(p);

  void _arm(Canvas c, Offset sh, Offset el, Offset wr, bool far) {
    final up = _tone(Part.arms, far: far);
    final fore = _lit(Part.forearms)
        ? _tone(Part.forearms, far: far)
        : far
            ? Color.lerp(neutral, stage, 0.38)!
            : (strong.contains(Part.arms)
                ? Color.lerp(neutral, hue, 0.45)!
                : neutral);
    c.drawLine(el, wr, _limb(fore, 4.8));
    c.drawLine(sh, el, _limb(up, 6));
    c.drawCircle(wr, 2.7, Paint()..color = fore);
  }

  /// [inward] points from this leg toward the body's midline (front view)
  /// or into the page (side view: null), for the inner-thigh overlay.
  void _leg(Canvas c, Offset hip, Offset kn, Offset an, Offset toe, bool far,
      {Offset? inward, Offset? back}) {
    final th = _tone(Part.thighs, far: far);
    final sh = _tone(Part.calves, far: far);
    final foot = far ? Color.lerp(neutral, stage, 0.38)! : neutral;
    c.drawLine(an, toe, _limb(foot, 4.2));
    c.drawLine(kn, an, _limb(sh, 6.6));
    c.drawLine(hip, kn, _limb(th, 8.4));
    final d = kn - hip;
    if (d.distance < 1e-3) return;
    final n = Offset(-d.dy, d.dx) / d.distance;
    // hamstrings: the back of the thigh — the side the shin bends away from
    if (_lit(Part.hamstrings)) {
      final shin = an - kn;
      var side = (n.dx * shin.dx + n.dy * shin.dy) < 0 ? n : -n;
      if (shin.distance > 1e-3 &&
          (n.dx * shin.dx + n.dy * shin.dy).abs() < 0.15 * shin.distance &&
          back != null) {
        side = (n.dx * back.dx + n.dy * back.dy) > 0 ? n : -n;
      }
      c.drawLine(hip + side * 2.4 + d * 0.12, kn + side * 2.4 - d * 0.12,
          _limb(_tone(Part.hamstrings, far: far), 3.8));
    }
    // adductors: the inner thigh
    if (_lit(Part.adductors)) {
      final side = inward == null
          ? Offset.zero
          : ((n.dx * inward.dx + n.dy * inward.dy) > 0 ? n : -n) * 2.6;
      c.drawLine(hip + side + d * 0.15, kn + side - d * 0.2,
          _limb(_tone(Part.adductors, far: far), inward == null ? 3.4 : 3));
    }
    // abductors: the outer hip, above the thigh's root
    if (_lit(Part.abductors)) {
      final out = inward == null ? -n * 0.6 : -inward;
      c.drawCircle(hip + out * 2.6 - d * 0.02, 3.6,
          Paint()..color = _tone(Part.abductors, far: far));
    }
  }

  void _torsoSide(Canvas c, Rig r) {
    final mid = lerpO(r.hip, r.shoulder, 0.5);
    final f = r.front;
    // glutes sit behind the hip
    c.drawCircle(r.hip - f * 3.6 + r.axis * -0.6, 5.6,
        Paint()..color = _tone(Part.glutes));
    c.drawLine(r.hip, mid, _limb(neutral, 11));
    c.drawLine(mid, r.shoulder, _limb(neutral, 12.5));
    void overlay(Part p, Offset a, Offset b, double w) {
      if (!strong.contains(p) && !soft.contains(p)) return;
      c.drawLine(a, b, _limb(_tone(p), w));
    }

    overlay(Part.chest, mid + f * 3.2, r.shoulder + f * 2.8, 5.6);
    overlay(Part.back, mid - f * 3.2, r.shoulder - f * 2.8, 5.6);
    overlay(Part.core, r.hip + f * 2.6 + r.axis * 2, mid + f * 2.8, 5);
    overlay(Part.lowerBack, r.hip - f * 2.6 + r.axis * 2, mid - f * 2.8, 5);
    overlay(Part.traps, r.shoulder - f * 2.2, r.shoulder + r.axis * 3 - f * 0.5,
        4.2);
    if (strong.contains(Part.shoulders) || soft.contains(Part.shoulders)) {
      c.drawCircle(r.shoulder, 4.4, Paint()..color = _tone(Part.shoulders));
    }
  }

  void _torsoFront(Canvas c, Rig r) {
    final path = Path()
      ..moveTo(r.hipF.dx, r.hipF.dy)
      ..lineTo(r.hipN.dx, r.hipN.dy)
      ..lineTo(r.shN.dx, r.shN.dy)
      ..lineTo(r.shF.dx, r.shF.dy)
      ..close();
    c.drawPath(path, Paint()..color = neutral);
    c.drawPath(path, _limb(neutral, 5));
    final mid = lerpO(r.hip, r.shoulder, 0.5);
    final up = r.axis;
    final side = r.front;
    if (strong.contains(Part.chest) ||
        soft.contains(Part.chest) ||
        strong.contains(Part.back) ||
        soft.contains(Part.back)) {
      final p = strong.contains(Part.chest) || strong.contains(Part.back)
          ? (strong.contains(Part.chest) ? Part.chest : Part.back)
          : (soft.contains(Part.chest) ? Part.chest : Part.back);
      final col = _tone(p);
      c.drawCircle(r.shoulder - up * 5 + side * 4, 4.2, Paint()..color = col);
      c.drawCircle(r.shoulder - up * 5 - side * 4, 4.2, Paint()..color = col);
    }
    if (strong.contains(Part.core) || soft.contains(Part.core)) {
      c.drawLine(r.hip + up * 2, mid, _limb(_tone(Part.core), 6));
    }
    for (final s in [r.shN, r.shF]) {
      if (strong.contains(Part.shoulders) || soft.contains(Part.shoulders)) {
        c.drawCircle(s, 4.6, Paint()..color = _tone(Part.shoulders));
      }
    }
    if (strong.contains(Part.glutes) || soft.contains(Part.glutes)) {
      for (final s in [r.hipN + side * 2.5, r.hipF - side * 2.5]) {
        c.drawCircle(s, 4.2, Paint()..color = _tone(Part.glutes));
      }
    }
    if (strong.contains(Part.traps) || soft.contains(Part.traps)) {
      c.drawLine(r.shN, r.shoulder + up * 3, _limb(_tone(Part.traps), 3.6));
      c.drawLine(r.shF, r.shoulder + up * 3, _limb(_tone(Part.traps), 3.6));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim?.value ?? still;
    final rig = spec.rigAt(t);
    final b = spec.bounds;
    final s = math.min(size.width / b.width, size.height / b.height);
    canvas.save();
    canvas.translate(
        (size.width - b.width * s) / 2, (size.height - b.height * s) / 2);
    canvas.scale(s);
    canvas.translate(-b.left, -b.top);

    final propInk = PropInk(
      light: Color.lerp(stage, ink, 0.16)!,
      mid: Color.lerp(stage, ink, 0.3)!,
      dark: Color.lerp(stage, ink, 0.52)!,
      stage: stage,
    );

    if (spec.showGround) {
      // a soft contact shadow under whatever touches the ground
      final lowest = [rig.ankleN, rig.ankleF, rig.toeN, rig.toeF]
          .map((o) => o.dy)
          .reduce(math.max);
      final lift = (ground - 2 - lowest).clamp(0.0, 20.0);
      final cx = (rig.ankleN.dx + rig.ankleF.dx + rig.hip.dx) / 3;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, ground), width: 34 - lift, height: 3.4),
          Paint()..color = Color.lerp(stage, ink, 0.1 - lift / 300)!);
      canvas.drawLine(Offset(b.left + 4, ground), Offset(b.right - 4, ground),
          _limb(Color.lerp(stage, ink, 0.14)!, 1.2));
    }

    for (final p in spec.props.where((p) => !p.inFront)) {
      p.paint(canvas, rig, propInk);
    }

    final front = rig.frontView;
    if (front) {
      _leg(canvas, rig.hipF, rig.kneeF, rig.ankleF, rig.toeF, false,
          inward: rig.front, back: null);
      _leg(canvas, rig.hipN, rig.kneeN, rig.ankleN, rig.toeN, false,
          inward: -rig.front, back: null);
      _torsoFront(canvas, rig);
      canvas.drawLine(rig.shoulder, rig.head, _limb(neutral, 4.4));
      canvas.drawCircle(rig.head, headR, Paint()..color = neutral);
      _arm(canvas, rig.shF, rig.elbowF, rig.wristF, false);
      _arm(canvas, rig.shN, rig.elbowN, rig.wristN, false);
    } else {
      _arm(canvas, rig.shF, rig.elbowF, rig.wristF, true);
      _leg(canvas, rig.hipF, rig.kneeF, rig.ankleF, rig.toeF, true,
          back: -rig.front);
      _torsoSide(canvas, rig);
      canvas.drawLine(rig.shoulder, rig.head, _limb(neutral, 4.4));
      canvas.drawCircle(rig.head, headR, Paint()..color = neutral);
      _leg(canvas, rig.hipN, rig.kneeN, rig.ankleN, rig.toeN, false,
          back: -rig.front);
      _arm(canvas, rig.shN, rig.elbowN, rig.wristN, false);
    }

    for (final p in spec.props.where((p) => p.inFront)) {
      p.paint(canvas, rig, propInk);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.spec != spec ||
      old.hue != hue ||
      old.stage != stage ||
      old.still != still ||
      old.anim != anim;
}

/// A demo of [spec] with the muscles from [muscles] lit in [color]: it
/// plays [repeats] reps, then eases into the key pose ([MotionSpec.stillAt])
/// and holds there — motion that shows the move, then settles. Under Reduce
/// Motion, or when [animate] is false, it shows the key pose only.
class ExerciseMotionView extends StatefulWidget {
  final MotionSpec spec;
  final List<String> muscles;
  final Color? color;
  final bool animate;
  final bool onTint; // stage sits on a tinted block: use the card surface

  /// Reps to play before settling; null loops for as long as it's shown.
  final int? repeats;

  /// Tapping the demo plays it again (only where a tap means nothing else).
  final bool replayOnTap;

  /// Show this fixed moment of the cycle (0..1) instead of playing —
  /// thumbnails and tests.
  final double? at;

  const ExerciseMotionView({
    super.key,
    required this.spec,
    required this.muscles,
    this.color,
    this.animate = true,
    this.onTint = false,
    this.repeats = 3,
    this.replayOnTap = false,
    this.at,
  });

  @override
  State<ExerciseMotionView> createState() => _ExerciseMotionViewState();
}

class _ExerciseMotionViewState extends State<ExerciseMotionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.spec.period);
  bool _played = false;
  int _run = 0; // bumps on every (re)start, so a stale settle never fires

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ExerciseMotionView old) {
    super.didUpdateWidget(old);
    if (old.spec != widget.spec) {
      _c.duration = widget.spec.period;
      _sync(restart: true);
    } else {
      _sync();
    }
  }

  bool get _running =>
      widget.at == null && widget.animate && !Motion.reduced(context);

  void _sync({bool restart = false}) {
    if (!_running) {
      _run++;
      _c.stop();
      _c.value = widget.spec.stillAt; // where it rests if motion returns
      return;
    }
    if (restart || !_played) _play();
  }

  void _play() {
    _played = true;
    final run = ++_run;
    _c.value = 0;
    final reps = widget.repeats;
    if (reps == null) {
      _c.repeat();
      return;
    }
    // completes only if the reps run out (a stop cancels it)
    _c.repeat(count: reps).then((_) {
      if (!mounted || run != _run) return;
      final still = widget.spec.stillAt;
      _c.animateTo(still, duration: widget.spec.period * still);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hue = widget.color ?? Iron.accent;
    final stage = widget.onTint ? Iron.card : Iron.tint(hue);
    final primary =
        widget.muscles.isEmpty ? <Part>{} : partsFor(widget.muscles.first);
    final secondary = {
      for (final m in widget.muscles.skip(1)) ...partsFor(m),
    }..removeAll(primary);
    final running = _running;
    Widget demo = RepaintBoundary(
      child: CustomPaint(
        painter: _FigurePainter(
          spec: widget.spec,
          anim: running ? _c : null,
          still: widget.at ?? widget.spec.stillAt,
          hue: Iron.inkOf(hue),
          stage: stage,
          neutral: Color.lerp(stage, Iron.faint, Iron.isDark ? 0.74 : 0.5)!,
          ink: Iron.ink,
          strong: primary,
          soft: secondary,
        ),
        child: const SizedBox.expand(),
      ),
    );
    if (widget.replayOnTap && running) {
      demo = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_c.isAnimating) _play();
        },
        child: demo,
      );
    }
    return demo;
  }
}
