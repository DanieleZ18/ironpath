import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ios_chrome.dart';
import '../utils.dart';
import '../weekly_program.dart';
import '../widgets/bento.dart';
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

    final done = completedThisWeek(settings, logs);
    final total = program?.slots.length ?? 0;
    final Plan? today = program == null
        ? best
        : done < total
            ? program.slots[done]
            : null;
    final lead = summaries.firstWhere((s) => s.tier == best?.tier,
        orElse: () => summaries.first);

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
                onOpen: today == null
                    ? null
                    : (card) => _openPlan(card, today,
                        radius: Iron.rXL.x,
                        color: Iron.tint(Iron.tier(today.tier))),
              ),

              // ---- this week and the last workout, side by side
              const SizedBox(height: bentoGap),
              BentoRow(children: [
                BentoTile(
                  hue: Iron.accent,
                  child: BentoStat(
                    icon: Icons.calendar_month_rounded,
                    label: L10n.t('statThisWeek'),
                    value: total > 0 ? '$done/$total' : '$done',
                    hue: Iron.accent,
                    size: 30,
                    note: total > 0 ? null : L10n.t('statSessions'),
                    extra: total > 0
                        ? SetDots(done: done, total: total, size: 10)
                        : null,
                  ),
                ),
                BentoTile(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BentoLabel(L10n.t('lastWorkout'),
                          icon: Icons.history_rounded),
                      const SizedBox(height: 8),
                      const Spacer(),
                      Text(
                        logs.isEmpty
                            ? L10n.t('noWorkoutsYet')
                            : logs.first.planTitle(zh),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Iron.body(15, weight: FontWeight.w800),
                      ),
                      if (logs.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                            '${fmtDayHeader(logs.first.startedAt, zh)} · ${logs.first.doneSets()}/${logs.first.totalSets()} ${L10n.t('sets')}',
                            style: Iron.caption(color: Iron.faint)),
                      ],
                    ],
                  ),
                ),
              ]),

              if (program != null) ...[
                const SizedBox(height: bentoGap),
                WeeklyProgramCard(
                  program: program,
                  done: done,
                  onOpen: (row, p) =>
                      _openPlan(row, p, radius: Iron.rM.x, color: Iron.card),
                ),
              ],

              // ---- browse by tier: the recommended level full width, the
              // other two as half tiles beneath
              const SizedBox(height: 22),
              SectionTitle(
                L10n.t('browseByLevel'),
                trailing: TextButton(
                    onPressed: widget.goLibrary,
                    child: Text(L10n.t('viewAll'))),
              ),
              TierCard(
                summary: lead,
                onStart: () => _startPlan(context, lead.bestPlan),
                onOpen: (card) => _openPlan(card, lead.bestPlan,
                    radius: Iron.rL.x, color: Iron.tint(Iron.tier(lead.tier))),
                recommended: true,
              ),
              const SizedBox(height: bentoGap),
              BentoRow(children: [
                for (final s in summaries.where((s) => s != lead))
                  TierCard(
                    summary: s,
                    compact: true,
                    onStart: () => _startPlan(context, s.bestPlan),
                    onOpen: (card) => _openPlan(card, s.bestPlan,
                        radius: Iron.rL.x, color: Iron.tint(Iron.tier(s.tier))),
                  ),
              ]),
              const SizedBox(height: 12),
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
          // a workout is a modal task: it slides up full screen
          fullscreenDialog: true,
          builder: (_) => SessionScreen(plan: plan),
        ))
        .then((_) => refresh());
  }

  /// Zooms the plan's detail page out of the card that was tapped.
  void _openPlan(BuildContext source, Plan plan,
      {required double radius, required Color color}) {
    openPlanDetail(source, plan, radius: radius, color: color)
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
