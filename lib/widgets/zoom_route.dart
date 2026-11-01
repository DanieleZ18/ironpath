import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../theme.dart';
import 'ios_chrome.dart' show isApple;

/// Opens [page] by zooming it out of the widget that owns [source] — the
/// iOS 18 zoom transition, which is Material's container transform on
/// Android. The card the user tapped becomes the page; closing it zooms
/// the page back into the card. Under Reduce Motion it cross-fades instead.
Future<T?> openZoomed<T>(
  BuildContext source,
  WidgetBuilder page, {
  double radius = 24,
  Color? color,
}) {
  final nav = Navigator.of(source);
  final box = source.findRenderObject();
  final navBox = nav.context.findRenderObject();
  if (Motion.reduced(source) ||
      box is! RenderBox ||
      !box.hasSize ||
      navBox is! RenderBox) {
    return nav.push<T>(_FadeRoute<T>(builder: page));
  }
  final rect = box.localToGlobal(Offset.zero, ancestor: navBox) & box.size;
  return nav.push<T>(ZoomPageRoute<T>(
    builder: page,
    sourceRect: rect,
    sourceRadius: radius,
    sourceColor: color,
  ));
}

class ZoomPageRoute<T> extends PageRoute<T> {
  ZoomPageRoute({
    required this.builder,
    required this.sourceRect,
    this.sourceRadius = 24,
    this.sourceColor,
    super.settings,
  });

  final WidgetBuilder builder;

  /// Where the tapped card sits, in navigator coordinates.
  final Rect sourceRect;
  final double sourceRadius;

  /// The card's surface colour — the page grows out of it.
  final Color? sourceColor;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 560);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 460);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      Semantics(
          scopesRoute: true, explicitChildNodes: true, child: builder(context));

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      _ZoomTransition(route: this, animation: animation, child: child);

  /// The page underneath recedes a little and dims while this one opens.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _recede;

  static Widget? _recede(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      bool allowSnapshotting,
      Widget? child) {
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(secondaryAnimation.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            // what shows around the receding page: the page colour, dimmed
            // like the page itself (not the app's black sheet backdrop)
            ColoredBox(color: Color.lerp(Iron.bg, Colors.black, 0.14 * t)!),
            Transform.scale(scale: 1 - 0.04 * t, child: child),
            IgnorePointer(
              child:
                  ColoredBox(color: Colors.black.withValues(alpha: 0.14 * t)),
            ),
          ],
        );
      },
    );
  }

  // ---- interactive dismissal (iOS edge swipe), driven like Cupertino's
  // back gesture: the finger scrubs the route's own animation

  void _dragStart() {
    if (!popGestureEnabled) return;
    navigator?.didStartUserGesture();
  }

  void _dragUpdate(double fraction) {
    if (!popGestureInProgress) return;
    controller!.value = (controller!.value - fraction).clamp(0.0, 1.0);
  }

  void _dragEnd(double velocity) {
    if (!popGestureInProgress) return;
    final c = controller!;
    final nav = navigator!;
    // velocity in screen widths per second, positive = toward closing
    final close = velocity > 1.0 || (velocity > -1.0 && c.value < 0.6);
    if (close) {
      nav.pop();
    } else {
      c.forward();
    }
    if (c.isAnimating) {
      late final AnimationStatusListener done;
      done = (_) {
        nav.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      nav.didStopUserGesture();
    }
  }
}

class _ZoomTransition extends StatefulWidget {
  final ZoomPageRoute<dynamic> route;
  final Animation<double> animation;
  final Widget child;

  const _ZoomTransition(
      {required this.route, required this.animation, required this.child});

  @override
  State<_ZoomTransition> createState() => _ZoomTransitionState();
}

