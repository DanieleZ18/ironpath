import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/exercise_motions.dart';
import '../l10n.dart';
import '../motion.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/exercise_motion.dart';
import '../widgets/ios_chrome.dart';
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
    // a light tap of confirmation, felt rather than heard
    if (Store.instance.settings.feedbackOn) HapticFeedback.lightImpact();
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
    final cur = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ??
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
    final res = await showIronActionSheet<bool>(
      context,
      title: L10n.t('giveUp'),
      message: L10n.t('giveUpBody'),
      actions: [SheetAction(L10n.t('quit'), true, destructive: true)],
      cancelLabel: L10n.t('stay'),
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
      child: IronPage(
        title: _phase == _Phase.finished ? '' : plan.title(L10n.zh),
        titleAlways: true,
        // close (✕) while training — it asks before quitting; nothing once
        // finished, the finish button leads home
        leading: _phase == _Phase.finished
            ? const SizedBox.shrink()
            : isApple(context)
                ? CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(44, 44),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Icon(CupertinoIcons.xmark,
                        size: 22, color: Iron.inkOf(Iron.accent)),
                  )
                : IconButton(
                    icon: Icon(Icons.close, color: Iron.ink),
                    tooltip: L10n.t('quit'),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
        builder: (context, insets) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // fade + a slight rise/scale: each set and rest feels like a card
          // being dealt, without moving far enough to distract
          transitionBuilder: (child, anim) => Motion.reduced(context)
              ? FadeTransition(opacity: anim, child: child)
              : FadeTransition(
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
              Text('${(100 * _itemIdx / plan.items.length).round()}%',
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
                if (ex != null) _demoStage(context, ex, hue),
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

  /// The move, demonstrated while you do it. Tapping it opens the full
  /// how-to sheet (the book badge says so).
  Widget _demoStage(BuildContext context, Exercise ex, Color hue) {
    final name = ex.name(L10n.zh);
    void open() => showExerciseDetail(context, ex);
    return Semantics(
      button: true,
      label: '${L10n.tf('demoOf', name)}. ${L10n.t('description')}',
      onTap: open,
      excludeSemantics: true,
      child: IronCard(
        radius: Iron.rL,
        padding: EdgeInsets.zero,
        raised: false,
        onTap: open,
        child: SizedBox(
          height: 150,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  child: ExerciseMotionView(
                    spec: motionFor(ex.id),
                    muscles: ex.muscles,
                    color: hue,
                    onTint: true,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Iron.tint(hue), shape: BoxShape.circle),
                  child: Icon(Icons.menu_book_rounded,
                      size: 16, color: Iron.inkOf(hue)),
                ),
              ),
            ],
          ),
        ),
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
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: _hue)),
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
                    const SizedBox(height: 10),
                    // the set just finished pops into its dot
                    SetDots(
                        done: _setIdx + 1,
                        total: _item.sets,
                        color: _hue,
                        popLast: true),
                    const SizedBox(height: 18),
                    RestRing(
                      value: _restTotal == 0 ? 0 : _restRemaining / _restTotal,
                      // digits roll down as time runs out; the last three
                      // seconds turn to the accent with the warning ticks
                      child: RollingText('$m:${s.toString().padLeft(2, '0')}',
                          down: true,
                          style: Iron.hero(64,
                              color: _restRemaining <= 3 ? Iron.accent : null)),
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
                                    style:
                                        Iron.body(15, weight: FontWeight.w800)),
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
    final recovery = trainingTips[1];
    return _FinishView(
      planTitle: plan.title(zh),
      sets: _log.fold<int>(0, (a, i) => a + i.sets.length),
      seconds: _durationSeconds,
      exercises: _log.length,
      tip: _tipCard(zh ? recovery.zh : recovery.en),
      onDone: () => Navigator.of(context).pop(),
    );
  }
}

/// The one orchestrated moment in the app: the check draws itself, the
/// title rises in, the numbers count up, and a success haptic lands as the
/// check closes. One controller sequences it all; Reduce Motion shows the
/// finished state at once.
class _FinishView extends StatefulWidget {
  final String planTitle;
  final int sets;
  final int seconds;
  final int exercises;
  final Widget tip;
  final VoidCallback onDone;

  const _FinishView({
    required this.planTitle,
    required this.sets,
    required this.seconds,
    required this.exercises,
    required this.tip,
    required this.onDone,
  });

