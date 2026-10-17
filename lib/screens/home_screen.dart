import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../weekly_program.dart';
import '../widgets/plan_card.dart';
import '../widgets/weekly_program_card.dart';
import 'session_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback goLibrary;
  const HomeScreen({super.key, required this.goLibrary});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final logs = Store.instance.logs;
    const adFree = false; // AdMob lands week 6-7; placeholder below.
    final summaries = tierSummaries();

    // Unified recommendation score across all builtin plans:
    //   equipment availability dominates (can you do it at all),
    //   then frequency fit (can you follow the weekly rhythm),
    //   then tier proximity (is it your level).
    // The badge lands on the tier of the best-scoring plan; each tier card
    // quick-starts its own best plan.
    final settings = Store.instance.settings;
    final program = deriveWeeklyProgram(settings);
    Plan? best;
    for (final s in summaries) {
      for (final p in s.plans) {
        if (best == null ||
            recommendationScore(p, settings) <
                recommendationScore(best, settings)) {
          best = p;
        }
      }
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('IronPath', style: Iron.hero(30)),
          SizedBox(height: 4),
          Text(L10n.t('offlinePitch'),
              style: Iron.caption(color: Iron.faint)),
          SizedBox(height: 20),
          if (program != null) ...[
            WeeklyProgramCard(program: program),
            SizedBox(height: 20),
          ],
          // Day-14 retention hook: last workout
          IronCard(
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: Iron.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L10n.t('lastWorkout'), style: Iron.caption()),
                      SizedBox(height: 3),
                      Text(
                        logs.isEmpty
                            ? L10n.t('noWorkoutsYet')
                            : '${fmtDate(logs.first.startedAt)} · ${logs.first.planTitle(zh)} · ${logs.first.doneSets()}/${logs.first.totalSets()}',
                        style: Iron.body(14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(L10n.t('quickStart'),
              style: Iron.body(17, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...summaries.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TierCard(
                  summary: s,
                  onStart: () => _startPlan(context, s.bestPlan),
                  onOpenLibrary: widget.goLibrary,
                  recommended: best != null && s.tier == best.tier,
                ),
              )),
          if (!adFree) ...[
            const SizedBox(height: 4),
            const _BannerPlaceholder(),
          ],
        ],
      ),
    );
  }

  void _startPlan(BuildContext context, Plan plan) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => SessionScreen(plan: plan),
        ))
        .then((_) => refresh());
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Iron.card,
        borderRadius: BorderRadius.all(Iron.rM),
      ),
      child: Text('AdMob banner', style: Iron.caption(color: Iron.faint)),
    );
  }
}
