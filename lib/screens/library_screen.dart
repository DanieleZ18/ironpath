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
        padding: const EdgeInsets.all(16),
        children: [
          for (final tier in [1, 2, 3]) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Iron.tierColor[tier] ?? Iron.sub,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4))),
                  ),
                  SizedBox(width: 8),
                  Text(tierLabel(tier),
                      style: Iron.body(16, weight: FontWeight.w600)),
                ],
              ),
            ),
            for (final p
                in Store.instance.builtin.where((p) => p.tier == tier))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PlanCard(plan: p, onTap: () => _openDetail(p)),
              ),
          ],
          SizedBox(height: 10),
          Text(L10n.t('myPlans'),
              style: Iron.body(16, weight: FontWeight.w600)),
          SizedBox(height: 8),
          Material(
            color: Iron.card,
            borderRadius: const BorderRadius.all(Iron.rM),
            child: InkWell(
              onTap: _newPlan,
              borderRadius: const BorderRadius.all(Iron.rM),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 18, color: Iron.accent),
                    SizedBox(width: 10),
                    Text(L10n.t('newPlan'), style: Iron.body(14)),
                  ],
                ),
              ),
            ),
          ),
          for (final p in custom)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PlanCard(plan: p, onTap: () => _openDetail(p)),
            ),
        ],
      ),
    );
  }
}
