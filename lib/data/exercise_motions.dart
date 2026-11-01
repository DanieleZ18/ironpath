import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../widgets/exercise_motion.dart';

// Every exercise's demo, as parametric motion families. Each family is a
// pose function of d (0 = start position, 1 = end position) or of the
// cycle time t for continuous moves; exercises pick a family plus their
// grip, props and timing. Side view faces right; front view faces the
// camera (N = the figure's right, on screen right).

const _fN = Offset(53, ankleY);
const _fF = Offset(49, ankleY);
const _standHip = Offset(50, standHipY);

const _slow = Duration(milliseconds: 3200);
const _std = Duration(milliseconds: 2800);
const _quick = Duration(milliseconds: 1400);

Offset _polar(double deg) => Offset(math.cos(deg * math.pi / 180),
    -math.sin(deg * math.pi / 180)); // 0 = right, + = up

Pose _stand({double torso = 2, Offset? handN, Offset? handF}) {
  final sh = shoulderOf(_standHip, torso);
  return Pose(
    hip: _standHip,
    torso: torso,
    footN: _fN,
    footF: _fF,
    handN: handN ?? sh + const Offset(2, 27),
    handF: handF ?? sh + const Offset(-0.5, 27),
  );
}

// ---- squats ---------------------------------------------------------------

enum _Hold { reach, goblet, barbell, hang }

Pose _squat(double d, _Hold hold, {bool sumo = false}) {
  final hip = Offset(50 - (sumo ? 4 : 9) * d, standHipY + (sumo ? 19 : 21) * d);
  final torso = 4 + (sumo ? 16 : 34) * d;
  final sh = shoulderOf(hip, torso);
  final f = frontOf(torso), ax = dirOf(torso);
  var elbow = const Offset(-0.2, 1);
  final Offset hand;
  switch (hold) {
    case _Hold.reach:
      hand = sh + Offset(lerpD(2, 25, d), lerpD(27, 3, d));
    case _Hold.goblet:
      hand = sh + f * 6.5 - ax * 9;
      elbow = const Offset(0.5, 1);
    case _Hold.barbell:
      hand = sh - f * 3.5 + ax * 1.5;
      elbow = const Offset(-0.5, 1);
    case _Hold.hang:
      hand = hip + f * 3 + const Offset(0, 14);
  }
  return Pose(
    hip: hip,
    torso: torso,
    head: -torso * 0.5,
    footN: sumo ? const Offset(57, ankleY) : _fN,
    footF: sumo ? const Offset(45, ankleY) : _fF,
    handN: hand,
    handF: hand + const Offset(-2, 0),
    elbowN: elbow,
    elbowF: elbow,
  );
}

MotionSpec _squatSpec(_Hold hold,
        {bool sumo = false, List<Prop> props = const []}) =>
    MotionSpec((t) => _squat(pingpong(t), hold, sumo: sumo), props: props);

MotionSpec _jumpSquat() {
  final stand = _squat(0, _Hold.reach);
  final low = _squat(0.8, _Hold.reach);
  final lowArms = low.copyWith(
      handN: low.shoulder + const Offset(-12, 24),
      handF: low.shoulder + const Offset(-14, 24));
  final takeoffHip = _standHip - const Offset(0, 3);
  final takeoffSh = shoulderOf(takeoffHip, 2);
  final takeoff = stand.copyWith(
      hip: takeoffHip,
      torso: 2,
      head: 0,
      footN: _fN - const Offset(0, 3),
      footF: _fF - const Offset(0, 3),
      toeN: 150,
      toeF: 150,
      handN: takeoffSh + const Offset(6, -26),
      handF: takeoffSh + const Offset(4, -26));
  final airHip = _standHip - const Offset(0, 11);
  final airSh = shoulderOf(airHip, 2);
  final air = takeoff.copyWith(
      hip: airHip,
      footN: _fN - const Offset(0, 11),
      footF: _fF - const Offset(0, 11),
      toeN: 160,
      toeF: 160,
      handN: airSh + const Offset(6, -26),
      handF: airSh + const Offset(4, -26));
  final land = _squat(0.35, _Hold.reach);
  return MotionSpec(
    (t) => keyframes([
      (0, stand),
      (0.3, lowArms),
      (0.44, takeoff),
      (0.54, air),
      (0.7, land),
      (0.86, stand),
      (1, stand),
    ], t),
    period: const Duration(milliseconds: 1900),
    stillAt: 0.3,
  );
}

MotionSpec _wallSit() => MotionSpec(
      (t) {
        final b = 0.4 * swing(t);
        final hip = Offset(40, 70 + b);
        return Pose(
          hip: hip,
          footN: const Offset(60, ankleY),
          footF: const Offset(57, ankleY),
          handN: Offset(55, 66 + b),
          handF: Offset(53, 66 + b),
          elbowN: const Offset(0.2, 1),
          elbowF: const Offset(0.2, 1),
        );
      },
      period: _slow,
      props: const [Wall(33.5)],
      stillAt: 0,
    );

MotionSpec _pistol() => MotionSpec((t) {
      final d = pingpong(t);
      final hip = Offset(50 - 10 * d, standHipY + 24 * d);
      final torso = 8 + 32 * d;
      final sh = shoulderOf(hip, torso);
      final hand = sh + Offset(lerpD(8, 25, d), lerpD(22, 4, d));
      return Pose(
        hip: hip,
        torso: torso,
        head: -torso * 0.5,
        footN: _fN,
        footF: lerpO(hip + const Offset(10, 37), hip + const Offset(37, 4), d),
        kneeF: const Offset(0, -1),
        handN: hand,
        handF: hand + const Offset(-2, 0),
        elbowN: const Offset(-0.2, 1),
        toeF: lerpD(150, 70, d),
      );
    });

MotionSpec _hackSquat() => MotionSpec(
      (t) {
        final d = pingpong(t);
        final hip = const Offset(43, 52) + const Offset(0.31, 0.95) * (18 * d);
        const torso = -18.0;
        final sh = shoulderOf(hip, torso);
        final f = frontOf(torso), ax = dirOf(torso);
        return Pose(
          hip: hip,
          torso: torso,
          head: 10,
          footN: const Offset(63, 86),
          footF: const Offset(60, 86),
          handN: sh + f * 3 + ax * 1.5,
          handF: sh + f * 1.5 + ax * 1.5,
          elbowN: const Offset(0.4, 1),
          elbowF: const Offset(0.4, 1),
          toeN: 80,
          toeF: 80,
        );
      },
      props: [
        Slab((r) => r.hip - r.front * 7.5 - r.axis * 6,
            (r) => r.shoulder - r.front * 7.5 + r.axis * 9,
            width: 6),
        Roller((r) => r.shoulder + r.axis * 2.5 + r.front * 1.5,
            radius: 3.4, front: false),
        Slab((_) => const Offset(55, 90.5), (_) => const Offset(73, 85.5),
            width: 3.5, dark: true),
      ],
    );

MotionSpec _legPress() {
  const hip = Offset(40, 70);
  const torso = -55.0;
  final legDir = dirOf(52);
  final perp = dirOf(-38);
  final f = frontOf(torso), ax = dirOf(torso);
  final sh = shoulderOf(hip, torso);
  return MotionSpec(
    (t) {
      final d = pingpong(t);
      final foot = hip + legDir * lerpD(37, 20, d);
      return Pose(
        hip: hip,
        torso: torso,
        head: 25,
        footN: foot,
        footF: foot + const Offset(-2, 1),
        kneeN: const Offset(0.2, -1),
        kneeF: const Offset(0.2, -1),
        handN: hip + const Offset(4, 6),
        handF: hip + const Offset(2, 6),
        toeN: -38,
        toeF: -38,
      );
    },
    props: [
      Slab((_) => hip - f * 7 - ax * 4, (_) => sh - f * 7 + ax * 6, width: 6),
      Slab((_) => hip + const Offset(-7, 7), (_) => hip + const Offset(9, 7),
          width: 5),
      Slab((r) => r.ankleN + perp * 9 + legDir * 3.5,
          (r) => r.ankleN - perp * 9 + legDir * 3.5,
          width: 4, dark: true),
      Slab((_) => hip + legDir * 24 + perp * 13,
          (_) => hip + legDir * 50 + perp * 13,
          width: 2),
    ],
  );
}

// ---- lunges -----------------------------------------------------------------

enum _Lunge { split, reverse, forward, bulgarian }

Pose _lunge(double d, _Lunge mode, {bool dumbbells = false}) {
  final stepping = mode == _Lunge.reverse || mode == _Lunge.forward;
  final step = stepping ? (d * 1.6).clamp(0.0, 1.0) : 1.0;
  final lift = stepping ? 7 * math.sin(math.pi * step) : 0.0;
  var front = const Offset(60, ankleY);
  var back = const Offset(37, 86);
  if (mode == _Lunge.reverse) {
    front = lerpO(_fN, const Offset(60, ankleY), step);
    back = lerpO(_fF, const Offset(37, 86), step) - Offset(0, lift);
  }
  if (mode == _Lunge.forward) {
    front = lerpO(_fN, const Offset(62, ankleY), step) - Offset(0, lift);
    back = lerpO(_fF, const Offset(38, 86), step);
  }
  if (mode == _Lunge.bulgarian) back = const Offset(30, 70.5);
  final midX = (front.dx + back.dx) / 2 + 1;
  final standY = stepping ? standHipY : 53.0;
  final hip = Offset(stepping ? lerpD(50, midX, step) : midX,
      standY + (mode == _Lunge.bulgarian ? 20 : 17) * d);
  final torso = 3 + 5 * d;
  final sh = shoulderOf(hip, torso);
  return Pose(
    hip: hip,
    torso: torso,
    footN: front,
    footF: back,
    kneeF: const Offset(0.3, 1),
    handN: sh + Offset(dumbbells ? 1 : 3, 27),
    handF: sh + Offset(dumbbells ? -1 : 1, 27),
    toeF: mode == _Lunge.bulgarian ? -100 : lerpD(90, 150, step),
  );
}

