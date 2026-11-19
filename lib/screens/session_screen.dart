import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/exercise_motions.dart';
import '../data/tips.dart';
import '../l10n.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../theme.dart';
import '../training_stats.dart';
import '../utils.dart';
import '../widgets/exercise_motion.dart';
import '../widgets/ios_chrome.dart';
import '../widgets/muscle_glyph.dart';
import 'exercise_detail_screen.dart';

enum _Phase { exercise, rest, finished }

enum _Quit { save, discard }

/// The heart of the app: the move demonstrated on top, then one row per set
/// the way strength trackers log it (last time, kg, reps, done), a thick
/// rest ring between sets, and the plan's tier hue carried through.

class SessionScreen extends StatefulWidget {
  final Plan plan;
  const SessionScreen({super.key, required this.plan});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final DateTime _startedAt = DateTime.now();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _repsCtrl = TextEditingController();

  /// Done sets per plan item, in plan order.
  late final List<List<SetLog>> _done = [
    for (final _ in widget.plan.items) <SetLog>[],
  ];

  /// Last time's done sets per plan item: the "Previous" column.
  late final List<List<SetLog>> _previous = [
    for (final it in widget.plan.items)
      previousSets(Store.instance.logs, it.exerciseId),
  ];

  /// Bodyweight moves the user chose to load this time.
  final Set<int> _weighted = {};

  int _itemIdx = 0;
  _Phase _phase = _Phase.exercise;
  int _restRemaining = 0;
  int _restTotal = 0;
  int _restCount = 0; // which rest we're on — rotates the tip
  Timer? _timer;
  SessionLog? _saved; // the log, once finished
  List<PersonalRecord> _records = const [];

  Plan get plan => widget.plan;
  Color get _hue => Iron.tier(plan.builtin ? plan.tier : 0);
  PlanItem get _item => plan.items[_itemIdx];
  int get _setIdx => _done[_itemIdx].length; // the set being done now
  RepTarget get _target => RepTarget.parse(_item.reps);
  bool get _timed => _target.timed || isTimed(_item.exerciseId);

  bool _complete(int i) => _done[i].length >= plan.items[i].sets;
  bool get _allDone {
    for (var i = 0; i < plan.items.length; i++) {
      if (!_complete(i)) return false;
    }
    return true;
  }

  int get _setsDone => _done.fold(0, (a, l) => a + l.length);
  int get _setsPlanned => plan.items.fold(0, (a, it) => a + it.sets);

  /// Loaded moves log weight; bodyweight ones once load has been added.
  bool _logsWeight(int i) {
    final ex = Store.instance.exerciseById(plan.items[i].exerciseId);
    if (ex == null || ex.category != 'bodyweight') return true;
    return _weighted.contains(i) ||
        _previous[i].any((s) => s.weight != null) ||
        _done[i].any((s) => s.weight != null);
  }

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
    _prefill();
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    _timer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  /// Start the set's fields where the last set left off: this workout's
  /// previous set, else the same set last time, else the target.
  void _prefill() {
    final today = _done[_itemIdx];
    final prev = _previous[_itemIdx];
    final before = today.isEmpty ? null : today.last;
    final lastTime =
        prev.isEmpty ? null : prev[math.min(_setIdx, prev.length - 1)];
    final w = before?.weight ??
        lastTime?.weight ??
        (today.isEmpty ? Store.instance.lastWeightFor(_item.exerciseId) : null);
    _weightCtrl.text = w == null ? '' : fmtWeight(w);
    _repsCtrl.text = '${before?.reps ?? lastTime?.reps ?? _target.start}';
  }

