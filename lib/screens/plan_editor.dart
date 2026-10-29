import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

/// Editor for custom plans — one soft card per exercise, pill steppers.

class PlanEditorPage extends StatefulWidget {
  final Plan? existing;
  const PlanEditorPage({super.key, this.existing});

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  late final TextEditingController _titleCtrl;
  late List<PlanItem> _items;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _titleCtrl = TextEditingController(
        text: p == null ? '' : (L10n.zh ? p.titleZh : p.titleEn));
    _items = p == null ? [] : List.of(p.items);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ExercisePickerPage()),
    );
    if (id == null) return;
    final ex = Store.instance.exerciseById(id);
    setState(() {
      _items.add(PlanItem(
        exerciseId: id,
        sets: ex?.defSets ?? 3,
        reps: ex?.defReps ?? '10-12',
        restSeconds: ex?.defRest ?? 90,
      ));
    });
  }

  Future<void> _replaceExercise(int index) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ExercisePickerPage()),
    );
    if (id == null) return;
    setState(() {
      _items[index] = _items[index].copyWith(exerciseId: id);
    });
  }

  Future<void> _editReps(int index) async {
    final ctrl = TextEditingController(text: _items[index].reps);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.t('reps')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: Iron.body(16, weight: FontWeight.w700),
          decoration: const InputDecoration(hintText: '8-12 / 30-45s'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(L10n.t('cancel'))),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(L10n.t('save'))),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;
    setState(() => _items[index] = _items[index].copyWith(reps: result));
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _items.length) return;
    setState(() {
      final tmp = _items[index];
      _items[index] = _items[target];
      _items[target] = tmp;
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack(L10n.t('planNeedsName'));
      return;
    }
    if (_items.isEmpty) {
      _snack(L10n.t('planNeedsItems'));
      return;
    }
    final id = widget.existing?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';
    final plan = Plan(
      id: id,
      titleEn: title,
      titleZh: title,
      descEn: widget.existing?.descEn ?? '',
      descZh: widget.existing?.descZh ?? '',
      tier: widget.existing?.tier ?? 0,
      builtin: false,
      daysMin: widget.existing?.daysMin ?? 2,
      daysMax: widget.existing?.daysMax ?? 5,
      idealDays: widget.existing?.idealDays ?? const [],
      items: List.of(_items),
    );
    Store.instance.customPlans.removeWhere((p) => p.id == id);
    Store.instance.customPlans.add(plan);
    await Store.instance.save();
    if (mounted) Navigator.pop(context, true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    return Scaffold(
      backgroundColor: Iron.bg,
      appBar: AppBar(
        title: Text(widget.existing == null
            ? L10n.t('newPlan')
            : L10n.t('editPlan')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(L10n.t('save')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          TextField(
            controller: _titleCtrl,
            style: Iron.hero(20),
            decoration: InputDecoration(
              labelText: L10n.t('planName'),
              prefixIcon: Icon(Icons.edit_note_rounded, color: Iron.accent),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _itemCard(context, i, zh),
            ),
          const SizedBox(height: 4),
          IronCard(
            onTap: _addExercise,
            color: Iron.tint(Iron.accent),
            radius: Iron.rM,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, color: Iron.accent),
                const SizedBox(width: 8),
                Text(L10n.t('addItem'),
                    style: Iron.body(15,
                        weight: FontWeight.w800, color: Iron.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, int i, bool zh) {
    final item = _items[i];
    final ex = Store.instance.exerciseById(item.exerciseId);
    return IronCard(
      radius: Iron.rM,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBlob(exerciseIcon(ex?.category ?? ''), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _replaceExercise(i),
                  borderRadius: const BorderRadius.all(Iron.rS),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(ex?.name(zh) ?? item.exerciseId,
                              style:
                                  Iron.body(15, weight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.swap_horiz_rounded,
                            size: 16, color: Iron.faint),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                onPressed: i == 0 ? null : () => _move(i, -1),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed:
                    i == _items.length - 1 ? null : () => _move(i, 1),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _items.removeAt(i)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stepper(
                  label: '${L10n.t('sets')} ${item.sets}',
                  onMinus: item.sets > 1
                      ? () => setState(() =>
                          _items[i] = item.copyWith(sets: item.sets - 1))
                      : null,
                  onPlus: item.sets < 10
                      ? () => setState(() =>
                          _items[i] = item.copyWith(sets: item.sets + 1))
                      : null,
                ),
                Material(
                  color: Iron.cardHi,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _editReps(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      child: Text('${L10n.t('reps')} ${item.reps}',
                          style: Iron.caption(color: Iron.ink)),
                    ),
                  ),
                ),
                _stepper(
                  label:
                      '${L10n.t('rest')} ${item.restSeconds}${L10n.t('seconds')}',
                  onMinus: item.restSeconds > 15
                      ? () => setState(() => _items[i] = item.copyWith(
                          restSeconds: item.restSeconds - 15))
                      : null,
                  onPlus: item.restSeconds < 300
                      ? () => setState(() => _items[i] = item.copyWith(
                          restSeconds: item.restSeconds + 15))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pill-shaped − value + control.
  Widget _stepper(
      {required String label, VoidCallback? onMinus, VoidCallback? onPlus}) {
    Widget btn(IconData icon, VoidCallback? onTap) => InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon,
                size: 18, color: onTap == null ? Iron.line : Iron.accent),
          ),
        );
    return Container(
      decoration:
          ShapeDecoration(shape: const StadiumBorder(), color: Iron.cardHi),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, onMinus),
          Text(label, style: Iron.caption(color: Iron.ink)),
          btn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }
}

/// Searchable exercise chooser; pops with the picked exercise id.

class ExercisePickerPage extends StatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final zh = L10n.zh;
    final q = _query.toLowerCase();
    final matches = Store.instance.exercises.where((e) {
      if (q.isEmpty) return true;
      return e.nameEn.toLowerCase().contains(q) ||
          e.nameZh.contains(_query) ||
          e.muscles.any((m) => L10n.muscle(m).toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: Iron.bg,
      appBar: AppBar(title: Text(L10n.t('pickExercise'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: Iron.body(15, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: L10n.t('search'),
                prefixIcon: Icon(Icons.search_rounded, color: Iron.sub),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                for (final category in [
                  'bodyweight',
                  'dumbbell',
                  'barbell',
                  'machine',
                  'cable'
                ])
                  ..._section(context, category, matches, zh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(
      BuildContext context, String category, List<Exercise> matches, bool zh) {
    final inCat = matches.where((e) => e.category == category).toList();
    if (inCat.isEmpty) return [];
    final userEq = Store.instance.settings.userEquipment;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Row(
          children: [
            Icon(exerciseIcon(category), size: 18, color: Iron.accent),
            const SizedBox(width: 6),
            Text(L10n.t(category),
                style: Iron.body(15, weight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('${inCat.length}', style: Iron.caption(color: Iron.faint)),
          ],
        ),
      ),
      for (final e in inCat)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IronCard(
            radius: Iron.rM,
            raised: false,
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            onTap: () => Navigator.pop(context, e.id),
            child: Row(
              children: [
                IconBlob(exerciseIcon(e.category),
                    size: 40,
                    color: e.availableFor(userEq) ? Iron.accent : Iron.faint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zh ? e.nameZh : e.nameEn,
                          style: Iron.body(15, weight: FontWeight.w700)),
                      Text(
                        zh
                            ? e.muscles.map((m) => L10n.muscle(m)).join(' · ')
                            : '${e.muscles.map((m) => L10n.muscle(m)).join(' · ')} · ${e.nameZh}',
                        style: Iron.caption(color: Iron.faint),
                      ),
                      if (!e.availableFor(userEq))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IronPill(
                            L10n.tf(
                                'needsEquipment',
                                L10n.t(e.requiredEquipment() == 'dumbbell'
                                    ? 'dumbbell'
                                    : 'obEqGym')),
                            icon: Icons.lock_outline_rounded,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline_rounded, color: Iron.accent),
              ],
            ),
          ),
        ),
    ];
  }
}