MotionSpec _lungeSpec(_Lunge mode, {bool dumbbells = false}) => MotionSpec(
      (t) => _lunge(pingpong(t), mode, dumbbells: dumbbells),
      props: [
        if (mode == _Lunge.bulgarian)
          const Bench(Offset(16, 73), Offset(36, 73)),
        if (dumbbells) const Dumbbells(DumbbellStyle.along),
      ],
    );

MotionSpec _stepUp() => MotionSpec(
      (t) {
        final d = pingpong(t);
        final hip = lerpO(const Offset(51, 57), const Offset(63, 34), d);
        final torso = lerpD(14, 3, d);
        final sh = shoulderOf(hip, torso);
        return Pose(
          hip: hip,
          torso: torso,
          footN: const Offset(66, 72),
          footF: lerpO(const Offset(46, ankleY), const Offset(58, 70), d),
          kneeF: const Offset(1, 0.2),
          handN: sh + const Offset(1, 27),
          handF: sh + const Offset(-1, 27),
          toeF: lerpD(90, 130, d),
        );
      },
      props: const [
        Box(Rect.fromLTRB(56, 74, 82, ground)),
        Dumbbells(DumbbellStyle.along),
      ],
    );

MotionSpec _lateralLunge() => MotionSpec(
      (t) {
        final s = swing(t);
        final a = s.abs();
        final hip = Offset(50 + 9 * s, 53 + 12 * a);
        return Pose(
          hip: hip,
          torso: -6 * s,
          footN: const Offset(68, ankleY),
          footF: const Offset(32, ankleY),
          kneeN: const Offset(1, -0.2),
          kneeF: const Offset(-1, -0.2),
          handN: Offset(hip.dx + 3, 40 + 8 * a),
          handF: Offset(hip.dx - 3, 40 + 8 * a),
          elbowN: const Offset(1, 1),
          elbowF: const Offset(-1, 1),
          toeN: 120,
          toeF: 120,
        );
      },
      frontView: true,
      period: _slow,
      stillAt: 0.25,
    );

// ---- hinges -----------------------------------------------------------------

Pose _rdl(double d) {
  final hip = Offset(50 - 12 * d, standHipY + 5 * d);
  final torso = 2 + 60 * d;
  final sh = shoulderOf(hip, torso);
  final hand = sh + const Offset(1, 27);
  return Pose(
    hip: hip,
    torso: torso,
    head: -torso * 0.25,
    footN: _fN,
    footF: _fF,
    handN: hand,
    handF: hand + const Offset(-2, 0),
    kneeN: const Offset(1, 0.1),
  );
}

MotionSpec _deadlift() => MotionSpec((t) {
      final d = pingpong(t);
      final hip = lerpO(const Offset(41, 67), _standHip, d);
      final torso = lerpD(55, 2, d);
      final bar = Offset(lerpD(58, 52, d), lerpD(82, standHipY + 1, d));
      return Pose(
        hip: hip,
        torso: torso,
        head: -torso * 0.3,
        footN: _fN,
        footF: _fF,
        handN: bar,
        handF: bar + const Offset(-1.5, 0),
        kneeN: const Offset(1, -0.1),
      );
    }, props: const [Plate(PlateAt.hands)]);

MotionSpec _singleLegRdl() => MotionSpec((t) {
      final d = pingpong(t);
      final hip = Offset(50 - 6 * d, standHipY + 4 * d);
      final torso = 3 + 77 * d;
      final sh = shoulderOf(hip, torso);
      return Pose(
        hip: hip,
        torso: torso,
        head: -torso * 0.2,
        footN: _fN,
        footF: lerpO(hip + const Offset(-3, 38), hip - dirOf(torso) * 38.5, d),
        kneeF: const Offset(0, 1),
        handN: sh + const Offset(0.5, 27),
        handF: sh + const Offset(3, 26),
        toeF: lerpD(90, 180, d),
      );
    }, props: const [Dumbbells(DumbbellStyle.along, far: false)]);

MotionSpec _swingSpec() => MotionSpec(
      (t) {
        final d = pingpong(t, rest: 0.02, go: 0.46, hold: 0.04);
        final hip = lerpO(const Offset(41, 55), _standHip, d);
        final torso = lerpD(60, 0, d);
        final sh = shoulderOf(hip, torso);
        final hand = lerpO(hip + const Offset(0, 20), sh + const Offset(26, 3),
            Curves.easeIn.transform(d));
        return Pose(
          hip: hip,
          torso: torso,
          head: -torso * 0.4,
          footN: const Offset(55, ankleY),
          footF: const Offset(47, ankleY),
          handN: hand,
          handF: hand + const Offset(-1, 0),
          elbowN: const Offset(0, 1),
          elbowF: const Offset(0, 1),
        );
      },
      period: _quick,
      props: const [Dumbbells(DumbbellStyle.vertical, far: false)],
    );

MotionSpec _backExtension() {
  const hip = Offset(50, 46);
  final ankle = hip - dirOf(46) * 38.5;
  return MotionSpec(
    (t) {
      final d = pingpong(t);
      final torso = lerpD(140, 46, d);
      final sh = shoulderOf(hip, torso);
      final f = frontOf(torso), ax = dirOf(torso);
      final hand = sh + f * 5 - ax * 6;
      return Pose(
        hip: hip,
        torso: torso,
        head: lerpD(-25, 0, d),
        footN: ankle,
        footF: ankle + const Offset(-1.5, 0),
        kneeN: const Offset(0.6, 1),
        kneeF: const Offset(0.6, 1),
        handN: hand,
        handF: hand + const Offset(-1, 0),
        elbowN: f,
        elbowF: f,
        toeN: 140,
        toeF: 140,
      );
    },
    props: [
      Slab(
          (_) => Offset(ankle.dx - 4, ground), (_) => hip + const Offset(3, 10),
          width: 3),
      Roller((r) => r.hip + const Offset(4, 4.5), radius: 5, front: false),
      Roller((r) => r.ankleN + const Offset(-0.5, -4.6), radius: 3.4),
    ],
  );
}

MotionSpec _nordic() => MotionSpec(
      (t) {
        final d = pingpong(t, rest: 0.1, go: 0.55, hold: 0.05);
        const knee = Offset(46, 87);
        final a = lerpD(4, 60, d);
        final hip = knee + dirOf(a) * thighLen;
        final sh = shoulderOf(hip, a);
        return Pose(
          hip: hip,
          torso: a,
          head: -10 * d,
          footN: const Offset(27, 87),
          footF: const Offset(25, 87),
          kneeN: const Offset(0.3, 1),
          kneeF: const Offset(0.3, 1),
          handN: sh + frontOf(a) * 8 - dirOf(a) * 4,
          handF: sh + frontOf(a) * 7 - dirOf(a) * 4,
          elbowN: const Offset(-0.5, 1),
          elbowF: const Offset(-0.5, 1),
          toeN: -100,
          toeF: -100,
        );
      },
      period: _slow,
      props: [
        Roller((r) => r.ankleN + const Offset(0, -4.6), radius: 3.4),
        Slab((_) => const Offset(39, 90.5), (_) => const Offset(55, 90.5),
            width: 3),
      ],
    );

// ---- bridges ------------------------------------------------------------------

Pose _bridge(double d, {bool single = false}) {
  // shoulders stay on the floor; the hips swing up around them until
  // shoulders, hips and knees line up
  const sh = Offset(24, 85);
  final hip = sh + dirOf(lerpD(90, 65, d)) * torsoLen;
  final torso = angleTo(hip, sh);
  return Pose(
    hip: hip,
    torso: torso,
    head: -90 - torso, // head rests on the floor
    footN: const Offset(65, ankleY),
    footF:
        single ? hip + dirOf(lerpD(68, 62, d)) * 38 : const Offset(63, ankleY),
    kneeN: const Offset(0.3, -1),
    kneeF: single ? const Offset(0.5, -1) : const Offset(0.3, -1),
    // arms long on the floor beside the body
    handN: const Offset(50.5, 89),
    handF: const Offset(48.5, 89),
    elbowN: const Offset(0, -1),
    elbowF: const Offset(0, -1),
    toeF: single ? lerpD(40, 30, d) : 90,
  );
}

