import 'package:flutter/material.dart';

import '../l10n.dart';
import '../store.dart';
import '../theme.dart';
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

    return Scaffold(
      backgroundColor: Iron.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('IronPath', style: Iron.hero(22)),
                  const Spacer(),
                  TextButton(
                      onPressed: _skip, child: Text(L10n.t('obSkip'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _pages; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < _pages - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i <= _page ? Iron.accent : Iron.cardHi,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(L10n.t('obWelcome'), style: Iron.caption()),
              const SizedBox(height: 24),
              Text(
                L10n.t(['obQ1', 'obQ5', 'obQ2', 'obQ3', 'obQ4'][_page]),
                style: Iron.hero(26, weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ...switch (_page) {
                      0 => [
                          for (final tier in [1, 2, 3])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _optionCard(
                                label: L10n.t(switch (tier) {
                                  1 => 'beginner',
                                  2 => 'intermediate',
                                  _ => 'advanced',
                                }),
                                dot: Iron.tierColor[tier] ?? Iron.sub,
                                selected: _tier == tier,
                                onTap: () => setState(() => _tier = tier),
                              ),
                            ),
                        ],
                      1 => [
                          for (final d in [2, 3, 4, 5, 6])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _optionCard(
                                label: L10n.t(switch (d) {
                                  2 => 'obDays2',
                                  3 => 'obDays3',
                                  4 => 'obDays4',
                                  _ => 'obDays5',
                                }),
                                icon: Icons.event_available,
                                selected: _days == d,
                                onTap: () => setState(() => _days = d),
                              ),
                            ),
                        ],
                      2 => [
                          _optionCard(
                            label: L10n.t('obEqNone'),
                            icon: Icons.accessibility_new,
                            selected: _equipment == 'none',
                            onTap: () =>
                                setState(() => _equipment = 'none'),
                          ),
                          _gap(),
                          _optionCard(
                            label: L10n.t('obEqDumbbell'),
                            icon: Icons.fitness_center,
                            selected: _equipment == 'dumbbell',
                            onTap: () =>
                                setState(() => _equipment = 'dumbbell'),
                          ),
                          _gap(),
                          _optionCard(
                            label: L10n.t('obEqGym'),
                            icon: Icons.storefront_outlined,
                            selected: _equipment == 'gym',
                            onTap: () => setState(() => _equipment = 'gym'),
                          ),
                        ],
                      3 => [
                          for (final band in ['young', 'mid', 'older'])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _optionCard(
                                label: L10n.t(switch (band) {
                                  'young' => 'obAgeYoung',
                                  'mid' => 'obAgeMid',
                                  _ => 'obAgeOlder',
                                }),
                                icon: switch (band) {
                                  'young' => Icons.directions_run,
                                  'mid' => Icons.self_improvement,
                                  _ => Icons.elderly,
                                },
                                selected: _ageBand == band,
                                onTap: () => setState(() => _ageBand = band),
                              ),
                            ),
                        ],
                      _ => [
                          _optionCard(
                            label: L10n.t('issueNone'),
                            icon: Icons.check_circle_outline,
                            selected: _issues.isEmpty,
                            onTap: () => setState(() => _issues = []),
                          ),
                          _gap(),
                          for (final issue in [
                            'knee',
                            'shoulder',
                            'lower_back'
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _optionCard(
                                label: L10n.t(switch (issue) {
                                  'knee' => 'issueKnee',
                                  'shoulder' => 'issueShoulder',
                                  _ => 'issueLowerBack',
                                }),
                                icon: switch (issue) {
                                  'knee' => Icons.healing,
                                  'shoulder' => Icons.accessibility,
                                  _ => Icons.airline_seat_recline_normal,
                                },
                                selected: _issues.contains(issue),
                                onTap: () => _toggleIssue(issue),
                              ),
                            ),
                        ],
                    },
                  ],
                ),
              ),
              IronButton(
                label: onLastPage ? L10n.t('obStart') : L10n.t('obNext'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 10);

  Widget _optionCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? dot,
  }) {
    return Material(
      color: selected ? Iron.accent.withValues(alpha: 0.12) : Iron.card,
      borderRadius: const BorderRadius.all(Iron.rM),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Iron.rM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Iron.rM),
            border: Border.all(
              color: selected ? Iron.accent : Iron.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: dot,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(5))),
                ),
                const SizedBox(width: 12),
              ],
              if (icon != null) ...[
                Icon(icon,
                    size: 20,
                    color: selected ? Iron.accent : Iron.sub),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(label,
                    style: Iron.body(15,
                        weight:
                            selected ? FontWeight.w600 : FontWeight.normal)),
              ),
              if (selected) Icon(Icons.check, size: 18, color: Iron.accent),
            ],
          ),
        ),
      ),
    );
  }
}