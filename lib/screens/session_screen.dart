import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../data/tips.dart';
import 'exercise_detail_screen.dart';

enum _Phase { exercise, rest, finished }

/// The heart of the app. Matte dark, mint accent, quiet numerals.

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
  final List<ItemLog> _log = [];

  Plan get plan => widget.plan;
  PlanItem get _item => plan.items[_itemIdx];

  /// 55+ users recover slower: every rest is 30s longer (locked rule).
  int get _effectiveRest =>
      _item.restSeconds + (Store.instance.settings.ageBand == 'older' ? 30 : 0);

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // screen stays on for the whole workout
    _prefillWeight();
    if (plan.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
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
    _startRest(_effectiveRest);
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
    setState(() => _phase = _Phase.finished);
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
          title: Text(_phase == _Phase.finished
              ? L10n.t('sessionFinished')
              : plan.title(L10n.zh)),
        ),
        body: switch (_phase) {
          _Phase.exercise => _buildExercise(context),
          _Phase.rest => _buildRest(context),
          _Phase.finished => _buildFinished(context),
        },
      ),
    );
  }

  // ---------------------------------------------------------------- exercise

  Widget _buildExercise(BuildContext context) {
    final zh = L10n.zh;
    final ex = Store.instance.exerciseById(_item.exerciseId);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                  zh
                      ? '动作 ${_itemIdx + 1} / ${plan.items.length}'
                      : 'EXERCISE ${_itemIdx + 1} OF ${plan.items.length}',
                  style: Iron.caption()),
              const Spacer(),
              Text((ex?.nameEn ?? '').toUpperCase(),
                  style: Iron.caption(color: Iron.faint)),
            ],
          ),
          SizedBox(height: 8),
          BarbellProgress(current: _itemIdx + 1, total: plan.items.length),
          SizedBox(height: 18),
          Text(ex?.name(zh) ?? _item.exerciseId, style: Iron.hero(28)),
          SizedBox(height: 12),
          _imageTile(context),
          if (ex != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ExerciseDetailPage(exercise: ex),
                  ));
                },
                child: Text(L10n.t('description'),
                    style: Iron.caption(color: Iron.accent)),
              ),
            ),
          SizedBox(height: 4),
          IronCard(
            padding:
                const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Column(
              children: [
                Text(
                    zh
                        ? '第 ${_setIdx + 1} 组 · 共 ${_item.sets} 组'
                        : 'Set ${_setIdx + 1} of ${_item.sets}',
                    style: Iron.hero(26, weight: FontWeight.w600)),
                SizedBox(height: 6),
                Text('${_item.sets} × ${_item.reps} · ${L10n.t('rest')} $_effectiveRest${L10n.t('seconds')}',
                    style: Iron.caption()),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _weightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: Iron.body(15),
            decoration: InputDecoration(
              labelText: L10n.t('weightKg'),
              helperText: _lastWeightShown == null
                  ? null
                  : '${L10n.t('lastWeightHint')}: ${fmtWeight(_lastWeightShown!)} kg',
            ),
          ),
          const SizedBox(height: 16),
          IronButton(
            label: L10n.t('completeSet'),
            icon: Icons.check,
            onPressed: _completeSet,
          ),
        ],
      ),
    );
  }

  Widget _imageTile(BuildContext context) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Iron.card,
        borderRadius: BorderRadius.all(Iron.rM),
      ),
      child: Icon(
        _item.exerciseId.startsWith('db_')
            ? Icons.fitness_center
            : Icons.accessibility_new,
        size: 40,
        color: Iron.faint,
      ),
    );
  }

  // -------------------------------------------------------------------- rest

  Widget _buildRest(BuildContext context) {
    final zh = L10n.zh;
    String nextLabel;
    if (_setIdx + 1 < _item.sets) {
      nextLabel =
          '${Store.instance.exerciseById(_item.exerciseId)?.name(zh) ?? _item.exerciseId} · ${zh ? '第 ${_setIdx + 2} 组' : 'SET ${_setIdx + 2}'}';
    } else if (_itemIdx + 1 < plan.items.length) {
      final next = plan.items[_itemIdx + 1];
      nextLabel = Store.instance.exerciseById(next.exerciseId)?.name(zh) ??
          next.exerciseId;
    } else {
      nextLabel = L10n.t('sessionFinished');
    }
    final m = _restRemaining ~/ 60;
    final s = _restRemaining % 60;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(L10n.t('restTime'), style: Iron.caption(color: Iron.sub)),
            const SizedBox(height: 16),
            SizedBox(
              width: 230,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 230,
                    height: 230,
                    child: CircularProgressIndicator(
                      value: _restTotal == 0
                          ? 0
                          : _restRemaining / _restTotal,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Iron.cardHi,
                      valueColor: AlwaysStoppedAnimation(Iron.accent),
                    ),
                  ),
                  Text('$m:${s.toString().padLeft(2, '0')}',
                      style: Iron.hero(72, weight: FontWeight.w300)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(nextLabel,
                  textAlign: TextAlign.center, style: Iron.caption()),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      size: 14, color: Iron.faint),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      L10n.zh
                          ? trainingTips[_restCount % trainingTips.length].zh
                          : trainingTips[_restCount % trainingTips.length].en,
                      style: Iron.caption(color: Iron.faint),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _addRest,
                      child: const Text('+15 s'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child:
                        IronButton(label: L10n.t('skipRest'), onPressed: _advance),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- finished

  Widget _buildFinished(BuildContext context) {
    final total = _log.fold<int>(0, (a, i) => a + i.sets.length);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: Iron.accent),
              SizedBox(height: 16),
              Text(L10n.t('sessionFinished'), style: Iron.hero(28)),
              SizedBox(height: 8),
              Text(
                  '${L10n.t('totalSets')}: $total · ${L10n.t('duration')}: ${fmtDuration(DateTime.now().difference(_startedAt).inSeconds)}',
                  style: Iron.caption()),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  L10n.zh ? trainingTips[1].zh : trainingTips[1].en,
                  textAlign: TextAlign.center,
                  style: Iron.caption(color: Iron.faint),
                ),
              ),
              SizedBox(height: 24),
              // AdMob interstitial goes here (week 6-7) — never mid-workout.
              Container(
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Iron.card,
                  borderRadius: BorderRadius.all(Iron.rM),
                ),
                child: Text(L10n.t('adPlaceholder'),
                    style: Iron.caption(color: Iron.faint)),
              ),
              const SizedBox(height: 24),
              IronButton(
                  label: L10n.t('finish'),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}