MotionSpec _hipThrust({required bool barbell}) => MotionSpec(
      (t) {
        final d = pingpong(t);
        final hip = lerpO(const Offset(44, 83), const Offset(49, 66), d);
        final torso = angleTo(hip, const Offset(26, 66));
        final hand = hip + frontOf(torso) * 7 + const Offset(-1, 0);
        return Pose(
          hip: hip,
          torso: torso,
          head: lerpD(0, 50, d),
          footN: const Offset(66, ankleY),
          footF: const Offset(64, ankleY),
          kneeN: const Offset(0.3, -1),
          kneeF: const Offset(0.3, -1),
          handN: hand,
          handF: hand + const Offset(-2, 0),
          elbowN: const Offset(-0.5, -1),
          elbowF: const Offset(-0.5, -1),
        );
      },
      props: [
        const Bench(Offset(8, 68), Offset(30, 68)),
        barbell
            ? const Plate(PlateAt.hip)
            : const Dumbbells(DumbbellStyle.along, far: false),
      ],
    );

// ---- push-ups & planks -------------------------------------------------------

Pose _plankLine(Offset ankle, double theta, Offset hand,
    {Offset? handFar, double toe = 180}) {
  final u = _polar(theta);
  final hip = ankle + u * (thighLen + shinLen - 0.5);
  return Pose(
    hip: hip,
    torso: 90 - theta,
    footN: ankle,
    footF: ankle + const Offset(-1.5, 0),
    kneeN: const Offset(0, 1),
    kneeF: const Offset(0, 1),
    handN: hand,
    handF: handFar ?? hand + const Offset(-2.5, 0),
    elbowN: const Offset(-1, -0.6),
    elbowF: const Offset(-1, -0.6),
    toeN: toe,
    toeF: toe,
  );
}

MotionSpec _pushUp() => MotionSpec((t) => _plankLine(const Offset(14, 86),
    lerpD(21.5, 6, pingpong(t)), const Offset(80, ankleY)));

MotionSpec _kneePushUp() => MotionSpec((t) {
      final d = pingpong(t);
      const knee = Offset(36, 88);
      final th = lerpD(36, 13, d);
      final hip = knee + _polar(th) * thighLen;
      return Pose(
        hip: hip,
        torso: 90 - th,
        // shins rest on the floor behind the knees
        footN: const Offset(17.5, 89.5),
        footF: const Offset(16, 89.5),
        kneeN: const Offset(0, 1),
        kneeF: const Offset(0, 1),
        handN: const Offset(74, ankleY),
        handF: const Offset(71.5, ankleY),
        elbowN: const Offset(-1, -0.6),
        elbowF: const Offset(-1, -0.6),
        toeN: -95,
        toeF: -95,
      );
    });

MotionSpec _declinePushUp() => MotionSpec(
      (t) => _plankLine(const Offset(12, 73), lerpD(8.8, -6, pingpong(t)),
          const Offset(76, ankleY)),
      props: const [Bench(Offset(2, 80), Offset(24, 80))],
    );

MotionSpec _pikePushUp() => MotionSpec((t) {
      final d = pingpong(t);
      const hip = Offset(42, 53);
      final torso =
          angleTo(hip, lerpO(const Offset(62, 63), const Offset(61, 76), d));
      return Pose(
        hip: hip,
        torso: torso,
        footN: const Offset(28, 86.5),
        footF: const Offset(26, 86.5),
        kneeN: const Offset(0, 1),
        kneeF: const Offset(0, 1),
        handN: const Offset(66, ankleY),
        handF: const Offset(63.5, ankleY),
        elbowN: const Offset(-1, -0.3),
        elbowF: const Offset(-1, -0.3),
        toeN: 160,
        toeF: 160,
      );
    });

MotionSpec _mountainClimber() {
  final base = _plankLine(const Offset(14, 86), 21.5, const Offset(80, ankleY));
  Offset drive(double k) =>
      lerpO(const Offset(14, 86), base.hip + const Offset(10, 15), k);
  return MotionSpec(
    (t) {
      final s = swing(t);
      final kn = s > 0 ? s : 0.0;
      final kf = s < 0 ? -s : 0.0;
      return base.copyWith(
        footN: drive(kn) - Offset(0, 3 * kn),
        footF: drive(kf) + const Offset(-1.5, 0),
        kneeN: const Offset(0.2, 1),
        kneeF: const Offset(0.2, 1),
        toeN: lerpD(180, 150, kn),
        toeF: lerpD(180, 150, kf),
      );
    },
    period: const Duration(milliseconds: 1000),
    stillAt: 0.25,
  );
}

MotionSpec _bearCrawl() => MotionSpec(
      (t) {
        final s = swing(t);
        final c = math.cos(2 * math.pi * t);
        final bob = 0.8 * math.sin(4 * math.pi * t);
        final hip = Offset(40 + 1.2 * s, 61 + bob);
        return Pose(
          hip: hip,
          torso: 90,
          head: -15,
          footN: Offset(31 - 4 * s, 86 - 3 * math.max(0, -c)),
          footF: Offset(29 + 4 * s, 86 - 3 * math.max(0, c)),
          kneeN: const Offset(1, 0.6),
          kneeF: const Offset(1, 0.6),
          handN: Offset(70 + 4 * s, ankleY - 3 * math.max(0, c)),
          handF: Offset(67 - 4 * s, ankleY - 3 * math.max(0, -c)),
          elbowN: const Offset(-1, 0),
          elbowF: const Offset(-1, 0),
          toeN: 150,
          toeF: 150,
        );
      },
      period: const Duration(milliseconds: 1300),
    );

MotionSpec _burpee() {
  final stand = _squat(0, _Hold.reach);
  const crouch = Pose(
    hip: Offset(44, 74),
    torso: 58,
    head: -20,
    footN: Offset(53, ankleY),
    footF: Offset(49, ankleY),
    handN: Offset(64, 89),
    handF: Offset(61, 89),
    elbowN: Offset(-1, -0.5),
    elbowF: Offset(-1, -0.5),
  );
  final plank =
      _plankLine(const Offset(-2, 86), 21.5, const Offset(64, ankleY));
  final jumpHip = _standHip - const Offset(0, 9);
  final jumpSh = shoulderOf(jumpHip, 2);
  final jump = stand.copyWith(
    hip: jumpHip,
    torso: 2,
    head: 0,
    footN: _fN - const Offset(0, 8),
    footF: _fF - const Offset(0, 8),
    toeN: 160,
    toeF: 160,
    handN: jumpSh + const Offset(5, -26),
    handF: jumpSh + const Offset(3, -26),
  );
  return MotionSpec(
    (t) => keyframes([
      (0, stand),
      (0.15, crouch),
      (0.3, plank),
      (0.42, plank),
      (0.56, crouch),
      (0.68, stand),
      (0.78, jump),
      (0.9, stand),
      (1, stand),
    ], t),
    period: const Duration(milliseconds: 3400),
    stillAt: 0.34,
  );
}

MotionSpec _forearmPlank() => MotionSpec(
      (t) {
        final th = 10 + 0.5 * swing(t);
        const ankle = Offset(14, 86);
        final hip = ankle + _polar(th) * 38.5;
        final sh = shoulderOf(hip, 90 - th);
        return Pose(
          hip: hip,
          torso: 90 - th,
          footN: ankle,
          footF: ankle + const Offset(-1.5, 0),
          kneeN: const Offset(0, 1),
          kneeF: const Offset(0, 1),
          handN: Offset(sh.dx + 12, 89),
          handF: Offset(sh.dx + 9.5, 89),
          elbowN: const Offset(0, 1),
          elbowF: const Offset(0, 1),
          toeN: 180,
          toeF: 180,
        );
      },
      period: _slow,
      stillAt: 0,
    );

MotionSpec _sidePlank() => MotionSpec(
      (t) {
        // seen from the front, lying on the right side: one straight line
        // from the stacked feet to the head, propped on the right forearm
        final th = 20 + 0.6 * swing(t);
        const foot = Offset(14, 87);
        final torso = 90 - th;
        final side = frontOf(torso); // the body's right side, pointing down
        final hipN = foot + _polar(th) * (thighLen + shinLen - 0.4);
        final hip = hipN - side * 5;
        final probe = Pose(
            hip: hip,
            torso: torso,
            footN: foot,
            footF: foot,
            handN: hip,
            handF: hip);
        final shLow = probe.shoulder + side * 9;
        final shHigh = probe.shoulder - side * 9;
        return probe.copyWith(
          footN: foot,
          footF: foot - side * 9.5,
          kneeN: const Offset(0, 1),
          kneeF: const Offset(0, -1),
          handN: Offset(shLow.dx + 11, 89),
          handF: shHigh + const Offset(1, -26),
          elbowN: const Offset(0, 1),
          elbowF: const Offset(-1, 0),
          toeN: -135,
          toeF: 135,
        );
      },
      frontView: true,
      period: _slow,
      stillAt: 0,
    );

MotionSpec _benchDip() => MotionSpec(
      (t) {
        final d = pingpong(t);
        final sh = Offset(40, lerpD(37, 50, d));
        final hip = sh + const Offset(1, 26);
        return Pose(
          hip: hip,
          torso: angleTo(hip, sh),
          footN: const Offset(70, ankleY),
          footF: const Offset(67, ankleY),
          kneeN: const Offset(0.2, -1),
          kneeF: const Offset(0.2, -1),
          handN: const Offset(37, 64),
          handF: const Offset(35, 64),
          elbowN: const Offset(-1, -0.2),
          elbowF: const Offset(-1, -0.2),
        );
      },
      props: const [Bench(Offset(14, 64.5), Offset(38, 64.5))],
    );