  @override
  State<_FinishView> createState() => _FinishViewState();
}

class _FinishViewState extends State<_FinishView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  final List<Timer> _haptics = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    final haptics = Store.instance.settings.feedbackOn;
    if (Motion.reduced(context)) {
      _c.value = 1;
      if (haptics) HapticFeedback.mediumImpact();
      return;
    }
    _c.forward();
    if (haptics) {
      // success pattern: a firm tap as the check closes, a lighter echo
      _haptics
        ..add(Timer(const Duration(milliseconds: 620),
            () => HapticFeedback.mediumImpact()))
        ..add(Timer(const Duration(milliseconds: 730),
            () => HapticFeedback.lightImpact()));
    }
  }

  @override
  void dispose() {
    for (final t in _haptics) {
      t.cancel();
    }
    _c.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b,
          [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  /// Fade + rise for a text block entering at [a]..[b].
  Widget _rise(double a, double b, Widget child) {
    final t = _seg(a, b);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(t),
        child: child,
      ),
    );
  }

  Widget _stat(int i, double value, String Function(double) format,
      String label, Color hue) {
    final delay = Duration(milliseconds: 650 + 90 * i);
    return _rise(
      0.4 + 0.06 * i,
      0.75 + 0.06 * i,
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Iron.tint(hue),
          borderRadius: const BorderRadius.all(Iron.rM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUp(
                value: value,
                format: format,
                delay: delay,
                style: Iron.hero(24, color: hue),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Iron.caption()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ring = _seg(0.0, 0.42, Curves.easeInOutCubic);
    final tick = _seg(0.26, 0.5, Curves.easeOutCubic);
    final disc = _seg(0.0, 0.55, Motion.bouncy);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Transform.scale(
                scale: 0.6 + 0.4 * disc.value,
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: CustomPaint(
                    painter: _CheckPainter(
                      ring: ring.value,
                      tick: tick.value,
                      disc: Iron.tint(Iron.accent),
                      ink: Iron.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _rise(
              0.3,
              0.6,
              Text(L10n.t('greatJob'),
                  textAlign: TextAlign.center, style: Iron.hero(30))),
          const SizedBox(height: 6),
          _rise(
              0.36,
              0.66,
              Text('${L10n.t('sessionFinished')} · ${widget.planTitle}',
                  textAlign: TextAlign.center, style: Iron.caption())),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _stat(0, widget.sets.toDouble(), (v) => '${v.round()}',
                      L10n.t('totalSets'), Iron.accent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _stat(
                      1,
                      widget.seconds.toDouble(),
                      (v) => fmtDuration(v.round()),
                      L10n.t('duration'),
                      Iron.tier(1))),
              const SizedBox(width: 10),
              Expanded(
                  child: _stat(
                      2,
                      widget.exercises.toDouble(),
                      (v) => '${v.round()}',
                      L10n.t('statExercises'),
                      Iron.tier(2))),
            ],
          ),
          const SizedBox(height: 14),
          _rise(0.6, 0.9, widget.tip),
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
              onPressed: widget.onDone),
        ],
      ),
    );
  }
}

/// Tinted disc, a ring that sweeps closed ([ring] 0..1), then a check
/// stroke that draws itself ([tick] 0..1).
class _CheckPainter extends CustomPainter {
  final double ring;
  final double tick;
  final Color disc;
  final Color ink;

  _CheckPainter(
      {required this.ring,
      required this.tick,
      required this.disc,
      required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r - 4, Paint()..color = disc);
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (ring > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 4), -1.5708,
          6.2832 * ring, false, stroke);
    }
    if (tick > 0) {
      final a = Offset(c.dx - r * 0.34, c.dy + r * 0.02);
      final b = Offset(c.dx - r * 0.08, c.dy + r * 0.28);
      final e = Offset(c.dx + r * 0.38, c.dy - r * 0.26);
      final first = (b - a).distance;
      final second = (e - b).distance;
      final drawn = (first + second) * tick;
      final path = Path()..moveTo(a.dx, a.dy);
      if (drawn <= first) {
        final p = Offset.lerp(a, b, drawn / first)!;
        path.lineTo(p.dx, p.dy);
      } else {
        final p = Offset.lerp(b, e, (drawn - first) / second)!;
        path
          ..lineTo(b.dx, b.dy)
          ..lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.ring != ring ||
      old.tick != tick ||
      old.disc != disc ||
      old.ink != ink;
}
