import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme.dart';

// iOS-style chrome on top of the IronPath look: frosted bars, collapsing
// large titles, a translucent tab bar, sheets and action sheets. Colours
// and type still come from [Iron]; only structure and motion follow iOS.
// Components whose behaviour differs by platform convention (sheets,
// action sheets, menus, controls, bar buttons) are adaptive: Cupertino on
// Apple devices, the Material equivalent on Android and elsewhere.

/// Whether this build should follow Apple conventions. Reads the theme's
/// platform so tests (and a ThemeData override) can switch it.
bool isApple(BuildContext context) => switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

/// Blur whatever scrolls underneath and lay a translucent page colour on
/// top — the iOS "material" behind bars. [visibility] fades it in (0..1).
class Frosted extends StatelessWidget {
  final Widget child;
  final double visibility;
  final Color? color;
  final Border? border;

  const Frosted({
    super.key,
    required this.child,
    this.visibility = 1,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Iron.bg;
    final v = visibility.clamp(0.0, 1.0);
    return ClipRect(
      child: BackdropFilter(
        enabled: v > 0,
        filter: ImageFilter.blur(sigmaX: 24 * v, sigmaY: 24 * v),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.8 * v),
            border: border == null
                ? null
                : Border(
                    top: border!.top.copyWith(
                        color: border!.top.color
                            .withValues(alpha: border!.top.color.a * v)),
                    bottom: border!.bottom.copyWith(
                        color: border!.bottom.color
                            .withValues(alpha: border!.bottom.color.a * v)),
                  ),
          ),
          child: child,
        ),
      ),
    );
  }
}

BorderSide get _hairline => BorderSide(color: Iron.line, width: 0.5);

/// A piece of glass (iOS 26/27 "Liquid Glass", approximated): whatever is
/// behind it shows through blurred under a translucent tint, with a bright
/// edge toward the light and a darkened edge away from it — the edges iOS
/// 27 sharpened so glass stays legible over busy content. Any [shape].
class GlassSurface extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;
  final Color? tint;
  final EdgeInsets padding;
  final bool shadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.tint,
    this.padding = EdgeInsets.zero,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Iron.isDark;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: shadow
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.32 : 0.1),
                    blurRadius: 22,
                    offset: const Offset(0, 8)),
              ]
            : null,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: (tint ?? Iron.card).withValues(alpha: dark ? 0.6 : 0.66),
              shape: shape,
            ),
            child: CustomPaint(
              foregroundPainter: _GlassEdge(shape, dark),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEdge extends CustomPainter {
  final ShapeBorder shape;
  final bool dark;
  _GlassEdge(this.shape, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect.deflate(0.6));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.32 : 0.8),
            Colors.white.withValues(alpha: dark ? 0.06 : 0.18),
            Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassEdge old) => old.shape != shape || old.dark != dark;
}

/// A round glass button for bar actions (back, close, settings): the way
/// iOS 26 floats toolbar buttons over content instead of filling a bar.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String label;
  final double size;
  final Color? color;

  const GlassIconButton(this.icon,
      {super.key,
      required this.onPressed,
      required this.label,
      this.size = 38,
      this.color});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          onPressed: onPressed,
          child: ExcludeSemantics(
            child: SizedBox(
              width: size,
              height: size,
              child: GlassSurface(
                shape: const CircleBorder(),
                child: Center(
                    child: Icon(icon,
                        size: size * 0.55, color: color ?? Iron.ink)),
              ),
            ),
          ),
        ),
      );
}

/// Large title for a tab page: big on top, collapses into a small centred
/// title in a frosted bar as the list scrolls (iOS "large title" bar).
Widget largeTitleBar(String title, {Widget? trailing, Widget? leading}) =>
    CupertinoSliverNavigationBar(
      largeTitle: Text(title),
      leading: leading,
      trailing: trailing,
      backgroundColor: Iron.bg.withValues(alpha: 0.8),
      border: Border(bottom: _hairline),
      // four tab bars live in one route; hero flights between them would
      // collide, and tabs never push one another anyway
      transitionBetweenRoutes: false,
      automaticallyImplyLeading: false,
      padding: const EdgeInsetsDirectional.only(start: 20, end: 12),
    );

/// Bottom padding a tab page needs so its last item clears the floating
/// tab bar and the home indicator.
double bottomInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + 24;

