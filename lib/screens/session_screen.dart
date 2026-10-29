import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/muscle_glyph.dart';
import '../utils.dart';
import '../data/tips.dart';
import 'exercise_detail_screen.dart';

enum _Phase { exercise, rest, finished }

/// The heart of the app. One soft block per set, a thick rest ring, and
/// the plan's tier hue carried through every phase.

class SessionScreen extends StatefulWidget {
  final Plan plan;
  const SessionScreen({super.key, required this.plan});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final DateTime _startedAt = DateTime.now();
  final TextEditingController _weightCtrl = TextEditingController();

  int _itemIdx = 0;
  int _setIdx = 0;
  _Phase _phase = _Phase.exercise;
  int _restRemaining = 0;
  int _restTotal = 0;
  int _restCount = 0; // which rest we're on — rotates the tip
  Timer? _timer;
  int _durationSeconds = 0; // frozen at finish, matches the saved log
  final List<ItemLog> _log = [];

  Plan get plan => widget.plan;
  Color get _hue => Iron.tier(plan.builtin ? plan.tier : 0);
  PlanItem get _item => plan.items[_itemIdx];

  /// 55+ users recover slower: every rest is 30s longer (locked rule).
  int get _effectiveRest =>
      _item.restSeconds + (Store.instance.settings.ageBand == 'older' ? 30 : 0);