MotionSpec _dip() => MotionSpec(
      (t) {
        final d = pingpong(t);
        final sh = lerpO(const Offset(50, 17), const Offset(47, 29), d);
        final torso = lerpD(4, 18, d);
        final hip = sh - dirOf(torso) * torsoLen;
        return Pose(
          hip: hip,
          torso: torso,
          footN: hip + const Offset(-12, 30),
          footF: hip + const Offset(-14, 29),
          kneeN: const Offset(1, 0.3),
          kneeF: const Offset(1, 0.3),
          handN: const Offset(51, 44),
          handF: const Offset(49, 44),
          elbowN: const Offset(-1, -0.3),
          elbowF: const Offset(-1, -0.3),
          toeN: 140,
          toeF: 140,
        );
      },
      props: const [Bar(Offset(36, 45.5), Offset(62, 45.5))],
    );

// ---- lying presses -----------------------------------------------------------

Pose _lying(Offset hand,
    {double hipX = 54,
    double y = 58.5,
    Offset elbow = const Offset(-0.2, 1),
    Offset? feet}) {
  final hip = Offset(hipX, y);
  final f = feet ?? const Offset(68, ankleY);
  return Pose(
    hip: hip,
    torso: -90,
    footN: f,
    footF: f + const Offset(-3, 0),
    kneeN: const Offset(0.6, -1),
    kneeF: const Offset(0.6, -1),
    handN: hand,
    handF: hand + const Offset(-1.5, 0),
    elbowN: elbow,
    elbowF: elbow,
  );
}

const _flatBench = Bench(Offset(10, 64.5), Offset(60, 64.5));

MotionSpec _benchPress({required bool barbell}) => MotionSpec(
      (t) => _lying(
          lerpO(const Offset(29, 31), const Offset(32, 50), pingpong(t))),
      props: [
        _flatBench,
        barbell
            ? const Plate(PlateAt.hands)
            : const Dumbbells(DumbbellStyle.end),
      ],
    );

MotionSpec _inclinePress({required bool barbell}) {
  const hip = Offset(52, 62);
  const torso = -60.0;
  final f = frontOf(torso), ax = dirOf(torso);
  final sh = shoulderOf(hip, torso);
  return MotionSpec(
    (t) {
      final hand =
          lerpO(const Offset(31, 22), const Offset(33, 41), pingpong(t));
      return Pose(
        hip: hip,
        torso: torso,
        footN: const Offset(66, ankleY),
        footF: const Offset(63, ankleY),
        kneeN: const Offset(0.6, -1),
        kneeF: const Offset(0.6, -1),
        handN: hand,
        handF: hand + const Offset(-1.5, 0),
        elbowN: const Offset(-0.3, 1),
        elbowF: const Offset(-0.3, 1),
      );
    },
    props: [
      Slab((_) => hip - f * 7 - ax * 3, (_) => sh - f * 7 + ax * 4, width: 6),
      Slab((_) => hip + const Offset(-8, 7), (_) => hip + const Offset(10, 7),
          width: 5),
      Slab((_) => Offset(hip.dx, ground), (_) => hip + const Offset(0, 9),
          width: 2.6),
      barbell ? const Plate(PlateAt.hands) : const Dumbbells(DumbbellStyle.end),
    ],
  );
}

MotionSpec _floorPress() => MotionSpec(
      (t) => _lying(
          lerpO(const Offset(29, 58), const Offset(31, 76), pingpong(t)),
          y: 85.5,
          feet: const Offset(66, ankleY),
          elbow: const Offset(-0.3, 1)),
      props: const [Dumbbells(DumbbellStyle.end)],
    );

MotionSpec _skullCrusher() => MotionSpec(
      (t) {
        const elbow = Offset(31, 45);
        final hand = elbow + dirOf(lerpD(0, -105, pingpong(t))) * 14;
        return _lying(hand, elbow: const Offset(0.2, -1));
      },
      props: const [_flatBench, Dumbbells(DumbbellStyle.end)],
    );

MotionSpec _flyTop() => MotionSpec(
      (t) {
        // seen from above, lying on a flat bench: arms open wide in an arc
        // and hug back together over the chest
        final d = pingpong(t);
        const hip = Offset(50, 64);
        return Pose(
          hip: hip,
          // thighs run along the bench, shins drop to the floor beside it
          thighScale: 0.9,
          shinScale: 0.3,
          footN: const Offset(60, 88),
          footF: const Offset(40, 88),
          kneeN: const Offset(1, 0),
          kneeF: const Offset(-1, 0),
          // arms aimed at the ceiling look short from above; opened out
          // they lie flat and show their full length
          armScale: lerpD(0.4, 1, d),
          handN: lerpO(const Offset(52.5, 42), const Offset(80, 42), d),
          handF: lerpO(const Offset(47.5, 42), const Offset(20, 42), d),
          elbowN: const Offset(0.2, 1),
          elbowF: const Offset(-0.2, 1),
          toeN: 150,
          toeF: 150,
        );
      },
      frontView: true,
      showGround: false,
      props: [
        Slab((_) => const Offset(50, 20), (_) => const Offset(50, 80),
            width: 22),
        const Dumbbells(DumbbellStyle.end),
      ],
    );

// ---- seated machines -----------------------------------------------------------

List<Prop> _seat(Offset hip, double torso) {
  final f = frontOf(torso), ax = dirOf(torso);
  final sh = shoulderOf(hip, torso);
  return [
    Slab((_) => hip - f * 7 - ax * 4, (_) => sh - f * 7 + ax * 4, width: 6),
    Slab((_) => hip + const Offset(-8, 7), (_) => hip + const Offset(10, 7),
        width: 5),
    Slab((_) => Offset(hip.dx, ground), (_) => hip + const Offset(0, 9),
        width: 2.6),
  ];
}

MotionSpec _chestPressMachine() {
  const hip = Offset(40, 66);
  const torso = -6.0;
  final sh = shoulderOf(hip, torso);
  return MotionSpec(
    (t) {
      final hand =
          lerpO(sh + const Offset(9, 4), sh + const Offset(27, 2), pingpong(t));
      return Pose(
        hip: hip,
        torso: torso,
        footN: const Offset(60, ankleY),
        footF: const Offset(57, ankleY),
        kneeN: const Offset(1, -0.4),
        kneeF: const Offset(1, -0.4),
        handN: hand,
        handF: hand + const Offset(-1.5, 0),
        elbowN: const Offset(-1, 0.4),
        elbowF: const Offset(-1, 0.4),
      );
    },
    props: [
      ..._seat(hip, torso),
      Slab((r) => r.wristN, (_) => const Offset(30, 16), width: 2),
      Slab((r) => r.wristN + const Offset(0, -4),
          (r) => r.wristN + const Offset(0, 4),
          width: 2.6, dark: true, front: true),
    ],
  );
}

MotionSpec _shoulderPress(
    {bool seated = false, bool barbell = false, bool machine = false}) {
  final hip = seated ? const Offset(44, 66) : _standHip;
  final torso = seated ? -4.0 : 2.0;
  final sh = shoulderOf(hip, torso);
  return MotionSpec(
    (t) {
      final hand = lerpO(
          sh + const Offset(6, 1), sh + const Offset(2, -27), pingpong(t));
      return Pose(
        hip: hip,
        torso: torso,
        footN: seated ? const Offset(62, ankleY) : _fN,
        footF: seated ? const Offset(59, ankleY) : _fF,
        kneeN: seated ? const Offset(1, -0.3) : const Offset(1, 0),
        kneeF: seated ? const Offset(1, -0.3) : const Offset(1, 0),
        handN: hand,
        handF: hand + const Offset(-1.5, 0),
        elbowN: const Offset(0.4, 1),
        elbowF: const Offset(0.4, 1),
      );
    },
    props: [
      if (seated) ..._seat(hip, torso),
      if (machine)
        Slab((r) => r.wristN + const Offset(0, -4),
            (r) => r.wristN + const Offset(0, 4),
            width: 2.6, dark: true, front: true)
      else if (barbell)
        const Plate(PlateAt.hands)
      else
        const Dumbbells(DumbbellStyle.end),
    ],
  );
}

MotionSpec _pecDeck({bool reverse = false}) {
  const hip = Offset(50, 64);
  return MotionSpec(
    (t) {
      final d = pingpong(t);
      final open = reverse ? d : 1 - d;
      return Pose(
        hip: hip,
        thighScale: 0.4, // seated, thighs aimed at the camera
        footN: const Offset(58, ankleY),
        footF: const Offset(42, ankleY),
        kneeN: const Offset(1, 0),
        kneeF: const Offset(-1, 0),
        handN: lerpO(const Offset(55, 26), Offset(82, reverse ? 38 : 26), open),
        handF: lerpO(const Offset(45, 26), Offset(18, reverse ? 38 : 26), open),
        elbowN: reverse ? const Offset(0.4, -1) : const Offset(1, 0.8),
        elbowF: reverse ? const Offset(-0.4, -1) : const Offset(-1, 0.8),
        toeN: 130,
        toeF: 130,
      );
    },
    frontView: true,
    props: [
      Slab((_) => const Offset(50, 30), (_) => const Offset(50, 64), width: 24),
      Slab((_) => const Offset(37, 69), (_) => const Offset(63, 69), width: 5),
      if (!reverse) ...[
        Slab((r) => r.elbowN, (r) => r.wristN, width: 9),
        Slab((r) => r.elbowF, (r) => r.wristF, width: 9),
      ],
    ],
  );
}

