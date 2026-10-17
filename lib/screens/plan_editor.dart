import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

/// Editor for custom plans — matte tiles, quiet controls, mint on actions.

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
          style: Iron.body(15),
          decoration: const InputDecoration(hintText: '8-12 / 30-45s'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(L10n.t('cancel'))),
          FilledButton(
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
          IconButton(icon: Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            style: Iron.body(15),
            decoration: InputDecoration(labelText: L10n.t('planName')),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _items.length; i++) _itemCard(context, i, zh),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: Icon(Icons.add, size: 18),
            label: Text(L10n.t('addItem')),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, int i, bool zh) {
    final item = _items[i];
    final ex = Store.instance.exerciseById(item.exerciseId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Iron.card,
          borderRadius: BorderRadius.all(Iron.rM),
        ),
        padding: const EdgeInsets.fromLTRB(14, 4, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _replaceExercise(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(ex?.name(zh) ?? item.exerciseId,
                          style: Iron.body(15, weight: FontWeight.w600)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_upward,
                      size: 17, color: Iron.sub),
                  onPressed: i == 0 ? null : () => _move(i, -1),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward,
                      size: 17, color: Iron.sub),
                  onPressed:
                      i == _items.length - 1 ? null : () => _move(i, 1),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 17, color: Iron.sub),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
              ],
            ),
            Row(
              children: [
                _stepper(
                  label: '${L10n.t('sets')} ${item.sets}',
                  onMinus: item.sets > 1
                      ? () => setState(() => _items[i] =
                          item.copyWith(sets: item.sets - 1))
                      : null,
                  onPlus: item.sets < 10
                      ? () => setState(() => _items[i] =
                          item.copyWith(sets: item.sets + 1))
                      : null,
                ),
                SizedBox(width: 8),
                InkWell(
                  onTap: () => _editReps(i),
                  borderRadius: const BorderRadius.all(Iron.rS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Iron.cardHi,
                      borderRadius: BorderRadius.all(Iron.rS),
                    ),
                    child: Text('${L10n.t('reps')}: ${item.reps}',
                        style: Iron.caption()),
                  ),
                ),
                const Spacer(),
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
          ],
        ),
      ),
    );
  }

  Widget _stepper(
      {required String label, VoidCallback? onMinus, VoidCallback? onPlus}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Iron.caption()),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onMinus,
          icon: Icon(Icons.remove_circle_outline,
              size: 18, color: Iron.sub),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onPlus,
          icon: Icon(Icons.add_circle_outline,
              size: 18, color: Iron.accent),
        ),
      ],
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: Iron.body(14),
              decoration: InputDecoration(
                hintText: L10n.t('search'),
                prefixIcon:
                    Icon(Icons.search, size: 18, color: Iron.sub),
              ),
            ),
          ),
          Expanded(
            child: ListView(
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
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Text(L10n.t(category),
            style: Iron.caption(color: Iron.accent)
                .copyWith(fontWeight: FontWeight.w600)),
      ),
      for (final e in inCat)
        ListTile(
          dense: true,
          enabled: true,
          title: Text(zh ? e.nameZh : e.nameEn, style: Iron.body(14)),
          subtitle: Text(
              (e.availableFor(Store.instance.settings.userEquipment)
                      ? ''
                      : '${L10n.tf('needsEquipment', L10n.t(e.requiredEquipment() == 'dumbbell' ? 'dumbbell' : 'obEqGym'))} · ') +
                  (zh
                      ? e.muscles.map((m) => L10n.muscle(m)).join(' · ')
                      : '${e.muscles.map((m) => L10n.muscle(m)).join(' · ')} · ${e.nameZh}'),
              style: Iron.caption(
                  color: e.availableFor(Store.instance.settings.userEquipment)
                      ? Iron.faint
                      : Iron.sub)),
          onTap: () => Navigator.pop(context, e.id),
        ),
    ];
  }
}