  double? get _weight =>
      double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
  int? get _reps => int.tryParse(_repsCtrl.text.trim());

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
    final set = SetLog(
      index: _setIdx,
      done: true,
      weight: _logsWeight(_itemIdx) ? _weight : null,
      reps: _reps,
    );
    setState(() => _done[_itemIdx].add(set));
    if (_allDone) {
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

  void _bumpWeight(double delta) {
    final next = ((_weight ?? 0) + delta).clamp(0, 999).toDouble();
    _weightCtrl.text = fmtWeight(next);
  }

  void _bumpReps(int delta) {
    final next = ((_reps ?? _target.start) + delta).clamp(0, 999);
    _repsCtrl.text = '$next';
  }

  void _changeRest(int delta) {
    if (_restRemaining + delta <= 0) {
      _advance();
      return;
    }
    setState(() {
      _restRemaining += delta;
      if (delta > 0) _restTotal += delta;
    });
  }

  /// The next exercise still to finish after [from], wrapping round to the
  /// ones skipped earlier.
  int _nextOpen(int from) {
    for (var d = 1; d <= plan.items.length; d++) {
      final i = (from + d) % plan.items.length;
      if (!_complete(i)) return i;
    }
    return from;
  }

  void _advance() {
    _timer?.cancel();
    if (_allDone) {
      _finish();
      return;
    }
    setState(() {
      if (_complete(_itemIdx)) _itemIdx = _nextOpen(_itemIdx);
      _phase = _Phase.exercise;
    });
    _prefill();
  }

  /// Picked from the workout list: go straight to that exercise.
  void _jumpTo(int i) {
    if (_complete(i) || (i == _itemIdx && _phase == _Phase.exercise)) return;
    _timer?.cancel();
    setState(() {
      _itemIdx = i;
      _phase = _Phase.exercise;
    });
    _prefill();
  }

  /// Save the workout. Finishing early keeps what was done and marks the
  /// planned sets that weren't, so History can tell.
  void _finish() {
    _timer?.cancel();
    final now = DateTime.now();
    final log = SessionLog(
      id: 'log_${now.millisecondsSinceEpoch}',
      planId: plan.id,
      planTitleEn: plan.titleEn,
      planTitleZh: plan.titleZh,
      startedAt: _startedAt,
      durationSeconds: now.difference(_startedAt).inSeconds,
      items: [
        for (var i = 0; i < plan.items.length; i++)
          ItemLog(exerciseId: plan.items[i].exerciseId, sets: [
            ..._done[i],
            for (var k = _done[i].length; k < plan.items[i].sets; k++)
              SetLog(index: k, done: false),
          ]),
      ],
    );
    final records = recordsIn(log, Store.instance.logs);
    Store.instance.logs.insert(0, log);
    Store.instance.save();
    setState(() {
      _saved = log;
      _records = records;
      _phase = _Phase.finished;
    });
  }

  Future<_Quit?> _confirmQuit() {
    final some = _setsDone > 0;
    return showIronActionSheet<_Quit>(
      context,
      title: L10n.t('quitTitle'),
      message: L10n.t(some ? 'quitBodySave' : 'giveUpBody'),
      actions: [
        if (some)
          SheetAction(L10n.t('finishAndSave'), _Quit.save, isDefault: true),
        SheetAction(L10n.t('discardWorkout'), _Quit.discard, destructive: true),
      ],
      cancelLabel: L10n.t('stay'),
    );
  }

  Future<void> _openOverview() async {
    final picked = await showIronSheet<int>(
      context,
      (context, controller) => _Overview(
        plan: plan,
        done: _done,
        current: _itemIdx,
        controller: controller,
        canFinish: _setsDone > 0,
      ),
    );
    if (!mounted || picked == null) return;
    if (picked < 0) {
      _finish();
    } else {
      _jumpTo(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (plan.items.isEmpty) return Scaffold(backgroundColor: Iron.bg);
    final apple = isApple(context);
    final training = _phase != _Phase.finished;
    return PopScope(
      canPop: !training,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final choice = await _confirmQuit();
        if (!context.mounted) return;
        if (choice == _Quit.save) {
          _finish();
        } else if (choice == _Quit.discard) {
          Navigator.of(context).pop();
        }
      },
      child: IronPage(
        title: training ? plan.title(L10n.zh) : '',
        titleAlways: true,
        // close (✕) while training — it asks before quitting; nothing once
        // finished, the finish button leads home
        leading: !training
            ? const SizedBox.shrink()
            : apple
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
        actions: [
          if (training)
            apple
                ? GlassIconButton(CupertinoIcons.list_bullet,
                    label: L10n.t('workoutOverview'), onPressed: _openOverview)
                : IconButton(
                    icon: Icon(Icons.format_list_bulleted_rounded,
                        color: Iron.ink),
                    tooltip: L10n.t('workoutOverview'),
                    onPressed: _openOverview,
                  ),
        ],
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
    final target = _target;
    final prev = _previous[_itemIdx];
    final weightOn = _logsWeight(_itemIdx);
    final ready = readyToProgress(prev, target, _item.sets);
    final loadedBefore = prev.any((s) => s.weight != null);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                Row(
                  children: [
                    Text(
                        '${L10n.tf('exerciseProgress', _itemIdx + 1)} / ${plan.items.length}',
                        style: Iron.eyebrow(color: hue)),
                    const Spacer(),
                    Text('${(100 * _setsDone / _setsPlanned).round()}%',
                        style: Iron.eyebrow()),
                  ],
                ),
                const SizedBox(height: 8),
                _WorkoutBar(
                  fractions: [
                    for (var i = 0; i < plan.items.length; i++)
                      _done[i].length / math.max(1, plan.items[i].sets),
                  ],
                  current: _itemIdx,
                  color: hue,
                ),
                const SizedBox(height: 18),

                // ---- the move and its sets
                IronCard(
                  color: Iron.tint(hue),
                  radius: Iron.rXL,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ex != null) _demoStage(context, ex, hue),
                      const SizedBox(height: 14),
                      Text(ex?.name(zh) ?? _item.exerciseId,
                          style: Iron.hero(24)),
                      if (zh && ex != null)
                        Text(ex.nameEn, style: Iron.caption(color: Iron.faint)),
                      const SizedBox(height: 12),
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
                      if (ready) ...[
                        const SizedBox(height: 12),
                        _progressHint(target, loadedBefore, hue),
                      ],
                      const SizedBox(height: 14),
                      ListenableBuilder(
                        listenable: Listenable.merge([_weightCtrl, _repsCtrl]),
                        builder: (context, _) => _SetTable(
                          sets: _item.sets,
                          done: _done[_itemIdx],
                          previous: prev,
                          current: _setIdx,
                          weight: weightOn ? _weight : null,
                          reps: _reps,
                          showWeight: weightOn,
                          timed: _timed,
                          hue: hue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- what this set was, and done: pinned within thumb reach
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                IronCard(
                  radius: Iron.rM,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: weightOn
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _stepper(
                                    L10n.t('weightLabel'), _weightCtrl,
                                    decimal: true,
                                    onMinus: () => _bumpWeight(-2.5),
                                    onPlus: () => _bumpWeight(2.5))),
                            const SizedBox(width: 12),
                            Expanded(child: _repsStepper(target)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _repsStepper(target),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () =>
                                    setState(() => _weighted.add(_itemIdx)),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(L10n.t('weightLabel')),
                                style: TextButton.styleFrom(
                                    foregroundColor: Iron.inkOf(hue),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 0)),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                IronButton(
                  label: L10n.t('completeSet'),
                  icon: Icons.check_rounded,
                  color: hue,
                  onPressed: _completeSet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Double progression: when every set reached the top of the range last
  /// time, say it's time to step up.
  Widget _progressHint(RepTarget target, bool loaded, Color hue) {
    final key = _timed
        ? 'progressHoldLonger'
        : loaded
            ? 'progressAddWeight'
            : 'progressHarder';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: ShapeDecoration(
        color: Iron.card,
        shape: Iron.squircle(Iron.inner(Iron.rXL, 18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_up_rounded, size: 18, color: Iron.inkOf(hue)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(L10n.tf(key, target.high ?? ''),
                style: Iron.body(13,
                    weight: FontWeight.w700, color: Iron.inkOf(hue))),
          ),
        ],
      ),
    );
  }

  Widget _repsStepper(RepTarget target) => _stepper(
        L10n.t(_timed ? 'secsLabel' : 'repsLabel'),
        _repsCtrl,
        onMinus: () => _bumpReps(-target.step),
        onPlus: () => _bumpReps(target.step),
      );

  /// A number field between − and + (big targets for gym hands; the field
  /// still takes typing).
  Widget _stepper(String label, TextEditingController ctrl,
      {required VoidCallback onMinus,
      required VoidCallback onPlus,
      bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Iron.caption()),
        const SizedBox(height: 8),
        Row(
          children: [
            _roundBtn(Icons.remove_rounded, onMinus, label: '− $label'),
            Expanded(
              child: TextField(
                controller: ctrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
                ],
                style: Iron.hero(22),
                decoration: const InputDecoration(
                  hintText: '—',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            _roundBtn(Icons.add_rounded, onPlus, label: '+ $label'),
          ],
        ),
      ],
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
        radius: Iron.inner(Iron.rXL, 18),
        padding: EdgeInsets.zero,
        raised: false,
        onTap: open,
        child: SizedBox(
          height: 128,
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

  /// A 42 px disc with a 48 px hit area (the platform minimum): the ring of
  /// slack around it catches taps that land just off the disc mid-set.
  Widget _roundBtn(IconData icon, VoidCallback onTap, {required String label}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Material(
              color: Iron.tint(_hue),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(icon, size: 22, color: Iron.inkOf(_hue))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- rest

  Widget _buildRest(BuildContext context) {
    final zh = L10n.zh;
    String nextLabel;
    if (!_complete(_itemIdx)) {
      nextLabel =
          '${Store.instance.exerciseById(_item.exerciseId)?.name(zh) ?? _item.exerciseId} · ${L10n.tf('setOfN', _setIdx + 1)}';
    } else if (!_allDone) {
      final next = plan.items[_nextOpen(_itemIdx)];
      nextLabel = Store.instance.exerciseById(next.exerciseId)?.name(zh) ??
          next.exerciseId;
    } else {
      nextLabel = L10n.t('sessionFinished');
    }
    final m = _restRemaining ~/ 60;
    final s = _restRemaining % 60;
    final tip = trainingTips[_restCount % trainingTips.length];
    final just = _done[_itemIdx].isEmpty ? null : _done[_itemIdx].last;
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
                    Text(L10n.t('restTime'),
                        style: Iron.eyebrow(color: Iron.accent)),
                    const SizedBox(height: 10),
                    // the set just finished pops into its dot
                    SetDots(
                        done: _done[_itemIdx].length,
                        total: _item.sets,
                        color: _hue,
                        popLast: true),
                    if (just != null && (just.weight ?? just.reps) != null) ...[
                      const SizedBox(height: 6),
                      Text(setLabel(just, timed: _timed),
                          style: Iron.caption(color: Iron.inkOf(_hue))),
                    ],
                    const SizedBox(height: 14),
                    RestRing(
                      value: _restTotal == 0 ? 0 : _restRemaining / _restTotal,
                      // digits roll down as time runs out; the last three
                      // seconds turn to the accent with the warning ticks
                      // inside the disc whatever the digits or text size
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RollingText(
                              '$m:${s.toString().padLeft(2, '0')}',
                              down: true,
                              style: Iron.hero(64,
                                  color: _restRemaining <= 3
                                      ? Iron.accent
                                      : null)),
                        ),
                      ),
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
                        minimumSize: const Size.fromHeight(56),
                        padding: EdgeInsets.zero),
                    onPressed: () => _changeRest(-15),
                    child: const Text('−15 s'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        padding: EdgeInsets.zero),
                    onPressed: () => _changeRest(15),
                    child: const Text('+15 s'),
                  ),
                ),
                const SizedBox(width: 8),
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
      decoration: ShapeDecoration(
        color: Iron.tint(hue),
        shape: Iron.squircle(Iron.rM),
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
      log: _saved!,
      records: _records,
      tip: _tipCard(zh ? recovery.zh : recovery.en),
      onDone: () => Navigator.of(context).pop(),
    );
  }
}

/// One segment per exercise, filled as its sets get done; the one being
/// done now sits a shade deeper.
class _WorkoutBar extends StatelessWidget {
  final List<double> fractions;
  final int current;
  final Color color;

  const _WorkoutBar(
      {required this.fractions, required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    final track = Iron.tint(color);
    return Row(
      children: [
        for (var i = 0; i < fractions.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 8,
              decoration: ShapeDecoration(
                color: i == current ? Color.lerp(track, color, 0.28) : track,
                shape: Iron.capsule,
              ),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fractions[i].clamp(0.0, 1.0)),
                duration: Motion.reduced(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 380),
                curve: Motion.smooth,
                builder: (context, f, _) => FractionallySizedBox(
                  widthFactor: f,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                        color: Iron.inkOf(color), shape: Iron.capsule),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The sets of the current exercise, one row each, as strength trackers
/// log them: set, last time, kg, reps, done. The row being done now shows
/// the fields' live values on the card surface.
class _SetTable extends StatelessWidget {
  final int sets;
  final List<SetLog> done;
  final List<SetLog> previous;
  final int current;
  final double? weight;
  final int? reps;
  final bool showWeight;
  final bool timed;
  final Color hue;

  const _SetTable({
    required this.sets,
    required this.done,
    required this.previous,
    required this.current,
    required this.weight,
    required this.reps,
    required this.showWeight,
    required this.timed,
    required this.hue,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Iron.inkOf(hue);
    TextStyle head() => Iron.caption(color: Iron.sub).copyWith(fontSize: 12);
    Widget row(int i) {
      final isDone = i < done.length;
      final isNow = i == current;
      final prev = i < previous.length ? previous[i] : null;
      final s = isDone ? done[i] : null;
      final w = isDone ? s!.weight : (isNow ? weight : null);
      final r = isDone ? s!.reps : (isNow ? reps : null);
      final valueStyle = Iron.body(15,
          weight: FontWeight.w800,
          color: isDone || isNow ? Iron.ink : Iron.faint);
      String show(Object? v) => v == null
          ? '—'
          : v is double
              ? fmtWeight(v)
              : '$v';
      final label = L10n.tf('setOfN', i + 1);
      return Semantics(
        label: '$label${isDone ? ', ${setLabel(s!, timed: timed)}' : ''}',
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: ShapeDecoration(
            color: isNow ? Iron.card : Colors.transparent,
            shape: Iron.squircle(Iron.rS),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? ink : Colors.transparent,
                      border: Border.all(
                          color: isDone || isNow
                              ? ink
                              : ink.withValues(alpha: 0.3),
                          width: 1.6),
                    ),
                    child: Text('${i + 1}',
                        style: Iron.caption(
                                color: isDone
                                    ? (Iron.isDark ? Iron.bg : Colors.white)
                                    : ink,
                                weight: FontWeight.w800)
                            .copyWith(fontSize: 12, height: 1)),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(prev == null ? '—' : setLabel(prev, timed: timed),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Iron.caption(color: Iron.faint)),
              ),
              if (showWeight)
                Expanded(
                    flex: 2,
                    child: Text(show(w),
                        textAlign: TextAlign.center, style: valueStyle)),
              Expanded(
                  flex: 2,
                  child: Text(show(r),
                      textAlign: TextAlign.center, style: valueStyle)),
              SizedBox(
                width: 26,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isDone || isNow ? ink : ink.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 34, child: Text(L10n.t('colSet'), style: head())),
                Expanded(
                    flex: 3, child: Text(L10n.t('colPrevious'), style: head())),
                if (showWeight)
                  Expanded(
                      flex: 2,
                      child: Text(L10n.t('colKg'),
                          textAlign: TextAlign.center, style: head())),
                Expanded(
                    flex: 2,
                    child: Text(L10n.t(timed ? 'colSecs' : 'colReps'),
                        textAlign: TextAlign.center, style: head())),
                const SizedBox(width: 26),
              ],
            ),
          ),
        ),
        for (var i = 0; i < math.max(sets, done.length); i++) row(i),
      ],
    );
  }
}

/// Every exercise of the workout with its sets done; tap one to go to it,
/// or finish here and keep what's done.
class _Overview extends StatelessWidget {
  final Plan plan;
  final List<List<SetLog>> done;
  final int current;
  final ScrollController controller;
  final bool canFinish;

  const _Overview({
    required this.plan,
    required this.done,
    required this.current,
    required this.controller,
    required this.canFinish,
  });

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final hue = Iron.tier(plan.builtin ? plan.tier : 0);
    return Column(
      children: [
        SheetHeader(
          title: L10n.t('workoutOverview'),
          trailing: BarTextButton(L10n.t('done'),
              bold: true, onPressed: () => Navigator.of(context).pop()),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
            children: [
              for (var i = 0; i < plan.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _row(context, i, zh, hue),
                ),
              if (canFinish) ...[
                const SizedBox(height: 10),
                IronButton(
                  label: L10n.t('finishWorkout'),
                  icon: Icons.flag_rounded,
                  color: hue,
                  onPressed: () => Navigator.of(context).pop(-1),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, int i, bool zh, Color hue) {
    final it = plan.items[i];
    final ex = Store.instance.exerciseById(it.exerciseId);
    final n = done[i].length;
    final complete = n >= it.sets;
    final now = i == current;
    return IronCard(
      radius: Iron.rM,
      color: now ? Iron.tint(hue) : null,
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      onTap: complete ? null : () => Navigator.of(context).pop(i),
      child: Row(
        children: [
          MuscleGlyph(
              muscles: ex?.muscles ?? const [],
              color: hue,
              size: 44,
              onTint: now),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex?.name(zh) ?? it.exerciseId,
                    style: Iron.body(15,
                        weight: FontWeight.w800,
                        color: complete ? Iron.sub : Iron.ink)),
                const SizedBox(height: 2),
                Text('${it.sets} × ${it.reps}',
                    style: Iron.caption(color: Iron.faint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          complete
              ? Icon(Icons.check_circle_rounded,
                  size: 22, color: Iron.inkOf(hue))
              : SetDots(done: n, total: it.sets, color: hue, size: 10),
        ],
      ),
    );
  }
}

/// The one orchestrated moment in the app: the check draws itself, the
/// title rises in, the numbers count up, and a success haptic lands as the
/// check closes. Then what the workout added up to, the way strength apps
/// sum it: time, sets, volume, the muscles it worked and any records.
/// Reduce Motion shows the finished state at once.
class _FinishView extends StatefulWidget {
  final String planTitle;
  final SessionLog log;
  final List<PersonalRecord> records;
  final Widget tip;
  final VoidCallback onDone;

  const _FinishView({
    required this.planTitle,
    required this.log,
    required this.records,
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
        decoration: ShapeDecoration(
          color: Iron.tint(hue),
          shape: Iron.squircle(Iron.rM),
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
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Iron.caption()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final zh = L10n.zh;
    final volume = sessionVolume(log);
    final reps = sessionReps(log);
    final muscles = setsPerMuscle([log]);
    final top = musclesBySets([log], 4);
    final skipped = log.totalSets() - log.doneSets();
    final ring = _seg(0.0, 0.42, Curves.easeInOutCubic);
    final tick = _seg(0.26, 0.5, Curves.easeOutCubic);
    final disc = _seg(0.0, 0.55, Motion.bouncy);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => Transform.scale(
                      scale: 0.6 + 0.4 * disc.value,
                      child: SizedBox(
                        width: 112,
                        height: 112,
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
                const SizedBox(height: 16),
                _rise(
                    0.3,
                    0.6,
                    Text(L10n.t('greatJob'),
                        textAlign: TextAlign.center, style: Iron.hero(30))),
                const SizedBox(height: 6),
                _rise(
                    0.36,
                    0.66,
                    Text(
                        skipped > 0
                            ? '${widget.planTitle} · ${L10n.tf('skippedN', skipped)}'
                            : '${L10n.t('sessionFinished')} · ${widget.planTitle}',
                        textAlign: TextAlign.center,
                        style: Iron.caption())),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                        child: _stat(
                            0,
                            log.durationSeconds.toDouble(),
                            (v) => fmtDuration(v.round()),
                            L10n.t('duration'),
                            Iron.tier(1))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _stat(
                            1,
                            log.doneSets().toDouble(),
                            (v) => '${v.round()}',
                            L10n.t('statSets'),
                            Iron.accent)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: volume > 0
                          ? _stat(2, volume, (v) => '${fmtThousands(v)} kg',
                              L10n.t('tonnage'), Iron.tier(2))
                          : reps > 0
                              ? _stat(2, reps.toDouble(), (v) => '${v.round()}',
                                  L10n.t('totalReps'), Iron.tier(2))
                              : _stat(
                                  2,
                                  log.items
                                      .where((i) => i.doneCount > 0)
                                      .length
                                      .toDouble(),
                                  (v) => '${v.round()}',
                                  L10n.t('statExercises'),
                                  Iron.tier(2)),
                    ),
                  ],
                ),
                if (top.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _rise(
                    0.55,
                    0.85,
                    IronCard(
                      radius: Iron.rL,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          MuscleMap(sets: muscles, height: 132, onTint: true),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(L10n.t('musclesWorked'),
                                    style:
                                        Iron.body(15, weight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                for (final m in top)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(L10n.muscle(m.key),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Iron.body(14,
                                                  weight: FontWeight.w700)),
                                        ),
                                        Text(L10n.tf('setsDone', m.value),
                                            style: Iron.caption(
                                                color: Iron.faint)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (widget.records.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _rise(
                    0.6,
                    0.9,
                    IronCard(
                      radius: Iron.rL,
                      color: Iron.tint(Iron.tier(3)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events_rounded,
                                  size: 18, color: Iron.inkOf(Iron.tier(3))),
                              const SizedBox(width: 6),
                              Text(L10n.t('newRecords'),
                                  style: Iron.body(15,
                                      weight: FontWeight.w800,
                                      color: Iron.inkOf(Iron.tier(3)))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final r in widget.records)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Text(
                                        Store.instance
                                                .exerciseById(r.exerciseId)
                                                ?.name(zh) ??
                                            r.exerciseId,
                                        style: Iron.body(14,
                                            weight: FontWeight.w700)),
                                  ),
                                  Text(_recordValue(r.value, r.byWeight),
                                      style: Iron.hero(17,
                                          color: Iron.inkOf(Iron.tier(3)))),
                                  const SizedBox(width: 6),
                                  Text(
                                      L10n.tf('recordWas',
                                          _recordValue(r.previous, r.byWeight)),
                                      style: Iron.caption(color: Iron.faint)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _rise(0.65, 0.95, widget.tip),
              ],
            ),
          ),
          // the way out stays in reach however long the summary runs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: IronButton(
                label: L10n.t('finish'),
                icon: Icons.home_rounded,
                onPressed: widget.onDone),
          ),
        ],
      ),
    );
  }

  String _recordValue(double v, bool byWeight) =>
      byWeight ? '${fmtWeight(v)} kg' : '${v.round()} ${L10n.t('repsUnit')}';
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
