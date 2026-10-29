import 'package:flutter/material.dart';

import '../l10n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/plan_card.dart' show tierIcon;
import 'root.dart';

/// First-launch questionnaire: four functional questions (experience tier,
/// available equipment, age band, body areas to be careful with). Skippable.
/// Every answer maps to an executed rule — recommendations, availability
/// tags, rest adjustment, injury-aware substitution.

class OnboardingPage extends StatefulWidget {
  final bool reentry; // true when launched again from Settings
  const OnboardingPage({super.key, this.reentry = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _pages = 5;
  int _page = 0;
  int? _tier;
  int? _days;
  String? _equipment;
  String? _ageBand;
  List<String> _issues = [];

  @override
  void initState() {
    super.initState();
    final s = Store.instance.settings;
    _tier = s.userTier;
    _days = s.userDays;
    _equipment = s.userEquipment;
    _ageBand = s.ageBand;
    _issues = List.of(s.bodyIssues);
  }

  void _skip() => _finish(skipped: true);

  Future<void> _finish({bool skipped = false}) async {
    final s = Store.instance.settings;
    s.onboardingDone = true;
    if (!skipped) {
      s.userTier = _tier;
      s.userDays = _days;
      s.userEquipment = _equipment;
      s.ageBand = _ageBand;
      s.bodyIssues = _issues;
    }
    await Store.instance.save();
    if (!mounted) return;
    if (widget.reentry) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RootShell()));
    }
  }

  void _toggleIssue(String issue) {
    setState(() {
      if (issue == 'none') {
        _issues = const [];
        return;
      }
      _issues.remove('none');
      if (_issues.contains(issue)) {
        _issues.remove(issue);
      } else {
        _issues.add(issue);
      }
    });
  }

  bool get _canProceed => switch (_page) {
        0 => _tier != null,
        1 => _days != null,
        2 => _equipment != null,
        3 => _ageBand != null,
        _ => true, // issues: empty list = none, always allowed
      };

  @override
  Widget build(BuildContext context) {
    final onLastPage = _page == _pages - 1;
    const questions = ['obQ1', 'obQ5', 'obQ2', 'obQ3', 'obQ4'];
    // one friendly glyph per question, in a hue that walks the palette
    const questionIcons = [
      Icons.emoji_events_rounded,
      Icons.calendar_month_rounded,
      Icons.fitness_center_rounded,
      Icons.cake_rounded,
      Icons.healing_rounded,
    ];
    final qHue = [
      Iron.accent,
      Iron.tier(1),
      Iron.tier(2),
      Iron.tier(3),
      Iron.accent,
    ][_page];

    return Scaffold(
      backgroundColor: Iron.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBlob(Icons.fitness_center_rounded, size: 36),
                  const SizedBox(width: 10),
                  Text('IronPath', style: Iron.hero(20)),
                  const Spacer(),
                  TextButton(
                      onPressed: _skip, child: Text(L10n.t('obSkip'))),
                ],
              ),
              const SizedBox(height: 14),
              BarbellProgress(current: _page + 1, total: _pages),
              const SizedBox(height: 26),
              IconBlob(questionIcons[_page], color: qHue, size: 64),
              const SizedBox(height: 16),
              Text(L10n.t('obWelcome'), style: Iron.caption()),
              const SizedBox(height: 6),
              Text(L10n.t(questions[_page]), style: Iron.hero(26)),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    ...switch (_page) {
                      0 => [
                          for (final tier in [1, 2, 3])
                            _option(
                              label: L10n.t(switch (tier) {
                                1 => 'beginner',
                                2 => 'intermediate',
                                _ => 'advanced',
                              }),
                              icon: tierIcon(tier),
                              color: Iron.tier(tier),
                              selected: _tier == tier,
                              onTap: () => setState(() => _tier = tier),
                            ),
                        ],
                      1 => [
                          for (final d in [2, 3, 4, 5, 6])
                            _option(
                              label: L10n.t('obDays$d'),
                              icon: Icons.event_available_rounded,
                              color: Iron.tier(1),
                              selected: _days == d,
                              onTap: () => setState(() => _days = d),
                            ),
                        ],
                      2 => [
                          _option(
                            label: L10n.t('obEqNone'),
                            icon: Icons.accessibility_new_rounded,
                            color: Iron.tier(2),
                            selected: _equipment == 'none',
                            onTap: () => setState(() => _equipment = 'none'),
                          ),
                          _option(
                            label: L10n.t('obEqDumbbell'),
                            icon: Icons.fitness_center_rounded,
                            color: Iron.tier(2),
                            selected: _equipment == 'dumbbell',
                            onTap: () =>
                                setState(() => _equipment = 'dumbbell'),
                          ),
                          _option(
                            label: L10n.t('obEqGym'),
                            icon: Icons.storefront_rounded,
                            color: Iron.tier(2),
                            selected: _equipment == 'gym',
                            onTap: () => setState(() => _equipment = 'gym'),
                          ),
                        ],
                      3 => [
                          for (final band in ['young', 'mid', 'older'])
                            _option(
                              label: L10n.t(switch (band) {
                                'young' => 'obAgeYoung',
                                'mid' => 'obAgeMid',
                                _ => 'obAgeOlder',
                              }),
                              icon: switch (band) {
                                'young' => Icons.directions_run_rounded,
                                'mid' => Icons.self_improvement_rounded,
                                _ => Icons.elderly_rounded,
                              },
                              color: Iron.tier(3),
                              selected: _ageBand == band,
                              onTap: () => setState(() => _ageBand = band),
                            ),
                        ],
                      _ => [
                          _option(
                            label: L10n.t('issueNone'),
                            icon: Icons.sentiment_satisfied_rounded,
                            color: Iron.accent,
                            selected: _issues.isEmpty,
                            onTap: () => setState(() => _issues = []),
                          ),
                          for (final issue in [
                            'knee',
                            'shoulder',
                            'lower_back'
                          ])
                            _option(
                              label: L10n.t(switch (issue) {
                                'knee' => 'issueKnee',
                                'shoulder' => 'issueShoulder',
                                _ => 'issueLowerBack',
                              }),
                              icon: switch (issue) {
                                'knee' => Icons.directions_walk_rounded,
                                'shoulder' => Icons.accessibility_rounded,
                                _ => Icons.airline_seat_recline_normal_rounded,
                              },
                              color: Iron.danger,
                              selected: _issues.contains(issue),
                              onTap: () => _toggleIssue(issue),
                            ),
                        ],
                    },
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56)),
                        onPressed: () => setState(() => _page--),
                        child: Text(L10n.t('back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: IronButton(
                      label:
                          onLastPage ? L10n.t('obStart') : L10n.t('obNext'),
                      icon: onLastPage
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _canProceed
                          ? () {
                              if (onLastPage) {
                                _finish();
                              } else {
                                setState(() => _page++);
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChoiceTile(
        label: label,
        icon: icon,
        color: color,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