/// Standing cable crossover from high pulleys: hands sweep down and in.
MotionSpec _cableFly() => MotionSpec(
      (t) {
        final d = pingpong(t);
        return _frontStand(
          torsoScale: 0.95,
          handN: lerpO(const Offset(80, 30), const Offset(53, 66), d),
          handF: lerpO(const Offset(20, 30), const Offset(47, 66), d),
        ).copyWith(elbowN: const Offset(1, 0.6), elbowF: const Offset(-1, 0.6));
      },
      frontView: true,
      props: const [
        Bar(Offset(8, 10), Offset(8, 10)),
        Bar(Offset(92, 10), Offset(92, 10)),
        Cable(Offset(92, 14), bothHands: false),
        Cable(Offset(8, 14), far: true),
      ],
    );

MotionSpec _legExtension() {
  const hip = Offset(40, 64);
  const torso = -6.0;
  return MotionSpec(
    (t) {
      final d = pingpong(t);
      final foot = lerpO(const Offset(60, 83), const Offset(78.5, 64), d);
      return Pose(
        hip: hip,
        torso: torso,
        footN: foot,
        footF: foot + const Offset(-1.5, 0.5),
        kneeN: const Offset(1, -1),
        kneeF: const Offset(1, -1),
        handN: hip + const Offset(3, 7),
        handF: hip + const Offset(1, 7),
        toeN: lerpD(110, 30, d),
        toeF: lerpD(110, 30, d),
      );
    },
    props: [
      ..._seat(hip, torso),
      Roller((r) => r.ankleN + const Offset(2, -2), radius: 3.8),
    ],
  );
}

MotionSpec _legCurl() => MotionSpec(
      (t) {
        final d = pingpong(t);
        const hip = Offset(42, 63);
        final foot = lerpO(const Offset(3.5, 64), const Offset(23, 45), d);
        return Pose(
          hip: hip,
          torso: 90,
          head: -10,
          footN: foot,
          footF: foot + const Offset(1, 1.5),
          kneeN: const Offset(0, 1),
          kneeF: const Offset(0, 1),
          handN: const Offset(80, 71),
          handF: const Offset(78, 71),
          elbowN: const Offset(0, 1),
          elbowF: const Offset(0, 1),
          toeN: lerpD(-90, -10, d),
          toeF: lerpD(-90, -10, d),
        );
      },
      props: [
        const Bench(Offset(20, 69), Offset(74, 69)),
        Roller((r) => r.ankleN + const Offset(0, -4.5), radius: 3.6),
      ],
    );

MotionSpec _hipAbduction() => MotionSpec(
      (t) {
        // seated, seen from the front: the knees push the pads apart; the
        // thighs (aimed at the camera) lengthen on screen as they open
        final d = pingpong(t);
        const hip = Offset(50, 62);
        final shN = shoulderOf(hip, 0) + const Offset(9, 0);
        final shF = shoulderOf(hip, 0) - const Offset(9, 0);
        return Pose(
          hip: hip,
          thighScale: lerpD(0.4, 0.8, d),
          footN: lerpO(const Offset(57, 88), const Offset(67, 88), d),
          footF: lerpO(const Offset(43, 88), const Offset(33, 88), d),
          kneeN: const Offset(1, -0.2),
          kneeF: const Offset(-1, -0.2),
          handN: shN + const Offset(4, 25),
          handF: shF + const Offset(-4, 25),
          elbowN: const Offset(1, 0),
          elbowF: const Offset(-1, 0),
          toeN: 130,
          toeF: 130,
        );
      },
      frontView: true,
      props: [
        Slab((_) => const Offset(50, 30), (_) => const Offset(50, 64),
            width: 24),
        Slab((_) => const Offset(36, 68), (_) => const Offset(64, 68),
            width: 5),
        Roller((r) => r.kneeN + const Offset(4.5, 0), radius: 3.4),
        Roller((r) => r.kneeF - const Offset(4.5, 0), radius: 3.4),
      ],
    );

// ---- raises ----------------------------------------------------------------------

MotionSpec _frontRaise() => MotionSpec((t) {
      final sh = shoulderOf(_standHip, 2);
      final hand = sh + dirOf(lerpD(172, 88, pingpong(t))) * 27.5;
      return _stand(handN: hand, handF: hand + const Offset(-1.5, 0))
          .copyWith(elbowN: const Offset(0, 1), elbowF: const Offset(0, 1));
    }, props: const [Dumbbells(DumbbellStyle.end)]);

Pose _frontStand(
        {required Offset handN,
        required Offset handF,
        Offset hip = _standHip,
        double torsoScale = 1}) =>
    Pose(
      hip: hip,
      torsoScale: torsoScale,
      footN: const Offset(56, ankleY),
      footF: const Offset(44, ankleY),
      kneeN: const Offset(1, 0),
      kneeF: const Offset(-1, 0),
      handN: handN,
      handF: handF,
      elbowN: const Offset(0.3, -1),
      elbowF: const Offset(-0.3, -1),
      toeN: 128,
      toeF: 128,
    );

MotionSpec _lateralRaise() => MotionSpec(
      (t) {
        final sh = shoulderOf(_standHip, 0);
        final a = lerpD(172, 92, pingpong(t));
        return _frontStand(
          handN: sh + const Offset(9, 0) + dirOf(a) * 27,
          handF: sh - const Offset(9, 0) + dirOf(-a) * 27,
        );
      },
      frontView: true,
      props: const [Dumbbells(DumbbellStyle.end)],
    );

MotionSpec _cableLateralRaise() => MotionSpec(
      (t) {
        final sh = shoulderOf(_standHip, 0);
        final d = pingpong(t);
        return _frontStand(
          handN: lerpO(const Offset(46, 64),
              sh + const Offset(9, 0) + dirOf(92) * 27, d),
          handF: const Offset(34, 52),
        ).copyWith(elbowF: const Offset(-1, 0.5));
      },
      frontView: true,
      props: const [Cable(Offset(16, 90), bothHands: false)],
    );

MotionSpec _reverseFlyBent() => MotionSpec(
      (t) {
        // bent over, seen from the front: hips back, so the thighs look
        // shorter; the arms open out to the sides
        const hip = Offset(50, 57);
        final sh = hip + const Offset(0, -26 * 0.55);
        final a = lerpD(176, 96, pingpong(t));
        return _frontStand(
          hip: hip,
          torsoScale: 0.55,
          handN: sh + const Offset(9, 0) + dirOf(a) * 26,
          handF: sh - const Offset(9, 0) + dirOf(-a) * 26,
        ).copyWith(thighScale: 0.78);
      },
      frontView: true,
      props: const [Dumbbells(DumbbellStyle.end)],
    );

MotionSpec _facePull() => MotionSpec((t) {
      const hip = Offset(48, standHipY);
      final sh = shoulderOf(hip, -2);
      final hand = lerpO(
          sh + const Offset(26, -4), sh + const Offset(5, -11), pingpong(t));
      return Pose(
        hip: hip,
        torso: -2,
        footN: const Offset(51, ankleY),
        footF: const Offset(46, ankleY),
        handN: hand,
        handF: hand + const Offset(-1.5, 0),
        elbowN: const Offset(-0.6, -1),
        elbowF: const Offset(-0.6, -1),
      );
    }, props: const [Cable(Offset(92, 20), rope: true)]);

// ---- rows & pulls ------------------------------------------------------------------

Pose _bentRow(double d, {double torso = 68, bool oneArm = false}) {
  const hip = Offset(44, 55);
  final sh = shoulderOf(hip, torso);
  final hang = sh + const Offset(0.5, 27);
  final pulled = hip + dirOf(torso) * 12 + frontOf(torso) * 6;
  final hn = lerpO(hang, pulled, d);
  return Pose(
    hip: hip,
    torso: torso,
    head: -30,
    footN: oneArm ? const Offset(48, ankleY) : _fN,
    footF: oneArm ? const Offset(58, ankleY) : _fF,
    kneeN: const Offset(1, 0.1),
    handN: hn,
    handF: oneArm ? const Offset(80, 64) : hn + const Offset(-1.5, 0),
    elbowN: const Offset(-0.5, -1),
    elbowF: oneArm ? const Offset(-0.3, 1) : const Offset(-0.5, -1),
  );
}

MotionSpec _cableRow() => MotionSpec(
      (t) {
        final d = pingpong(t);
        const hip = Offset(34, 76);
        final torso = lerpD(4, -8, d);
        final sh = shoulderOf(hip, torso);
        final hand =
            lerpO(sh + const Offset(25, 8), sh + const Offset(6, 17), d);
        return Pose(
          hip: hip,
          torso: torso,
          footN: const Offset(66, 80),
          footF: const Offset(64, 81),
          kneeN: const Offset(0.3, -1),
          kneeF: const Offset(0.3, -1),
          handN: hand,
          handF: hand + const Offset(-1.5, 0),
          elbowN: const Offset(-1, 0.1),
          elbowF: const Offset(-1, 0.1),
          toeN: -10,
          toeF: -10,
        );
      },
      props: [
        const Box(Rect.fromLTRB(22, 81, 46, ground)),
        Slab((_) => const Offset(71, 72), (_) => const Offset(71, 88),
            width: 3.5),
        const Cable(Offset(94, 82)),
      ],
    );

