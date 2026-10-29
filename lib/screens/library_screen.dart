import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/plan_card.dart';
import 'plan_detail.dart';
import 'plan_editor.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openDetail(Plan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanDetailPage(plan: plan)),
    );
    refresh();
  }

  Future<void> _newPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanEditorPage()),
    );
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final custom = Store.instance.customPlans;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(L10n.t('tabLibrary'), style: Iron.hero(28)),
          const SizedBox(height: 16),

          // ---- my plans first: they're the ones people come back to
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
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
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
              child: PlanCard(plan: p, onTap: () => _openDetail(p)),
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
                child: PlanCard(plan: p, onTap: () => _openDetail(p)),
              ),
          ],
        ],
      ),
    );
  }
}