class _ZoomTransitionState extends State<_ZoomTransition>
    with WidgetsBindingObserver {
  // after a gesture, the rest of that transition stays linear so the page
  // doesn't jump when the curve would kick back in
  bool _linear = false;
  double _pull = 0; // iOS pull-down overscroll, for pull-to-dismiss
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scroll notifications can arrive mid-layout; defer the rebuild then.
  void _setPull(double v) {
    if (v == _pull) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pull = v);
      });
    } else {
      setState(() => _pull = v);
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s.isCompleted || s.isDismissed) _linear = false;
  }

  // ---- Android predictive back: the system gesture scrubs the zoom

  bool get _predictive => !isApple(context);

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    if (!_predictive ||
        backEvent.isButtonEvent ||
        !route.isCurrent ||
        !route.popGestureEnabled) {
      return false;
    }
    route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (widget.route.popGestureInProgress) {
      widget.route
          .handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    }
  }

  @override
  void handleCancelBackGesture() {
    if (widget.route.popGestureInProgress) {
      widget.route.handleCancelBackGesture();
    }
  }

  @override
  void handleCommitBackGesture() {
    if (widget.route.popGestureInProgress) {
      widget.route.handleCommitBackGesture();
    }
  }

  // ---- iOS pull-down to dismiss (App Store card style)

  bool _onScroll(ScrollNotification n) {
    if (!isApple(context) || n.depth != 0) return false;
    if (n is ScrollUpdateNotification) {
      final overscroll = -n.metrics.pixels + n.metrics.minScrollExtent;
      if (n.dragDetails != null) {
        _setPull(overscroll.clamp(0.0, 200.0));
        _armed = overscroll > 90;
      } else if (_armed && widget.route.isCurrent) {
        // finger lifted while pulled far enough
        _armed = false;
        HapticFeedback.lightImpact();
        Navigator.of(context).maybePop();
      }
    } else if (n is ScrollEndNotification) {
      _setPull(0);
    }
    return false;
  }

  double _progress() {
    final a = widget.animation;
    if (widget.route.popGestureInProgress) _linear = true;
    if (_linear) return a.value;
    final apple = isApple(context);
    final reversing = a.status == AnimationStatus.reverse;
    final Curve curve = reversing
        ? (apple
            ? const SpringCurve(response: 0.42, dampingFraction: 1)
            : Easing.emphasizedAccelerate)
        : (apple
            ? const SpringCurve(response: 0.5, dampingFraction: 0.88)
            : Easing.emphasizedDecelerate);
    return curve.transform(a.value);
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final apple = isApple(context);
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      final full = Offset.zero & size;
      return AnimatedBuilder(
        animation: widget.animation,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        builder: (context, child) {
          final p = _progress();
          final q = p.clamp(0.0, 1.0);
          final rect = Rect.lerp(route.sourceRect, full, p)!;
          // pulling down on iOS shrinks the page and rounds its corners, a
          // preview of it zooming back into the card
          final pull = apple ? (_pull / 160).clamp(0.0, 1.0) : 0.0;
          final radius = lerpDouble(route.sourceRadius, 0, q)! + 30 * pull;
          final scale = rect.width / size.width;
          // the card's surface fills the growing shape first, then the
          // page's content fades in on top of it
          final fill = const Interval(0, 0.18).transform(q);
          final content = const Interval(0.08, 0.42).transform(q);
          final surface = Color.lerp(route.sourceColor ?? Iron.card, Iron.bg,
              const Interval(0, 0.7).transform(q))!;
          final settled =
              widget.animation.isCompleted && !route.popGestureInProgress;
          return Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  ignoring: !settled,
                  child: Transform.scale(
                    scale: 1 - 0.08 * pull,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      clipBehavior:
                          settled && pull == 0 ? Clip.none : Clip.antiAlias,
                      child: ColoredBox(
                        color: surface.withValues(alpha: fill),
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minWidth: size.width,
                          maxWidth: size.width,
                          minHeight: size.height,
                          maxHeight: size.height,
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.topCenter,
                            child: Opacity(opacity: content, child: child),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // iOS: drag from the left edge to zoom the page back
              if (apple && settled || apple && route.popGestureInProgress)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 20,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) => route._dragStart(),
                    onHorizontalDragUpdate: (d) =>
                        route._dragUpdate(d.primaryDelta! / size.width),
                    onHorizontalDragEnd: (d) => route
                        ._dragEnd(d.velocity.pixelsPerSecond.dx / size.width),
                    onHorizontalDragCancel: () => route._dragEnd(0),
                  ),
                ),
            ],
          );
        },
      );
    });
  }
}

/// Reduce Motion: a plain cross-fade instead of zooming.
class _FadeRoute<T> extends PageRoute<T> {
  _FadeRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      FadeTransition(opacity: animation, child: child);
}