MotionSpec _invertedRow() => MotionSpec(
      (t) {
        const ankle = Offset(16, 87);
        final th = lerpD(12, 28, pingpong(t));
        final hip = ankle + _polar(th) * 38.5;
        return Pose(
          hip: hip,
          torso: 90 - th,
          head: -10,
          footN: ankle,
          footF: ankle + const Offset(-1.5, 0),
          kneeN: const Offset(0, 1),
          kneeF: const Offset(0, 1),
          handN: const Offset(79, 47),
          handF: const Offset(77, 47),
          elbowN: const Offset(-0.5, 1),
          elbowF: const Offset(-0.5, 1),
          toeN: 20,
          toeF: 20,
        );
      },
      props: const [Bar(Offset(70, 46.5), Offset(92, 46.5))],
    );

Pose _hang(double d, {bool chin = false, double legs = 0, double breath = 0}) {
  const grip = Offset(52, -4);
  final sh =
      lerpO(const Offset(51, 23), const Offset(50, 6), d) + Offset(0, breath);
  const torso = -4.0;
  final hip = sh - dirOf(torso) * torsoLen;
  final bentFoot = hip + const Offset(-14, 22);
  final raised = hip + dirOf(lerpD(178, 88, legs)) * 38;
  return Pose(
    hip: hip,
    torso: torso,
    head: 6,
    footN: legs > 0 ? raised : bentFoot,
    footF:
        legs > 0 ? raised + const Offset(-1.5, 1) : hip + const Offset(-16, 21),
    kneeN: legs > 0 ? const Offset(0.6, -0.8) : const Offset(1, 0.4),
    kneeF: legs > 0 ? const Offset(0.6, -0.8) : const Offset(1, 0.4),
    handN: grip,
    handF: grip + const Offset(-3, 0),
    elbowN: chin ? const Offset(0.4, 1) : const Offset(0, 1),
    elbowF: chin ? const Offset(0.4, 1) : const Offset(0, 1),
    toeN: legs > 0 ? lerpD(150, 20, legs) : 150,
    toeF: legs > 0 ? lerpD(150, 20, legs) : 150,
  );
}

const _pullBar = Bar(Offset(32, -5), Offset(72, -5));

MotionSpec _pullUp({bool chin = false, bool negative = false}) => MotionSpec(
      (t) => _hang(
          negative
              ? 1 - pingpong(t, rest: 0.08, go: 0.6, hold: 0.06)
              : pingpong(t),
          chin: chin),
      period: negative ? _slow : _std,
      props: const [_pullBar],
    );

MotionSpec _pulldown() {
  const hip = Offset(46, 70);
  const torso = -12.0;
  final sh = shoulderOf(hip, torso);
  return MotionSpec(
    (t) {
      final hand = lerpO(
          sh + const Offset(6, -27), sh + const Offset(9, 2), pingpong(t));
      return Pose(
        hip: hip,
        torso: torso,
        head: 8,
        footN: const Offset(64, ankleY),
        footF: const Offset(61, ankleY),
        kneeN: const Offset(1, -0.3),
        kneeF: const Offset(1, -0.3),
        handN: hand,
        handF: hand + const Offset(-2, 0),
        elbowN: const Offset(0.3, 1),
        elbowF: const Offset(0.3, 1),
      );
    },
    props: [
      Slab((_) => hip + const Offset(-8, 7), (_) => hip + const Offset(10, 7),
          width: 5),
      Slab((_) => Offset(hip.dx, ground), (_) => hip + const Offset(0, 9),
          width: 2.6),
      const Roller(_kneePad, radius: 3.4, front: false),
      const Cable(Offset(54, 2)),
      Roller((r) => (r.wristN + r.wristF) / 2, radius: 2.2),
    ],
  );
}

Offset _kneePad(Rig r) => const Offset(61, 63);

MotionSpec _straightArmPulldown() => MotionSpec((t) {
      const hip = Offset(48, 52);
      const torso = 18.0;
      final sh = shoulderOf(hip, torso);
      final hand = sh + dirOf(lerpD(28, 165, pingpong(t))) * 27.5;
      return Pose(
        hip: hip,
        torso: torso,
        head: -10,
        footN: _fN,
        footF: _fF,
        handN: hand,
        handF: hand + const Offset(-1.5, 0),
        elbowN: const Offset(-0.5, -1),
        elbowF: const Offset(-0.5, -1),
      );
    }, props: const [Cable(Offset(90, 4))]);

// ---- curls & extensions ---------------------------------------------------------------

MotionSpec _curl({required Prop prop}) => MotionSpec((t) {
      final sh = shoulderOf(_standHip, 2);
      final elbow = sh + const Offset(-1, 14);
      final hand = elbow + dirOf(lerpD(176, 32, pingpong(t))) * 14;
      return _stand(handN: hand, handF: hand + const Offset(-2, 0)).copyWith(
          elbowN: const Offset(-1, 0.5), elbowF: const Offset(-1, 0.5));
    }, props: [prop]);

MotionSpec _concentrationCurl() => MotionSpec(
      (t) {
        const hip = Offset(42, 63);
        const torso = 38.0;
        final sh = shoulderOf(hip, torso);
        final elbow = sh + dirOf(178) * 14;
        final hand = elbow + dirOf(lerpD(178, 25, pingpong(t))) * 14;
        return Pose(
          hip: hip,
          torso: torso,
          head: -15,
          footN: const Offset(64, ankleY),
          footF: const Offset(58, ankleY),
          kneeN: const Offset(1, -0.5),
          kneeF: const Offset(1, -0.5),
          handN: hand,
          handF: const Offset(60, 66),
          elbowN: const Offset(-1, 0.3),
          elbowF: const Offset(0, 1),
        );
      },
      props: const [
        Bench(Offset(26, 66), Offset(50, 66)),
        Dumbbells(DumbbellStyle.end, far: false),
      ],
    );

MotionSpec _overheadExtension({required bool rope}) => MotionSpec((t) {
      final sh = shoulderOf(_standHip, 2);
      final elbow = sh + dirOf(-6) * 14;
      final hand = elbow + dirOf(lerpD(-150, -4, pingpong(t))) * 14;
      return _stand(handN: hand, handF: hand + const Offset(-1.5, 0)).copyWith(
          elbowN: const Offset(0.2, -1), elbowF: const Offset(0.2, -1));
    }, props: [
      rope
          ? const Cable(Offset(6, 86), rope: true)
          : const Dumbbells(DumbbellStyle.vertical, far: false),
    ]);

MotionSpec _pushdown() => MotionSpec((t) {
      const hip = Offset(48, standHipY);
      const torso = 10.0;
      final sh = shoulderOf(hip, torso);
      final elbow = sh + dirOf(178) * 14;
      final hand = elbow + dirOf(lerpD(40, 172, pingpong(t))) * 14;
      return Pose(
        hip: hip,
        torso: torso,
        head: -8,
        footN: const Offset(51, ankleY),
        footF: const Offset(46, ankleY),
        handN: hand,
        handF: hand + const Offset(-1.5, 0),
        elbowN: const Offset(-1, 0.3),
        elbowF: const Offset(-1, 0.3),
      );
    }, props: const [Cable(Offset(72, 2), rope: true)]);

MotionSpec _kickback() => MotionSpec(
      (t) {
        const hip = Offset(44, 56);
        const torso = 70.0;
        final sh = shoulderOf(hip, torso);
        final elbow = sh - dirOf(torso) * 14;
        final hand = elbow + dirOf(lerpD(180, 250, pingpong(t))) * 14;
        return Pose(
          hip: hip,
          torso: torso,
          head: -30,
          footN: const Offset(48, ankleY),
          footF: const Offset(58, ankleY),
          kneeN: const Offset(1, 0.1),
          handN: hand,
          handF: const Offset(80, 64),
          elbowN: const Offset(-0.6, -1),
          elbowF: const Offset(-0.3, 1),
        );
      },
      props: const [
        Bench(Offset(64, 65.5), Offset(92, 65.5)),
        Dumbbells(DumbbellStyle.end, far: false),
      ],
    );

// ---- core ----------------------------------------------------------------------

Pose _supine({
  required double torso,
  double hipX = 52,
  double hipY = 85.5,
  required Offset footN,
  required Offset footF,
  required Offset handN,
  required Offset handF,
  Offset knee = const Offset(0.2, -1),
  Offset elbow = const Offset(1, -1),
  double head = 0,
  double toe = 90,
}) =>
    Pose(
      hip: Offset(hipX, hipY),
      torso: torso,
      head: head,
      footN: footN,
      footF: footF,
      kneeN: knee,
      kneeF: knee,
      handN: handN,
      handF: handF,
      elbowN: elbow,
      elbowF: elbow,
      toeN: toe,
      toeF: toe,
    );

MotionSpec _crunch() => MotionSpec((t) {
      final d = pingpong(t);
      final torso = lerpD(-90, -62, d);
      final sh = shoulderOf(const Offset(52, 85.5), torso);
      final hand = sh + dirOf(torso) * 9 - frontOf(torso) * 1;
      return _supine(
        torso: torso,
        head: lerpD(0, 12, d),
        footN: const Offset(68, ankleY),
        footF: const Offset(66, ankleY),
        handN: hand,
        handF: hand + const Offset(-1, 0),
      );
    });

