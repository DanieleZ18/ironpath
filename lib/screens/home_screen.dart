import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../training_stats.dart';
import '../utils.dart';
import '../weekly_program.dart';
import '../widgets/bento.dart';
import '../widgets/ios_chrome.dart';
import '../widgets/muscle_glyph.dart';
import '../widgets/plan_card.dart';
import '../widgets/weekly_program_card.dart';
import 'plan_detail.dart';
import 'session_screen.dart';
import 'settings_screen.dart';

/// Today: the one workout to do now, and how the week is going. Plans and
/// exercises live in their own tabs; settings sit behind the gear.
class HomeScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const HomeScreen({super.key, this.scrollController});

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
    final settings = Store.instance.settings;
    final program = deriveWeeklyProgram(settings);

    // without a weekly program (skipped onboarding) the hero recommends the
    // best-scoring plan across all tiers
    Plan? best;
    for (final s in tierSummaries()) {
      for (final p in s.plans) {
        if (best == null ||
            recommendationScore(p, settings) <
                recommendationScore(best, settings)) {
          best = p;
        }
      }
    }

    final now = DateTime.now();
    final done = completedThisWeek(settings, logs, now: now);
    final total = program?.slots.length ?? 0;
    final Plan? today = program == null
        ? best
        : done < total
            ? program.slots[done]
            : null;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        largeTitleBar(
          L10n.t('tabToday'),
          trailing: isApple(context)
              ? GlassIconButton(CupertinoIcons.gear,
                  label: L10n.t('tabSettings'), onPressed: _openSettings)
              : IconButton(
                  icon: Icon(Icons.settings_outlined, color: Iron.ink),
                  tooltip: L10n.t('tabSettings'),
                  onPressed: _openSettings),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset(context)),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(fmtDayHeader(now, zh).toUpperCase(),
                    style: Iron.eyebrow()),
              ),
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
              const SizedBox(height: bentoGap),
              WeekStrip(
                program: program,
                logs: logs,
                now: now,
                onOpenPlan: (row, p) =>
                    _openPlan(row, p, radius: Iron.rM.x, color: Iron.card),
              ),
              const SizedBox(height: bentoGap),
              _WeekMuscles(logs: logs, now: now),
              // the ad slot shows in debug builds only until AdMob lands
              if (!adFree && kDebugMode) ...[
                const SizedBox(height: 18),
                const _BannerPlaceholder(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
    refresh();
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

/// The week as seven columns: a check for each day trained, a dot on
/// today, hollow rings for the sessions still to come. Tap for the
/// day-by-day plan.
class WeekStrip extends StatelessWidget {
  final WeeklyProgram? program;
  final List<SessionLog> logs;
  final DateTime now;
  final void Function(BuildContext source, Plan plan) onOpenPlan;

  const WeekStrip({
    super.key,
    required this.program,
    required this.logs,
    required this.now,
    required this.onOpenPlan,
  });

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final start = weekStartOf(now);
    final trained = List<bool>.filled(7, false);
    for (final l in logs) {
      if (l.startedAt.isBefore(start)) continue;
      final i = l.startedAt.difference(start).inDays;
      if (i >= 0 && i < 7) trained[i] = true;
    }
    final done = completedThisWeek(Store.instance.settings, logs, now: now);
    final total = program?.slots.length ?? 0;
    final today = now.weekday - 1;
    final streak = weekStreak(logs, now: now);
    // the sessions left this week are pencilled onto the days still to come
    var remaining = (total - done).clamp(0, 7);
    final planned = List<bool>.filled(7, false);
    for (var i = today; i < 7 && remaining > 0; i++) {
      if (trained[i]) continue;
      planned[i] = true;
      remaining--;
    }
    return BentoTile(
      onTap: program == null ? null : () => _showWeek(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(L10n.t('weekStrip'),
                    style: Iron.body(16, weight: FontWeight.w800)),
              ),
              if (streak >= 2) ...[
                IronPill(L10n.tf('streakWeeks', streak),
                    color: Iron.tier(3),
                    icon: Icons.local_fire_department_rounded),
                const SizedBox(width: 10),
              ],
              Text(total > 0 ? '$done / $total' : '$done',
                  style: Iron.body(16,
                      weight: FontWeight.w800, color: Iron.accent)),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: L10n.t('weekStrip'),
            value: total > 0
                ? L10n.tf('weekProgress', '$done/$total')
                : L10n.tf('sessionsN', done),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      children: [
                        _dot(trained[i], planned[i], i == today),
                        const SizedBox(height: 6),
                        Text(fmtWeekdayShort(i + 1, zh),
                            style: Iron.caption(
                                color: i == today ? Iron.ink : Iron.faint,
                                weight: i == today
                                    ? FontWeight.w800
                                    : FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool trained, bool planned, bool today) {
    final accent = Iron.inkOf(Iron.accent);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: trained ? accent : Colors.transparent,
        border: Border.all(
          color: trained
              ? accent
              : planned
                  ? accent.withValues(alpha: 0.5)
                  : Iron.line,
          width: planned && !trained ? 2 : 1.5,
        ),
      ),
      child: trained
          ? Icon(Icons.check_rounded,
              size: 14, color: Iron.isDark ? Iron.bg : Colors.white)
          : today
              ? Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: accent))
              : null,
    );
  }

  /// The day-by-day plan, as a sheet.
  void _showWeek(BuildContext context) {
    final p = program!;
    final done = completedThisWeek(Store.instance.settings, logs, now: now);
    showIronSheet<void>(
      context,
      (sheet, controller) => Column(
        children: [
          SheetHeader(
            title: L10n.t('weeklyPlan'),
            trailing: BarTextButton(L10n.t('done'),
                bold: true, onPressed: () => Navigator.of(sheet).pop()),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                  20, 4, 20, 24 + MediaQuery.paddingOf(sheet).bottom),
              children: [
                WeeklyProgramCard(
                  program: p,
                  done: done,
                  onOpen: (row, plan) {
                    Navigator.of(sheet).pop();
                    onOpenPlan(context, plan);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: Iron.cardHi,
        shape: Iron.squircle(Iron.rM),
      ),
      child: Text('AdMob banner', style: Iron.caption(color: Iron.faint)),
    );
  }
}

/// This week's training as a muscle map: which muscles got work so far,
/// and how much (Strava's muscle map, Fitbod's recovery view).
class _WeekMuscles extends StatelessWidget {
  final List<SessionLog> logs;
  final DateTime now;
  const _WeekMuscles({required this.logs, required this.now});

  @override
  Widget build(BuildContext context) {
    final week = logsThisWeek(logs, now: now).toList();
    final shade = setsPerMuscle(week);
    final top = musclesBySets(week, 4);
    return BentoTile(
      child: Row(
        children: [
          MuscleMap(sets: shade, full: 8, height: 124, onTint: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BentoLabel(L10n.t('thisWeekMuscles'),
                    icon: Icons.accessibility_new_rounded),
                const SizedBox(height: 10),
                if (top.isEmpty)
                  Text(L10n.t('noMusclesYet'), style: Iron.caption())
                else
                  for (final m in top)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(L10n.muscle(m.key),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Iron.body(14, weight: FontWeight.w700)),
                          ),
                          Text(L10n.tf('setsDone', m.value),
                              style: Iron.caption(color: Iron.faint)),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