/// Translucent iOS tab bar: icon over a short label, accent when active,
/// content blurs underneath (the Scaffold must use `extendBody: true`).
class IronTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData icon, IconData active, String label)> items;

  const IronTabBar(
      {super.key,
      required this.index,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    if (isApple(context)) {
      // iOS 26: the tab bar is a capsule of glass floating over the
      // content, the selected tab marked by a pill that slides between
      // items; the page keeps scrolling underneath
      final bottom = MediaQuery.paddingOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, math.max(bottom, 10) + 4),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: SizedBox(
            height: 62,
            child: GlassSurface(
              padding: const EdgeInsets.all(4),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth / items.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: Motion.of(context, Motion.snappy.duration),
                        curve: Motion.snappy,
                        left: w * index,
                        top: 0,
                        bottom: 0,
                        width: w,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: Iron.tint(Iron.accent),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(child: _item(i, reduced, glass: true)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
    return Frosted(
      color: Iron.card,
      border: Border(top: _hairline),
      child: SafeArea(
        top: false,
        // tab labels stay near their designed size, as on iOS: the bar is
        // a fixed 54 pt and the label is a hint under the icon
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(child: _item(i, reduced)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, bool reduced, {bool glass = false}) {
    final (icon, activeIcon, label) = items[i];
    final active = i == index;
    final color =
        active ? Iron.inkOf(Iron.accent) : (glass ? Iron.sub : Iron.faint);
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkResponse(
        onTap: () => onTap(i),
        radius: 32,
        highlightShape: BoxShape.rectangle,
        containedInkWell: glass,
        customBorder: glass ? const StadiumBorder() : null,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SF Symbols-style bounce when a tab becomes active
              TweenAnimationBuilder<double>(
                key: ValueKey(active),
                tween: Tween(begin: active && !reduced ? 0.78 : 1.0, end: 1.0),
                duration: Motion.bouncy.duration,
                curve: Motion.bouncy,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Icon(active ? activeIcon : icon, size: 25, color: color),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: Iron.caption(color: color, weight: FontWeight.w800)
                      .copyWith(fontSize: 10.5, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back button: iOS chevron on Apple, Material arrow elsewhere (both go
/// through maybePop, so PopScope still applies).
class IronBackButton extends StatelessWidget {
  const IronBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isApple(context)) {
      return IconButton(
        icon: Icon(Icons.arrow_back, color: Iron.ink),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GlassIconButton(
        CupertinoIcons.chevron_back,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Pushed-page scaffold with an iOS nav bar: transparent over the top of
/// the content, frosting over once content scrolls under it; the title
/// fades in after [revealTitleAt] px (or is always shown). [builder]
/// receives the insets its scroll view must pad by (bar + safe areas).
class IronPage extends StatefulWidget {
  final String title;
  final bool titleAlways;
  final double revealTitleAt;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottomBar;
  final Widget Function(BuildContext context, EdgeInsets insets) builder;

  const IronPage({
    super.key,
    required this.title,
    required this.builder,
    this.titleAlways = false,
    this.revealTitleAt = 90,
    this.leading,
    this.actions = const [],
    this.bottomBar,
  });

  @override
  State<IronPage> createState() => _IronPageState();
}

class _IronPageState extends State<IronPage> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      _offset.value = n.metrics.pixels;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      backgroundColor: Iron.bg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: ValueListenableBuilder<double>(
          valueListenable: _offset,
          builder: (context, off, _) {
            final under = (off / 12).clamp(0.0, 1.0);
            final titleT = widget.titleAlways
                ? 1.0
                : ((off - widget.revealTitleAt) / 28).clamp(0.0, 1.0);
            return Frosted(
              visibility: under,
              border: Border(bottom: _hairline),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 48,
                  child: NavigationToolbar(
                    leading: widget.leading ??
                        (canPop ? const IronBackButton() : null),
                    middle: Opacity(
                      opacity: titleT,
                      child: Transform.translate(
                        offset: Offset(0, 6 * (1 - titleT)),
                        child: Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Iron.body(17, weight: FontWeight.w800)),
                      ),
                    ),
                    trailing: widget.actions.isEmpty
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.actions),
                    middleSpacing: 8,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Builder(
          builder: (context) =>
              widget.builder(context, MediaQuery.paddingOf(context)),
        ),
      ),
      bottomNavigationBar: widget.bottomBar,
    );
  }
}

/// Text-style bar button (iOS "Cancel" / "Save").
class BarTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bold;

  const BarTextButton(this.label,
      {super.key, this.onPressed, this.bold = false});

  @override
  Widget build(BuildContext context) {
    if (!isApple(context)) {
      return TextButton(
        onPressed: onPressed,
        child: Text(label,
            style: Iron.body(15,
                color: Iron.accent,
                weight: bold ? FontWeight.w800 : FontWeight.w700)),
      );
    }
    // iOS 26: bar buttons sit in capsules — the one primary action
    // (bold) filled in the accent, the others as glass
    final text = Text(label,
        style: Iron.body(15,
            color: bold ? Iron.onAccent : Iron.ink,
            weight: bold ? FontWeight.w800 : FontWeight.w700));
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: SizedBox(
        height: 36,
        child: bold
            ? DecoratedBox(
                decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: Iron.inkOf(Iron.accent)),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(widthFactor: 1, child: text)),
              )
            : GlassSurface(
                shadow: false,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(widthFactor: 1, child: text),
              ),
      ),
    );
  }
}

/// Card sheet. Apple: iOS sheet — the page behind shrinks back, drag down
/// to dismiss. Elsewhere: Material modal bottom sheet with a drag handle.
/// [builder] gets the sheet's scroll controller so scrolling and
/// drag-to-dismiss cooperate.
Future<T?> showIronSheet<T>(
  BuildContext context,
  Widget Function(BuildContext context, ScrollController controller) builder,
) {
  if (!isApple(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, controller) => builder(context, controller),
      ),
    );
  }
  return showCupertinoSheet<T>(
    context: context,
    showDragHandle: true,
    scrollableBuilder: (context, controller) => Material(
      color: Iron.bg,
      child: builder(context, controller),
    ),
  );
}

/// Header row for a sheet: cancel on the left, title centred, action right.
class SheetHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const SheetHeader(
      {super.key, required this.title, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
      child: SizedBox(
        height: 44,
        child: NavigationToolbar(
          leading: leading,
          middle: Text(title, style: Iron.body(17, weight: FontWeight.w800)),
          trailing: trailing,
        ),
      ),
    );
  }
}

/// One choice in an action sheet.
class SheetAction<T> {
  final String label;
  final T value;
  final bool destructive;
  final bool isDefault;
  const SheetAction(this.label, this.value,
      {this.destructive = false, this.isDefault = false});
}

/// Choice prompt; resolves to the picked value, or null on cancel / tap
/// outside. Apple: iOS action sheet. Elsewhere: a single action becomes a
/// Material confirmation dialog, several become a bottom-sheet menu.
Future<T?> showIronActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<SheetAction<T>> actions,
  required String cancelLabel,
}) {
  if (!isApple(context)) {
    if (actions.length == 1) {
      final a = actions.single;
      return showDialog<T>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: title == null ? null : Text(title),
          content: message == null ? null : Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(cancelLabel)),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: a.destructive
                      ? Iron.inkOf(Iron.danger)
                      : Iron.inkOf(Iron.accent)),
              onPressed: () => Navigator.pop(ctx, a.value),
              child: Text(a.label),
            ),
          ],
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child:
                    Text(title, style: Iron.body(16, weight: FontWeight.w800)),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(message, style: Iron.caption()),
              ),
            for (final a in actions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(a.label,
                    style: Iron.body(16,
                        color: a.destructive ? Iron.danger : Iron.ink,
                        weight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, a.value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: title == null
          ? null
          : Text(title, style: Iron.caption(weight: FontWeight.w800)),
      message: message == null ? null : Text(message, style: Iron.caption()),
      actions: [
        for (final a in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: a.destructive,
            isDefaultAction: a.isDefault,
            onPressed: () => Navigator.pop(ctx, a.value),
            child: Text(a.label,
                style: Iron.body(18,
                    color: a.destructive ? Iron.danger : Iron.accent,
                    weight: a.isDefault ? FontWeight.w800 : FontWeight.w600)),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(cancelLabel,
            style: Iron.body(18, color: Iron.accent, weight: FontWeight.w800)),
      ),
    ),
  );
}
