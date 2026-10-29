import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ios_chrome.dart';
import '../utils.dart';
import '../weekly_program.dart';
import '../widgets/plan_card.dart';
import '../widgets/weekly_program_card.dart';
import 'plan_detail.dart';
import 'session_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback goLibrary;
  final ScrollController? scrollController;
  const HomeScreen({super.key, required this.goLibrary, this.scrollController});

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

    final done = program == null ? 0 : completedThisWeek(settings, logs);
    final total = program?.slots.length ?? 0;
    final Plan? today = program == null
        ? best
        : done < total
            ? program.slots[done]
            : null;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        largeTitleBar(L10n.t('homeHello'), trailing: null),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset(context)),
          sliver: SliverList.list(
            children: [
              // ---- date under the large title
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(fmtDayHeader(DateTime.now(), zh).toUpperCase(),
                    style: Iron.eyebrow()),
              ),

              // ---- today
              TodayCard(
                plan: today,
                dayIndex: done,
                done: done,
                total: total,
                recommended: program == null,
                onStart:
                    today == null ? null : () => _startPlan(context, today),
                onOpen: today == null ? null : () => _openPlan(context, today),
              ),

              if (program != null) ...[
                const SizedBox(height: 16),
                WeeklyProgramCard(
                  program: program,
                  done: done,
                  onOpen: (p) => _openPlan(context, p),
                ),
              ],

              // ---- last workout (day-14 retention hook)
              const SizedBox(height: 16),
              IronCard(
                padding: const EdgeInsets.all(14),
                radius: Iron.rM,
                child: Row(
                  children: [
                    IconBlob(Icons.history_rounded, color: Iron.tier(1)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L10n.t('lastWorkout'), style: Iron.caption()),
                          const SizedBox(height: 2),
                          Text(
                            logs.isEmpty
                                ? L10n.t('noWorkoutsYet')
                                : logs.first.planTitle(zh),
                            style: Iron.body(15, weight: FontWeight.w700),
                          ),
                          if (logs.isNotEmpty)
                            Text(
                                '${fmtDate(logs.first.startedAt)} · ${logs.first.doneSets()}/${logs.first.totalSets()} ${L10n.t('sets')}',
                                style: Iron.caption(color: Iron.faint)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ---- browse by tier
              const SizedBox(height: 22),
              SectionTitle(
                L10n.t('browseByLevel'),
                trailing: TextButton(
                    onPressed: widget.goLibrary,
                    child: Text(L10n.t('viewAll'))),
              ),
              for (final s in summaries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TierCard(
                    summary: s,
                    onStart: () => _startPlan(context, s.bestPlan),
                    onOpenLibrary: () => _openPlan(context, s.bestPlan),
                    recommended: best != null && s.tier == best.tier,
                  ),
                ),
              if (!adFree) ...[
                const SizedBox(height: 4),
                const _BannerPlaceholder(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _startPlan(BuildContext context, Plan plan) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => SessionScreen(plan: plan),
        ))
        .then((_) => refresh());
  }

  void _openPlan(BuildContext context, Plan plan) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => PlanDetailPage(plan: plan),
        ))
        .then((_) => refresh());
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Iron.cardHi,
        borderRadius: const BorderRadius.all(Iron.rM),
      ),
      child: Text('AdMob banner', style: Iron.caption(color: Iron.faint)),
    );
  }
}
