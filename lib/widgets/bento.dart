import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme.dart';

// Bento grid: tiles of different sizes that share edges and one gutter.
// A tile's size says how much it matters — one hero per screen, the
// supporting facts around it — and every row takes the height of its
// tallest tile, so larger text grows the grid instead of clipping it.

const double bentoGap = 10;

/// Tiles side by side, widths split by [flex], all as tall as the tallest.
class BentoRow extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flex;

  const BentoRow({super.key, required this.children, this.flex});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: bentoGap),
              Expanded(flex: flex?[i] ?? 1, child: children[i]),
            ],
          ],
        ),
      );
}

/// One tall tile beside a column of smaller ones that share its height:
///
///     [ lead | a ]
///     [      | b ]
class BentoSplit extends StatelessWidget {
  final Widget lead;
  final List<Widget> stack;
  final int leadFlex;
  final int stackFlex;

  const BentoSplit({
    super.key,
    required this.lead,
    required this.stack,
    this.leadFlex = 1,
    this.stackFlex = 1,
  });

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: leadFlex, child: lead),
            const SizedBox(width: bentoGap),
            Expanded(
              flex: stackFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < stack.length; i++) ...[
                    if (i > 0) const SizedBox(height: bentoGap),
                    Expanded(child: stack[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

/// A bento tile: tinted in [hue] (meaning: difficulty, progress) or the
/// plain card surface (information). Tappable when [onTap] is set.
class BentoTile extends StatelessWidget {
  final Widget child;
  final Color? hue;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Radius radius;

  const BentoTile({
    super.key,
    required this.child,
    this.hue,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = Iron.rL,
  });

  @override
  Widget build(BuildContext context) => IronCard(
        color: hue == null ? null : Iron.tint(hue!),
        radius: radius,
        padding: padding,
        onTap: onTap,
        child: child,
      );
}

/// The small label every tile opens with: an icon and a caption.
class BentoLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? hue;

  const BentoLabel(this.text, {super.key, this.icon, this.hue});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16, color: hue == null ? Iron.faint : Iron.inkOf(hue!)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Iron.caption()),
          ),
        ],
      );
}

/// A stat tile's contents: label on top, the value large at the bottom
/// (rolling into place when it changes), an optional note and extra line.
class BentoStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? hue; // value colour; matches the tile's tint
  final String? note;
  final Widget? extra;
  final double size;

  const BentoStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.hue,
    this.note,
    this.extra,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoLabel(label, icon: icon, hue: hue),
          SizedBox(height: size > 28 ? 14 : 8),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RollingText(value, style: Iron.hero(size, color: hue)),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: Iron.caption(color: Iron.faint)),
          ],
          if (extra != null) ...[
            const SizedBox(height: 10),
            extra!,
          ],
        ],
      );
}