  @override
  void initState() {
    super.initState();
    if (plan.items.isEmpty) {
      // nothing to play: leave before touching plan.items[0]
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    // screen stays on for the whole workout; best-effort — browsers may
    // refuse the wake lock, which must not surface as an uncaught error
    WakelockPlus.enable().catchError((Object _) {});
    _prefillWeight();
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    _timer?.cancel();
    _weightCtrl.dispose();
    super.dispose();
  }

  double? _lastWeightShown;

  /// Prefill from this session's earlier sets, else from stored history.
  void _prefillWeight() {
    double? w;
    outer:
    for (final item in _log.reversed) {
      if (item.exerciseId != _item.exerciseId) continue;
      for (var i = item.sets.length - 1; i >= 0; i--) {
        if (item.sets[i].weight != null) {
          w = item.sets[i].weight;
          break outer;
        }
      }
    }
    w ??= Store.instance.lastWeightFor(_item.exerciseId);
    _lastWeightShown = w;
    _weightCtrl.text = w == null ? '' : fmtWeight(w);
  }

  /// Alert sound + haptic when the rest timer expires on its own.
  void _restEndFeedback() {
    if (!Store.instance.settings.feedbackOn) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  /// Short tick during the last 3 seconds of rest.
  void _countdownTick() {
    if (!Store.instance.settings.feedbackOn) return;
    SystemSound.play(SystemSoundType.click);
  }

  void _completeSet() {
    final weight =
        double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    if (_log.length <= _itemIdx) {
      _log.add(ItemLog(exerciseId: _item.exerciseId, sets: const []));
    }
    final current = _log[_itemIdx];
    _log[_itemIdx] = ItemLog(
      exerciseId: current.exerciseId,
      sets: [
        ...current.sets,
        SetLog(index: _setIdx, done: true, weight: weight),
      ],
    );
    _weightCtrl.clear();
    final lastSet =
        _setIdx + 1 >= _item.sets && _itemIdx + 1 >= plan.items.length;
    if (lastSet) {
      // no rest after the final set: log right away so a quit can't lose it
      _finish();
    } else {
      _startRest(_effectiveRest);
    }
  }

  void _startRest(int seconds) {
    setState(() {
      _phase = _Phase.rest;
      _restRemaining = seconds;
      _restTotal = seconds;
      _restCount++;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) {
          _restEndFeedback();
          _advance();
        } else if (_restRemaining <= 3) {
          _countdownTick(); // 3-2-1 warning beeps
        }
      });
    });
  }

  /// Nudge the weight field by [delta] kg (never below zero).
  void _bumpWeight(double delta) {
    final cur =
        double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ??
            _lastWeightShown ??
            0;
    final next = (cur + delta).clamp(0, 999).toDouble();
    setState(() => _weightCtrl.text = fmtWeight(next));
  }

  void _addRest() {
    setState(() {
      _restRemaining += 15;
      _restTotal += 15;
    });
  }

  void _advance() {
    _timer?.cancel();
    if (_setIdx + 1 < _item.sets) {
      setState(() {
        _setIdx++;
        _phase = _Phase.exercise;
      });
      _prefillWeight();
    } else if (_itemIdx + 1 < plan.items.length) {
      setState(() {
        _itemIdx++;
        _setIdx = 0;
        _phase = _Phase.exercise;
      });
      _prefillWeight();
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    final log = SessionLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      planId: plan.id,
      planTitleEn: plan.titleEn,
      planTitleZh: plan.titleZh,
      startedAt: _startedAt,
      durationSeconds: DateTime.now().difference(_startedAt).inSeconds,
      items: List.of(_log),
    );
    Store.instance.logs.insert(0, log);
    Store.instance.save();
    setState(() {
      _durationSeconds = log.durationSeconds;
      _phase = _Phase.finished;
    });
  }

  Future<bool> _confirmQuit() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.t('giveUp')),
        content: Text(L10n.t('giveUpBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.t('stay')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Iron.inkOf(Iron.danger),
                minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L10n.t('quit')),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    if (plan.items.isEmpty) return Scaffold(backgroundColor: Iron.bg);
    return PopScope(
      canPop: _phase == _Phase.finished,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final quit = await _confirmQuit();
        if (quit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Iron.bg,
        appBar: AppBar(
          automaticallyImplyLeading: _phase == _Phase.finished,
          leading: _phase == _Phase.finished
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
          title: Text(
            _phase == _Phase.finished ? '' : plan.title(L10n.zh),
            style: Iron.body(16, weight: FontWeight.w800),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // fade + a slight rise/scale: each set and rest feels like a card
          // being dealt, without moving far enough to distract
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.0).animate(anim),
              child: SlideTransition(
                position:
                    Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                        .animate(anim),
                child: child,
              ),
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey('$_phase-$_itemIdx-$_setIdx'),
            child: switch (_phase) {
              _Phase.exercise => _buildExercise(context),
              _Phase.rest => _buildRest(context),
              _Phase.finished => _buildFinished(context),
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- exercise

  Widget _buildExercise(BuildContext context) {
    final zh = L10n.zh;
    final hue = _hue;
    final ex = Store.instance.exerciseById(_item.exerciseId);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Text(
                  '${L10n.tf('exerciseProgress', _itemIdx + 1)} / ${plan.items.length}'
                      .toUpperCase(),
                  style: Iron.eyebrow(color: hue)),
              const Spacer(),
              Text(
                  '${(100 * _itemIdx / plan.items.length).round()}%',
                  style: Iron.eyebrow()),
            ],
          ),
          const SizedBox(height: 8),
          BarbellProgress(
              current: _itemIdx + 1, total: plan.items.length, color: hue),
          const SizedBox(height: 18),

          // ---- the set card
          IronCard(
            color: Iron.tint(hue),
            radius: Iron.rXL,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MuscleGlyph(
                        muscles: ex?.muscles ?? const [],
                        color: hue,
                        size: 56,
                        onTint: true),
                    const Spacer(),
                    if (ex != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: Iron.inkOf(hue)),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ExerciseDetailPage(exercise: ex),
                          ));
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: Text(L10n.t('description')),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(ex?.name(zh) ?? _item.exerciseId, style: Iron.hero(28)),
                if (zh && ex != null)
                  Text(ex.nameEn, style: Iron.caption(color: Iron.faint)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SetDots(
                        done: _setIdx, total: _item.sets, color: hue, size: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          zh
                              ? '第 ${_setIdx + 1} 组 · 共 ${_item.sets} 组'
                              : 'Set ${_setIdx + 1} of ${_item.sets}',
                          style: Iron.body(16,
                              weight: FontWeight.w800, color: hue)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    IronPill('${L10n.t('target')} ${_item.reps}',
                        color: hue, icon: Icons.repeat_rounded),
                    IronPill(
                        '${L10n.t('rest')} $_effectiveRest${L10n.t('seconds')}',
                        color: hue,
                        icon: Icons.timer_outlined),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---- weight
          IronCard(
            radius: Iron.rM,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t('weightKg'), style: Iron.caption()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _roundBtn(Icons.remove_rounded, () => _bumpWeight(-2.5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: Iron.hero(26),
                        decoration: InputDecoration(
                          hintText: '—',
                          suffixText: 'kg',
                          suffixStyle: Iron.caption(),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _roundBtn(Icons.add_rounded, () => _bumpWeight(2.5)),
                  ],
                ),
                if (_lastWeightShown != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      '${L10n.t('lastWeightHint')}: ${fmtWeight(_lastWeightShown!)} kg',
                      style: Iron.caption(color: Iron.faint)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          IronButton(
            label: L10n.t('completeSet'),
            icon: Icons.check_rounded,
            color: hue,
            onPressed: _completeSet,
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Iron.tint(_hue),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
            width: 48, height: 48, child: Icon(icon, color: _hue)),
      ),
    );
  }

  // -------------------------------------------------------------------- rest

  Widget _buildRest(BuildContext context) {
    final zh = L10n.zh;
    String nextLabel;
    if (_setIdx + 1 < _item.sets) {
      nextLabel =
          '${Store.instance.exerciseById(_item.exerciseId)?.name(zh) ?? _item.exerciseId} · ${zh ? '第 ${_setIdx + 2} 组' : 'Set ${_setIdx + 2}'}';
    } else if (_itemIdx + 1 < plan.items.length) {
      final next = plan.items[_itemIdx + 1];
      nextLabel = Store.instance.exerciseById(next.exerciseId)?.name(zh) ??
          next.exerciseId;
    } else {
      nextLabel = L10n.t('sessionFinished');
    }
    final m = _restRemaining ~/ 60;
    final s = _restRemaining % 60;
    final tip = trainingTips[_restCount % trainingTips.length];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(L10n.t('restTime').toUpperCase(),
                        style: Iron.eyebrow(color: Iron.accent)),
                    const SizedBox(height: 18),
                    RestRing(
                      value: _restTotal == 0 ? 0 : _restRemaining / _restTotal,
                      child: Text('$m:${s.toString().padLeft(2, '0')}',
                          style: Iron.hero(64)),
                    ),
                    const SizedBox(height: 24),
                    IronCard(
                      radius: Iron.rM,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          IconBlob(Icons.skip_next_rounded, color: _hue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(L10n.t('nextUp'), style: Iron.caption()),
                                Text(nextLabel,
                                    style: Iron.body(15,
                                        weight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _tipCard(zh ? tip.zh : tip.en),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    onPressed: _addRest,
                    child: const Text('+15 s'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: IronButton(
                      label: L10n.t('skipRest'),
                      icon: Icons.fast_forward_rounded,
                      onPressed: _advance),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(String text) {
    final hue = Iron.tier(2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Iron.tint(hue),
        borderRadius: const BorderRadius.all(Iron.rM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, size: 20, color: hue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t('tipTitle'), style: Iron.caption(color: hue)),
                const SizedBox(height: 2),
                Text(text, style: Iron.body(13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- finished

  Widget _buildFinished(BuildContext context) {
    final zh = L10n.zh;
    final total = _log.fold<int>(0, (a, i) => a + i.sets.length);
    final recovery = trainingTips[1];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  color: Iron.tint(Iron.accent), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 72, color: Iron.accent),
            ),
          ),
          const SizedBox(height: 18),
          Text(L10n.t('greatJob'),
              textAlign: TextAlign.center, style: Iron.hero(30)),
          const SizedBox(height: 6),
          Text('${L10n.t('sessionFinished')} · ${plan.title(zh)}',
              textAlign: TextAlign.center, style: Iron.caption()),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: '$total', label: L10n.t('totalSets'))),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: fmtDuration(_durationSeconds),
                      label: L10n.t('duration'),
                      color: Iron.tier(1))),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${_log.length}',
                      label: L10n.t('statExercises'),
                      color: Iron.tier(2))),
            ],
          ),
          const SizedBox(height: 14),
          _tipCard(zh ? recovery.zh : recovery.en),
          const SizedBox(height: 14),
          // AdMob interstitial goes here (week 6-7) — never mid-workout.
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Iron.cardHi,
              borderRadius: const BorderRadius.all(Iron.rM),
            ),
            child: Text(L10n.t('adPlaceholder'),
                style: Iron.caption(color: Iron.faint)),
          ),
          const SizedBox(height: 20),
          IronButton(
              label: L10n.t('finish'),
              icon: Icons.home_rounded,
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