MotionSpec _bicycle() => MotionSpec(
      (t) {
        const torso = -66.0;
        const hip = Offset(52, 85.5);
        final sh = shoulderOf(hip, torso);
        final hand = sh + dirOf(torso) * 9 - frontOf(torso);
        final s = swing(t);
        Offset leg(double k) =>
            lerpO(hip + const Offset(36, -9), hip + const Offset(11, -17), k);
        return _supine(
          torso: torso,
          head: 10,
          footN: leg(math.max(0, s)),
          footF: leg(math.max(0, -s)) + const Offset(-1.5, 0),
          handN: hand,
          handF: hand + const Offset(-1, 0),
          knee: const Offset(0.1, -1),
          toe: 60,
        );
      },
      period: const Duration(milliseconds: 1600),
      stillAt: 0.25,
    );

MotionSpec _legRaise({bool hanging = false}) => hanging
    ? MotionSpec((t) => _hang(0, legs: pingpong(t)), props: const [_pullBar])
    : MotionSpec((t) {
        final foot =
            const Offset(52, 86) + dirOf(lerpD(93, 2, pingpong(t))) * 38.5;
        return _supine(
          torso: -90,
          hipY: 86,
          footN: foot,
          footF: foot + const Offset(-1.5, 0.5),
          handN: const Offset(53, 89),
          handF: const Offset(51, 89),
          knee: const Offset(1, 0),
          elbow: const Offset(0, -1),
          toe: 40,
        );
      });

MotionSpec _hollowHold() => MotionSpec(
      (t) {
        final b = 0.6 * swing(t);
        const hip = Offset(52, 84);
        final torso = -78 + b;
        final sh = shoulderOf(hip, torso);
        final foot = hip + dirOf(72 - b) * 38.5;
        final hand = sh + dirOf(torso - 6) * 27;
        return _supine(
          torso: torso,
          hipY: 84,
          footN: foot,
          footF: foot + const Offset(-1.5, 0.5),
          handN: hand,
          handF: hand + const Offset(-1.5, 0),
          knee: const Offset(1, 0),
          elbow: const Offset(0, -1),
          toe: 60,
        );
      },
      period: _slow,
      stillAt: 0,
    );

MotionSpec _deadBug() => MotionSpec(
      (t) {
        const hip = Offset(52, 86);
        final sh = shoulderOf(hip, -90);
        final s = swing(t);
        final a = math.max(0.0, s), b = math.max(0.0, -s);
        Offset arm(double k) =>
            lerpO(sh + const Offset(2, -27), sh + dirOf(-102) * 27, k);
        Offset leg(double k) =>
            lerpO(hip + const Offset(19, -20), hip + dirOf(97) * 38, k);
        return _supine(
          torso: -90,
          hipY: 86,
          footN: leg(b),
          footF: leg(a) + const Offset(-1.5, 0),
          handN: arm(a),
          handF: arm(b) + const Offset(-1.5, 0),
          knee: const Offset(-0.3, -1),
          elbow: const Offset(0.3, -1),
          toe: 60,
        );
      },
      period: _slow,
      stillAt: 0.25,
    );

MotionSpec _russianTwist() => MotionSpec(
      (t) {
        // sitting back in a V with the feet hovering; the clasped hands
        // sweep from the floor beside the near hip, across the chest, to
        // the far hip (behind the body) and back
        const hip = Offset(44, 85.5);
        final s = swing(t); // +1 near side, -1 far side
        final torso = -36 + 5 * s;
        final sh = shoulderOf(hip, torso);
        final chest = sh + frontOf(torso) * 19 + const Offset(0, 8);
        const near = Offset(42, 88.5);
        const far = Offset(39, 79);
        final hand = s >= 0
            ? lerpO(chest, near, Curves.easeInOut.transform(s))
            : lerpO(chest, far, Curves.easeInOut.transform(-s));
        return Pose(
          hip: hip,
          torso: torso,
          head: 14,
          footN: const Offset(68, 82),
          footF: const Offset(66, 83),
          kneeN: const Offset(0.2, -1),
          kneeF: const Offset(0.2, -1),
          handN: hand,
          handF: hand + const Offset(-1.5, 0.5),
          elbowN: const Offset(0.2, 1),
          elbowF: const Offset(0.2, 1),
          toeN: 115,
          toeF: 115,
        );
      },
      period: const Duration(milliseconds: 2400),
      stillAt: 0.25,
    );

MotionSpec _superman() => MotionSpec((t) {
      final d = pingpong(t);
      const hip = Offset(44, 86);
      final torso = lerpD(90, 76, d);
      final sh = shoulderOf(hip, torso);
      final hand = sh + dirOf(lerpD(90, 80, d)) * 27;
      final foot = hip + dirOf(lerpD(-90, -78, d)) * 38.5;
      return Pose(
        hip: hip,
        torso: torso,
        head: -6 * d,
        footN: foot,
        footF: foot + const Offset(1, 1),
        kneeN: const Offset(0, 1),
        kneeF: const Offset(0, 1),
        handN: hand,
        handF: hand + const Offset(-1.5, 0.5),
        elbowN: const Offset(0, -1),
        elbowF: const Offset(0, -1),
        toeN: -100,
        toeF: -100,
      );
    });

MotionSpec _birdDog() => MotionSpec(
      (t) {
        const hip = Offset(40, 63);
        final sh = shoulderOf(hip, 90);
        final s = swing(t);
        final a = math.max(0.0, s), b = math.max(0.0, -s);
        Offset hand(double k, double back) =>
            lerpO(Offset(sh.dx - back, ankleY), sh + dirOf(84) * 27, k);
        Offset foot(double k, double back) =>
            lerpO(Offset(24 - back, ankleY), hip + dirOf(-86) * 38.5, k);
        return Pose(
          hip: hip,
          torso: 90,
          head: -12,
          footN: foot(b, 0),
          footF: foot(a, 1.5),
          kneeN: const Offset(0, 1),
          kneeF: const Offset(0, 1),
          handN: hand(a, 0),
          handF: hand(b, 2.5),
          elbowN: const Offset(-1, 0),
          elbowF: const Offset(-1, 0),
          toeN: lerpD(-100, 180, b),
          toeF: lerpD(-100, 180, a),
        );
      },
      period: const Duration(milliseconds: 3600),
      stillAt: 0.25,
    );

MotionSpec _donkeyKick() => MotionSpec((t) {
      final d = pingpong(t);
      const hip = Offset(40, 63);
      final sh = shoulderOf(hip, 90);
      return Pose(
        hip: hip,
        torso: 90,
        head: -12,
        footN: lerpO(const Offset(24, ankleY), hip + const Offset(-21, -20), d),
        footF: const Offset(22.5, ankleY),
        kneeN: lerpO(const Offset(0, 1), const Offset(-1, 0.4), d),
        kneeF: const Offset(0, 1),
        handN: Offset(sh.dx, ankleY),
        handF: Offset(sh.dx - 2.5, ankleY),
        elbowN: const Offset(-1, 0),
        elbowF: const Offset(-1, 0),
        toeN: lerpD(-100, -10, d),
        toeF: -100,
      );
    });

MotionSpec _pallof() => MotionSpec(
      (t) {
        // seen from the front, the cable tower to one side: the hands press
        // straight out toward the camera — the arms straighten and
        // foreshorten — while the cable tries to turn the torso
        final d = pingpong(t);
        final hand = lerpO(const Offset(50, 39), const Offset(50, 33), d);
        return _frontStand(
          handN: hand + const Offset(1.6, 0),
          handF: hand - const Offset(1.6, 0),
        ).copyWith(
          armScale: lerpD(1, 0.42, d),
          elbowN: const Offset(1, 0.8),
          elbowF: const Offset(-1, 0.8),
        );
      },
      frontView: true,
      props: [
        Slab((_) => const Offset(10, 10), (_) => const Offset(10, ground),
            width: 3.5),
        const Cable(Offset(10, 36)),
      ],
    );

// ---- feet, shoulders, carries -------------------------------------------------------

MotionSpec _calfRaise({bool machine = false}) => MotionSpec((t) {
      final d = pingpong(t, rest: 0.1, go: 0.3, hold: 0.15);
      final lift = 5 * d;
      final hip = Offset(50, standHipY - lift);
      final sh = shoulderOf(hip, 2);
      return Pose(
        hip: hip,
        torso: 2,
        footN: Offset(53, ankleY - lift),
        footF: Offset(49, ankleY - lift),
        handN: machine ? sh + const Offset(3, -1) : sh + const Offset(2, 27),
        handF:
            machine ? sh + const Offset(1.5, -1) : sh + const Offset(-0.5, 27),
        elbowN: machine ? const Offset(0.2, 1) : const Offset(-0.4, 1),
        elbowF: machine ? const Offset(0.2, 1) : const Offset(-0.4, 1),
        toeN: lerpD(90, 142, d),
        toeF: lerpD(90, 142, d),
      );
    }, props: [
      if (machine) ...[
        Slab((_) => const Offset(34, ground), (_) => const Offset(34, 14),
            width: 3),
        Slab((_) => const Offset(34, 18),
            (r) => r.shoulder + const Offset(0, -4),
            width: 3),
        Roller((r) => r.shoulder + const Offset(0, -4), radius: 4),
      ],
    ]);

