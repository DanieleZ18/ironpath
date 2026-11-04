import 'dart:math' as math;
import 'dart:ui';

// Shape helpers for the exercise figure: body segments drawn as smooth
// tapered silhouettes (a profile of half-widths along each bone, with a
// muscle belly where the muscle is), and muscle regions that sit inside
// them. Everything is in the 100 × 100 design units of the rig.

/// Half-widths of a body segment along its length, on its two sides
/// ([a] and [b]), sampled evenly from the root (t = 0) to the end (t = 1)
/// and blended smoothly between samples.
class Profile {
  final List<double> a, b;
  const Profile(this.a, this.b);

  /// The same half-width on both sides.
  const Profile.even(List<double> w)
      : a = w,
        b = w;

  static double _at(List<double> v, double t) {
    final n = v.length - 1;
    final x = t.clamp(0.0, 1.0) * n;
    final i = math.min(x.floor(), n - 1);
    final s = x - i;
    return v[i] + (v[i + 1] - v[i]) * (s * s * (3 - 2 * s));
  }

  double wa(double t) => _at(a, t);
  double wb(double t) => _at(b, t);
}

double _dot(Offset p, Offset q) => p.dx * q.dx + p.dy * q.dy;

Offset unit(Offset v, [Offset fallback = const Offset(0, 1)]) {
  final d = v.distance;
  return d < 1e-6 ? fallback : v / d;
}

/// A body segment from [p0] to [p1] with its profile's side `a` turned
/// toward [aSide] (for a thigh: the front of the leg).
class Segment {
  final Offset p0, p1;
  final Profile profile;
  final Offset u; // unit direction p0 → p1
  final Offset n; // unit normal toward side a
  final double len;

  Segment._(this.p0, this.p1, this.profile, this.u, this.n, this.len);

  factory Segment(Offset p0, Offset p1, Profile profile, {Offset? aSide}) {
    final d = p1 - p0;
    final u = unit(d);
    var n = Offset(-u.dy, u.dx);
    if (aSide != null && _dot(n, aSide) < 0) n = -n;
    return Segment._(p0, p1, profile, u, n, d.distance);
  }

  Offset at(double t) => p0 + u * (len * t);

  /// The segment's silhouette, rounded at both ends.
  Path outline({int steps = 10}) {
    final pa = <Offset>[], pb = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final c = at(t);
      pa.add(c + n * profile.wa(t));
      pb.add(c - n * profile.wb(t));
    }
    final end = _cap(at(1), u, n, profile.wa(1), profile.wb(1));
    final start = _cap(at(0), -u, -n, profile.wb(0), profile.wa(0));
    return smoothClosed([...pa, ...end, ...pb.reversed, ...start]);
  }

  /// A muscle on one side of the segment: from that side's edge inward by
  /// [depth] (1 = to the centre line, 2 = across to the far edge), swelling
  /// from a point at [t0] to a point at [t1] like a muscle belly. [inset]
  /// keeps a sliver of skin tone along the edge.
  Path region({
    required bool onA,
    required double t0,
    required double t1,
    double depth = 1,
    double inset = 0.35,
    int steps = 10,
  }) {
    final side = onA ? n : -n;
    final outer = <Offset>[], inner = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = t0 + (t1 - t0) * i / steps;
      final c = at(t);
      final w = onA ? profile.wa(t) : profile.wb(t);
      final other = onA ? profile.wb(t) : profile.wa(t);
      final env = math.pow(math.sin(math.pi * i / steps), 0.6).toDouble();
      final reach = math.min(
          depth <= 1 ? w * depth : w + other * (depth - 1), w + other - inset);
      final edge = math.max(0.0, w - inset);
      outer.add(c + side * edge);
      inner.add(c + side * (edge - (reach - inset) * env));
    }
    return smoothClosed([...outer, ...inner.reversed]);
  }
}

/// Half an ellipse from `c + side·w1` round through `c + dir·r` to
/// `c − side·w2` (the end cap of a segment), as intermediate points.
List<Offset> _cap(Offset c, Offset dir, Offset side, double w1, double w2) {
  final r = (w1 + w2) / 2;
  return [
    for (var k = 1; k < 6; k++)
      c +
          dir * (r * math.sin(math.pi * k / 6)) +
          side *
              ((math.cos(math.pi * k / 6) >= 0 ? w1 : w2) *
                  math.cos(math.pi * k / 6)),
  ];
}

/// A closed curve through (the midpoints between) [p]: each point is the
/// control of a quadratic segment, so corners come out round.
Path smoothClosed(List<Offset> p) {
  final path = Path();
  final n = p.length;
  if (n < 3) return path;
  Offset mid(int i) => (p[i % n] + p[(i + 1) % n]) / 2;
  final m0 = mid(0);
  path.moveTo(m0.dx, m0.dy);
  for (var i = 1; i <= n; i++) {
    final c = p[i % n];
    final m = mid(i);
    path.quadraticBezierTo(c.dx, c.dy, m.dx, m.dy);
  }
  return path..close();
}

/// An ellipse centred on [c] with radius [ru] along [u] and [rv] across.
Path ellipse(Offset c, Offset u, double ru, double rv, {int steps = 20}) {
  final a = unit(u);
  final v = Offset(-a.dy, a.dx);
  return smoothClosed([
    for (var i = 0; i < steps; i++)
      c +
          a * (ru * math.cos(2 * math.pi * i / steps)) +
          v * (rv * math.sin(2 * math.pi * i / steps)),
  ]);
}

/// The unit normal of the line a → b that points toward [other] (any point
/// off the line), or the one closest to [fallback] when [other] is too
/// close to the line to tell (a straight limb).
Offset sideToward(Offset a, Offset b, Offset other, Offset fallback) {
  final u = unit(b - a);
  final n = Offset(-u.dy, u.dx);
  final v = other - b;
  final s = _dot(n, v);
  if (s.abs() < 0.15 * v.distance || v.distance < 1e-6) {
    return _dot(n, fallback) >= 0 ? n : -n;
  }
  return s > 0 ? n : -n;
}
