import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Apple-style appearance change: snapshot the current frame, apply the new
/// theme underneath, then dissolve the snapshot away. Used for light/dark,
/// colour theme and language switches.
class ThemeCrossfade extends StatefulWidget {
  final Widget child;
  const ThemeCrossfade({super.key, required this.child});

  /// Runs [change] behind a crossfade — or instantly when Reduce Motion is
  /// on or no crossfade host is above [context].
  static Future<void> run(BuildContext context, VoidCallback change) async {
    final host = context.findAncestorStateOfType<ThemeCrossfadeState>();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (host == null || reduced) {
      change();
      return;
    }
    await host.crossfade(change);
  }

  @override
  State<ThemeCrossfade> createState() => ThemeCrossfadeState();
}

class ThemeCrossfadeState extends State<ThemeCrossfade>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final Animation<double> _opacity = Tween(begin: 1.0, end: 0.0)
      .animate(CurvedAnimation(parent: _fade, curve: Curves.easeInOut));
  ui.Image? _shot;
  bool _busy = false;

  Future<void> crossfade(VoidCallback change) async {
    final boundary = _boundary.currentContext?.findRenderObject();
    // already capturing or fading: just apply, the running dissolve covers
    // it (a second snapshot would race the first)
    if (boundary is! RenderRepaintBoundary || _busy) {
      change();
      return;
    }
    _busy = true;
    try {
      await _run(boundary, change);
    } finally {
      _busy = false;
    }
  }

  Future<void> _run(RenderRepaintBoundary boundary, VoidCallback change) async {
    final ui.Image image;
    try {
      image =
          await boundary.toImage(pixelRatio: View.of(context).devicePixelRatio);
    } catch (_) {
      change();
      return;
    }
    if (!mounted) {
      image.dispose();
      change();
      return;
    }
    setState(() => _shot = image);
    change();
    await _fade.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _shot?.dispose();
      _shot = null;
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    _shot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shot = _shot;
    return Stack(
      fit: StackFit.expand,
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (shot != null)
          IgnorePointer(
            child: FadeTransition(
              opacity: _opacity,
              child: RawImage(image: shot, fit: BoxFit.fill),
            ),
          ),
      ],
    );
  }
}