MotionSpec _shrug({required Prop prop}) => MotionSpec((t) {
      final shrug = 4.5 * pingpong(t, rest: 0.1, go: 0.3, hold: 0.15);
      final sh = shoulderOf(_standHip, 2, shrug);
      return Pose(
        hip: _standHip,
        torso: 2,
        shrug: shrug,
        footN: _fN,
        footF: _fF,
        handN: sh + const Offset(1, 27),
        handF: sh + const Offset(-1, 27),
      );
    }, props: [prop]);

MotionSpec _carry() => MotionSpec(
      (t) {
        final ph = 2 * math.pi * t;
        final s = math.sin(ph), c = math.cos(ph);
        final hip = Offset(50, standHipY + 0.8 * s.abs());
        final sh = shoulderOf(hip, 2);
        return Pose(
          hip: hip,
          torso: 2,
          footN: Offset(52 + 7 * s, ankleY - 3.5 * math.max(0, c)),
          footF: Offset(49 - 7 * s, ankleY - 3.5 * math.max(0, -c)),
          handN: sh + const Offset(1, 27),
          handF: sh + const Offset(-1, 27),
        );
      },
      period: const Duration(milliseconds: 1100),
      props: const [Dumbbells(DumbbellStyle.along)],
    );

MotionSpec _jumpingJack() => MotionSpec(
      (t) {
        final d = pingpong(t, rest: 0.02, go: 0.46, hold: 0.02);
        final hop = 3 * math.sin(math.pi * d);
        final hip = Offset(50, standHipY - hop);
        final sh = shoulderOf(hip, 0);
        final a = lerpD(176, 12, d);
        return Pose(
          hip: hip,
          footN: Offset(54 + 13 * d, ankleY - hop),
          footF: Offset(46 - 13 * d, ankleY - hop),
          kneeN: const Offset(1, 0),
          kneeF: const Offset(-1, 0),
          handN: sh + const Offset(9, 0) + dirOf(a) * 27,
          handF: sh - const Offset(9, 0) + dirOf(-a) * 27,
          elbowN: const Offset(0.3, -1),
          elbowF: const Offset(-0.3, -1),
          toeN: 128,
          toeF: 128,
        );
      },
      frontView: true,
      period: const Duration(milliseconds: 1100),
    );

MotionSpec _deadHang() => MotionSpec(
      (t) => _hang(0, breath: 0.4 * swing(t)),
      period: _slow,
      props: const [_pullBar],
      stillAt: 0,
    );

// ---- registry ---------------------------------------------------------------------------

final Map<String, MotionSpec> _cache = {};

MotionSpec? _build(String id) => switch (id) {
      // squats & lunges
      'squat_bw' => _squatSpec(_Hold.reach),
      'goblet_squat' => _squatSpec(_Hold.goblet,
          props: const [Dumbbells(DumbbellStyle.vertical, far: false)]),
      'bb_squat' =>
        _squatSpec(_Hold.barbell, props: const [Plate(PlateAt.shoulders)]),
      'db_sumo_squat' => _squatSpec(_Hold.hang,
          sumo: true,
          props: const [Dumbbells(DumbbellStyle.vertical, far: false)]),
      'jump_squat' => _jumpSquat(),
      'wall_sit' => _wallSit(),
      'pistol_squat' => _pistol(),
      'hack_squat' => _hackSquat(),
      'leg_press' => _legPress(),
      'lunge_bw' => _lungeSpec(_Lunge.forward),
      'db_lunge' => _lungeSpec(_Lunge.forward, dumbbells: true),
      'reverse_lunge' => _lungeSpec(_Lunge.reverse),
      'db_split_squat' => _lungeSpec(_Lunge.split, dumbbells: true),
      'bulgarian_split_squat' => _lungeSpec(_Lunge.bulgarian),
      'db_stepup' => _stepUp(),
      'lateral_lunge' => _lateralLunge(),
      // hinges & bridges
      'db_rdl' => MotionSpec((t) => _rdl(pingpong(t)),
          props: const [Dumbbells(DumbbellStyle.along)]),
      'bb_deadlift' => _deadlift(),
      'db_single_leg_rdl' => _singleLegRdl(),
      'db_swing' => _swingSpec(),
      'back_extension' => _backExtension(),
      'nordic_curl' => _nordic(),
      'glute_bridge' => MotionSpec((t) => _bridge(pingpong(t))),
      'single_leg_bridge' =>
        MotionSpec((t) => _bridge(pingpong(t), single: true)),
      'db_hip_thrust' => _hipThrust(barbell: false),
      'bb_hip_thrust' => _hipThrust(barbell: true),
      'donkey_kick' => _donkeyKick(),
      // pushes
      'pushup' ||
      'wide_pushup' ||
      'diamond_pushup' ||
      'archer_pushup' =>
        _pushUp(),
      'knee_pushup' => _kneePushUp(),
      'decline_pushup' => _declinePushUp(),
      'pike_pushup' => _pikePushUp(),
      'bench_dip' => _benchDip(),
      'dip_bar' => _dip(),
      'db_bench_press' => _benchPress(barbell: false),
      'bb_bench_press' || 'close_grip_bench' => _benchPress(barbell: true),
      'db_incline_press' => _inclinePress(barbell: false),
      'bb_incline_press' => _inclinePress(barbell: true),
      'db_floor_press' => _floorPress(),
      'db_fly' => _flyTop(),
      'chest_press_machine' => _chestPressMachine(),
      'pec_deck' => _pecDeck(),
      'cable_fly_high' => _cableFly(),
      'db_shoulder_press' || 'arnold_press' => _shoulderPress(),
      'bb_overhead_press' => _shoulderPress(barbell: true),
      'machine_shoulder_press' => _shoulderPress(seated: true, machine: true),
      // raises
      'lateral_raise' => _lateralRaise(),
      'cable_lateral_raise' => _cableLateralRaise(),
      'db_front_raise' => _frontRaise(),
      'db_reverse_fly' => _reverseFlyBent(),
      'reverse_fly_machine' => _pecDeck(reverse: true),
      'face_pull' => _facePull(),
      // pulls
      'db_bentover_row' => MotionSpec((t) => _bentRow(pingpong(t)),
          props: const [Dumbbells(DumbbellStyle.along)]),
      'db_row_onearm' => MotionSpec(
            (t) => _bentRow(pingpong(t), torso: 72, oneArm: true),
            props: const [
              Bench(Offset(64, 65.5), Offset(92, 65.5)),
              Dumbbells(DumbbellStyle.along, far: false),
            ]),
      'bb_row' => MotionSpec((t) => _bentRow(pingpong(t), torso: 62),
          props: const [Plate(PlateAt.hands)]),
      'seated_cable_row' => _cableRow(),
      'inverted_row' => _invertedRow(),
      'pullup' => _pullUp(),
      'chin_up' => _pullUp(chin: true),
      'negative_pullup' => _pullUp(chin: true, negative: true),
      'dead_hang' => _deadHang(),
      'lat_pulldown' => _pulldown(),
      'straight_arm_pulldown' => _straightArmPulldown(),
      // arms
      'db_curl' => _curl(prop: const Dumbbells(DumbbellStyle.end)),
      'hammer_curl' => _curl(prop: const Dumbbells(DumbbellStyle.vertical)),
      'bb_curl' => _curl(prop: const Plate(PlateAt.hands)),
      'cable_curl' => _curl(prop: const Cable(Offset(80, 91))),
      'db_concentration_curl' => _concentrationCurl(),
      'db_overhead_ext' => _overheadExtension(rope: false),
      'overhead_rope_ext' => _overheadExtension(rope: true),
      'rope_pushdown' => _pushdown(),
      'db_kickback' => _kickback(),
      'db_skull_crusher' => _skullCrusher(),
      // core
      'plank' => _forearmPlank(),
      'side_plank' => _sidePlank(),
      'mountain_climber' => _mountainClimber(),
      'bear_crawl' => _bearCrawl(),
      'crunch' => _crunch(),
      'bicycle_crunch' => _bicycle(),
      'leg_raise' => _legRaise(),
      'hanging_leg_raise' => _legRaise(hanging: true),
      'hollow_hold' => _hollowHold(),
      'dead_bug' => _deadBug(),
      'russian_twist' => _russianTwist(),
      'superman' => _superman(),
      'bird_dog' => _birdDog(),
      'pallof_press' => _pallof(),
      // legs, shoulders, conditioning
      'leg_extension' => _legExtension(),
      'leg_curl' => _legCurl(),
      'hip_abduction' => _hipAbduction(),
      'calf_raise_bw' => _calfRaise(),
      'calf_raise_machine' => _calfRaise(machine: true),
      'db_shrug' => _shrug(prop: const Dumbbells(DumbbellStyle.along)),
      'bb_shrug' => _shrug(prop: const Plate(PlateAt.hands)),
      'db_farmer_carry' => _carry(),
      'jumping_jack' => _jumpingJack(),
      'burpee' => _burpee(),
      _ => null,
    };

/// Whether [id] has a hand-authored demo (not the generic fallback).
bool hasMotion(String id) => _build(id) != null;

/// The demo for an exercise; unknown ids get a calm standing breath.
MotionSpec motionFor(String id) => _cache.putIfAbsent(
      id,
      () =>
          _build(id) ??
          MotionSpec(
            (t) =>
                _stand().copyWith(hip: _standHip + Offset(0, 0.4 * swing(t))),
            period: _slow,
          ),
    );
