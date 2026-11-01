import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/widgets.dart';

// Motion tokens. Apple's motion is springs, not easing curves: a spring
// has a natural period (response) and a damping fraction, and its
// duration falls out of those. Motion here answers what the user did —
// press, open, confirm, change — and steps aside when the system asks for
// reduced motion.

/// A spring as a [Curve], parameterised like SwiftUI's
/// `.spring(response:dampingFraction:)`. Use [duration] as the animation
/// duration so the curve plays to rest. Underdamped springs overshoot 1 —
/// fine for scale and position, never use them for opacity.
class SpringCurve extends Curve {
  /// Seconds for one undamped oscillation (lower = snappier).
  final double response;

  /// 1 = no overshoot, lower = more bounce.
  final double dampingFraction;

  const SpringCurve({this.response = 0.4, this.dampingFraction = 0.82});

  double get _omega => 2 * math.pi / response;

  /// Time for the spring to settle within 0.1% of its target.
  Duration get duration {
    final zeta = dampingFraction.clamp(0.1, 1.0);
    final seconds = math.log(1000) / (zeta * _omega);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  double transformInternal(double t) {
    final w = _omega;
    final z = dampingFraction;
    final time = t * duration.inMicroseconds / 1e6;
    if (z >= 1) {
      return 1 - math.exp(-w * time) * (1 + w * time);
    }
    final wd = w * math.sqrt(1 - z * z);
    return 1 -
        math.exp(-z * w * time) *
            (math.cos(wd * time) + (z * w / wd) * math.sin(wd * time));
  }
}

abstract final class Motion {
  /// Presses, toggles, small state changes.
  static const snappy = SpringCurve(response: 0.3, dampingFraction: 0.86);

  /// Layout and surfaces settling into place.
  static const smooth = SpringCurve(response: 0.45, dampingFraction: 1.0);

  /// Celebratory pops (a completed set, the finish check).
  static const bouncy = SpringCurve(response: 0.5, dampingFraction: 0.62);

  /// The system's Reduce Motion / Remove animations setting.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero under reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Press feedback: the child sinks slightly while touched and springs back
/// on release, the way iOS cards and buttons respond. Listens to raw
/// pointers, so it never competes with the child's own tap handling;
/// moving past touch slop (a scroll) releases it.
class Pressable extends StatefulWidget {
  final Widget child;
  final double scale;
  final bool enabled;

  const Pressable({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.enabled = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset? _origin;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || Motion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_down && (e.position - _origin!).distance > kTouchSlop) {
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        // sink quickly, release on a spring
        duration:
            _down ? const Duration(milliseconds: 110) : Motion.snappy.duration,
        curve: _down ? Curves.easeOut : Motion.snappy,
        child: widget.child,
      ),
    );
  }
}

/// Text whose changing characters roll into place — iOS's numeric content
/// transition. Digits are matched from the right so "10:00" → "9:59" keeps
/// alignment. [down] rolls new digits in from above (counting down).
class RollingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool down;

  const RollingText(this.text,
      {super.key, required this.style, this.down = false});

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return Text(text, style: style);
    final chars = text.characters.toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final incoming =
                  child.key == ValueKey('${chars.length - i}${chars[i]}');
              final dir = (down ? -1.0 : 1.0) * (incoming ? 1 : -1);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position:
                      Tween(begin: Offset(0, 0.45 * dir), end: Offset.zero)
                          .animate(anim),
                  child: child,
                ),
              );
            },
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [...previous, if (current != null) current],
            ),
            // keyed by position-from-right + glyph: only changed digits roll
            child: Text(chars[i],
                key: ValueKey('${chars.length - i}${chars[i]}'), style: style),
          ),
      ],
    );
  }
}

/// A number that counts up to [value] the first time it appears and rolls
/// to new values afterwards. [format] turns the animated value into text.
class CountUp extends StatelessWidget {
  final double value;
  final String Function(double v) format;
  final TextStyle style;
  final Duration delay;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    required this.format,
    required this.style,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return Text(format(value), style: style);
    final total = delay + duration;
    final lead = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: total,
      curve: Interval(lead, 1, curve: Curves.easeOutCubic),
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}
