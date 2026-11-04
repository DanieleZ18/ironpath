import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../weekly_program.dart' show recommendationScore;
import '../widgets/bento.dart';
import '../widgets/ios_chrome.dart';
import '../widgets/plan_card.dart';
import 'plan_detail.dart';
import 'plan_editor.dart';
import 'session_screen.dart';

class LibraryScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const LibraryScreen({super.key, this.scrollController});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  void refresh() {
    if (mounted) setState(() {});
  }

  /// Zooms the detail page out of the plan's card ([source]).
  Future<void> _openDetail(BuildContext source, Plan plan) async {
    await openPlanDetail(source, plan, radius: Iron.rM.x, color: Iron.card);
    refresh();
  }

  Future<void> _start(Plan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          // a workout is a modal task: it slides up full screen
          fullscreenDialog: true,
          builder: (_) => SessionScreen(plan: plan)),
    );
    refresh();
  }

  /// The plan's quick actions, shared by both long-press menus:
  /// (label, Cupertino icon, Material icon, action, destructive).
  List<(String, IconData, IconData, VoidCallback, bool)> _menuEntries(
          Plan p, BuildContext source) =>
      [
        (
          L10n.t('startWorkout'),
          CupertinoIcons.play_fill,
          Icons.play_arrow_rounded,
          () => _start(p),
          false
        ),
        (
          L10n.t('viewDetails'),
          CupertinoIcons.doc_text,
          Icons.description_outlined,
          () => _openDetail(source, p),
          false
        ),
        if (p.builtin)
          (
            L10n.t('copyPlan'),
            CupertinoIcons.doc_on_doc,
            Icons.copy_rounded,
            () {
              Store.instance.customPlans.add(p.copyAsCustom(
                  'custom_${DateTime.now().millisecondsSinceEpoch}'));
              Store.instance.save();
              refresh();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(L10n.t('copyDone'))));
            },
            false
          )
        else ...[
          (
            L10n.t('editPlan'),
            CupertinoIcons.pencil,
            Icons.edit_outlined,
            () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PlanEditorPage(existing: p)));
              refresh();
            },
            false
          ),
          (
            L10n.t('deletePlan'),
            CupertinoIcons.delete,
            Icons.delete_outline,
            () {
              Store.instance.customPlans.removeWhere((x) => x.id == p.id);
              Store.instance.save();
              refresh();
            },
            true
          ),
        ],
      ];

  /// Plan card with a long-press menu. Apple: iOS context menu (the card
  /// lifts over a blurred page). Elsewhere: Material popup menu at the
  /// press point.
  Widget _withMenu(Plan p) => Builder(builder: (source) {
        final card =
            PlanCard(plan: p, onTap: (source) => _openDetail(source, p));
        final entries = _menuEntries(p, source);
        if (!isApple(context)) {
          return GestureDetector(
            onLongPressStart: (d) async {
              HapticFeedback.mediumImpact();
              final pos = d.globalPosition;
              final size = MediaQuery.sizeOf(context);
              final i = await showMenu<int>(
                context: context,
                position: RelativeRect.fromLTRB(
                    pos.dx, pos.dy, size.width - pos.dx, size.height - pos.dy),
                items: [
                  for (var k = 0; k < entries.length; k++)
                    PopupMenuItem(
                      value: k,
                      child: Row(
                        children: [
                          Icon(entries[k].$3,
                              size: 20,
                              color: entries[k].$5 ? Iron.danger : Iron.sub),
                          const SizedBox(width: 12),
                          Text(entries[k].$1,
                              style: Iron.body(15,
                                  color: entries[k].$5 ? Iron.danger : Iron.ink,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              );
              if (i != null) entries[i].$4();
            },
            child: card,
          );
        }
        return CupertinoContextMenu(
          actions: [
            for (final (label, icon, _, action, destructive) in entries)
              CupertinoContextMenuAction(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss the menu first
                  action();
                },
                isDestructiveAction: destructive,
                trailingIcon: icon,
                child: Text(label,
                    style: Iron.body(16,
                        color: destructive ? Iron.danger : Iron.ink,
                        weight: FontWeight.w600)),
              ),
          ],
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width - 40,
            child: card,
          ),
        );
      });

  Future<void> _newPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanEditorPage()),
    );
    refresh();
  }

  /// Zooms a tier's best plan out of its tile.
  void _openTier(BuildContext source, TierSummary s) =>
      openPlanDetail(source, s.bestPlan,
              radius: Iron.rL.x, color: Iron.tint(Iron.tier(s.tier)))
          .then((_) => refresh());

  @override
  Widget build(BuildContext context) {
    final custom = Store.instance.customPlans;
    final settings = Store.instance.settings;
    final summaries = tierSummaries();
    // the level that fits the onboarding answers leads, full width; the
    // other two sit beneath as half tiles
    TierSummary? lead;
    for (final s in summaries) {
      for (final p in s.plans) {
        if (lead == null ||
            recommendationScore(p, settings) <
                recommendationScore(lead.bestPlan, settings)) {
          lead = s;
        }
      }
    }
    lead ??= summaries.first;
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        largeTitleBar(L10n.t('tabLibrary'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _newPlan,
              child: Icon(CupertinoIcons.add_circled_solid,
                  size: 28, color: Iron.inkOf(Iron.accent)),
            )),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset(context)),
          sliver: SliverList.list(
            children: [
              // ---- by level: the recommended tier, then the other two
              TierCard(
                summary: lead,
                onStart: () => _start(lead!.bestPlan),
                onOpen: (card) => _openTier(card, lead!),
                recommended: true,
              ),
              const SizedBox(height: bentoGap),
              BentoRow(children: [
                for (final s in summaries.where((s) => s != lead))
                  TierCard(
                    summary: s,
                    compact: true,
                    onStart: () => _start(s.bestPlan),
                    onOpen: (card) => _openTier(card, s),
                  ),
              ]),

              // ---- my plans: the ones people come back to
              const SizedBox(height: 22),
              SectionTitle(L10n.t('myPlans'),
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 10)),
              IronCard(
                onTap: _newPlan,
                color: Iron.tint(Iron.accent),
                radius: Iron.rM,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Iron.accent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Icon(Icons.add_rounded, color: Iron.onAccent),
                    ),
                    const SizedBox(width: 14),
                    Text(L10n.t('newPlan'),
                        style: Iron.body(16,
                            weight: FontWeight.w800, color: Iron.accent)),
                  ],
                ),
              ),
              for (final p in custom)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _withMenu(p),
                ),

              // ---- builtin, grouped by tier
              for (final tier in [1, 2, 3]) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Row(
                    children: [
                      IronPill(tierLabel(tier),
                          color: Iron.tier(tier),
                          icon: tierIcon(tier),
                          solid: true),
                      const Spacer(),
                      Text(
                          L10n.tf(
                              'plansCount',
                              Store.instance.builtin
                                  .where((p) => p.tier == tier)
                                  .length),
                          style: Iron.caption(color: Iron.faint)),
                    ],
                  ),
                ),
                for (final p
                    in Store.instance.builtin.where((p) => p.tier == tier))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _withMenu(p),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
