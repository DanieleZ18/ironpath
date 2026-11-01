import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../motion.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ios_chrome.dart';
import '../widgets/plan_card.dart' show tierLabel, tierIcon;
import '../widgets/theme_crossfade.dart';
import '../utils.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const SettingsScreen({super.key, this.scrollController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _setAppearance(String value) {
    Store.instance.settings.appearance = value;
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    ThemeCrossfade.run(context, () {
      setState(() {});
      Iron.setAppearance(value, platformDark: platformDark);
    });
    Store.instance.save();
  }

  void _setLang(String value) {
    Store.instance.settings.lang = value;
    ThemeCrossfade.run(context, () {
      setState(() {});
      L10n.setLang(value,
          systemLocale:
              WidgetsBinding.instance.platformDispatcher.locale.toString());
    });
    Store.instance.save();
  }

  /// Switch colour theme behind a crossfade.
  void _setTheme(String id) {
    if (id == Iron.themeId) return;
    HapticFeedback.selectionClick();
    final s = Store.instance.settings..themeId = id;
    ThemeCrossfade.run(context, () {
      setState(() {});
      Iron.setTheme(id, hue: s.customHue);
    });
    Store.instance.save();
  }

  /// Dragging the hue slider retunes the palette live; saved on release.
  void _setHue(double hue, {bool save = false}) {
    Store.instance.settings
      ..themeId = 'custom'
      ..customHue = hue;
    setState(() {});
    Iron.setTheme('custom', hue: hue);
    if (save) Store.instance.save();
  }

  void _setReminders(bool on) {
    setState(() => Store.instance.settings.remindersOn = on);
    Store.instance.save();
  }

  /// Reminder time: iOS wheel in a bottom popup on Apple devices (commits
  /// on "Done"), the Material clock dialog elsewhere.
  Future<void> _pickReminderTime() async {
    final s = Store.instance.settings;
    if (!isApple(context)) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
        // 24-hour clock, matching how the time is shown in the row
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (t == null) return;
      setState(() {
        s.reminderHour = t.hour;
        s.reminderMinute = t.minute;
      });
      Store.instance.save();
      return;
    }
    var picked = DateTime(2000, 1, 1, s.reminderHour, s.reminderMinute);
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      // Material ancestor so the header's text gets proper text styling
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: Iron.card,
            borderRadius: const BorderRadius.vertical(top: Iron.rXL),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SheetHeader(
                  title: L10n.t('reminderTime'),
                  leading: BarTextButton(L10n.t('cancel'),
                      onPressed: () => Navigator.pop(ctx, false)),
                  trailing: BarTextButton(L10n.t('done'),
                      bold: true, onPressed: () => Navigator.pop(ctx, true)),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: picked,
                    onDateTimeChanged: (d) => picked = d,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    setState(() {
      s.reminderHour = picked.hour;
      s.reminderMinute = picked.minute;
    });
    Store.instance.save();
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.instance.settings;
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        largeTitleBar(L10n.t('tabSettings'), trailing: null),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset(context)),
          sliver: SliverList.list(
            children: [
              // ---- appearance
              _label(L10n.t('appearance')),
              _segmented(
                value: s.appearance,
                onChanged: _setAppearance,
                options: [
                  (
                    'system',
                    Icons.brightness_auto_rounded,
                    L10n.t('systemShort')
                  ),
                  ('light', Icons.light_mode_rounded, L10n.t('light')),
                  ('dark', Icons.dark_mode_rounded, L10n.t('dark')),
                ],
              ),
              const SizedBox(height: 20),

              // ---- colour theme
              _label(L10n.t('themeColor')),
              _themePicker(),
              const SizedBox(height: 20),

              // ---- language
              _label(L10n.t('language')),
              _segmented(
                value: s.lang,
                onChanged: _setLang,
                options: [
                  ('system', Icons.translate_rounded, L10n.t('systemShort')),
                  ('zh', Icons.language_rounded, L10n.t('chinese')),
                  ('en', Icons.language_rounded, L10n.t('english')),
                ],
              ),
              const SizedBox(height: 20),

              // ---- workout
              IronCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _switchRow(
                      icon: Icons.volume_up_rounded,
                      hue: Iron.tier(1),
                      title: L10n.t('soundHaptics'),
                      subtitle: L10n.t('soundHapticsHint'),
                      value: s.feedbackOn,
                      onChanged: (v) {
                        setState(() => Store.instance.settings.feedbackOn = v);
                        Store.instance.save();
                      },
                    ),
                    _divider(),
                    _switchRow(
                      icon: Icons.notifications_rounded,
                      hue: Iron.tier(2),
                      title: L10n.t('reminders'),
                      subtitle: L10n.t('reminderStub'),
                      value: s.remindersOn,
                      onChanged: _setReminders,
                    ),
                    if (s.remindersOn) ...[
                      _divider(),
                      _row(
                        icon: Icons.schedule_rounded,
                        hue: Iron.tier(2),
                        title: L10n.t('reminderTime'),
                        trailing: IronPill(
                            '${pad2(s.reminderHour)}:${pad2(s.reminderMinute)}',
                            color: Iron.tier(2),
                            solid: true),
                        onTap: _pickReminderTime,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IronCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _row(
                      icon: Icons.person_pin_rounded,
                      hue: Iron.accent,
                      title: L10n.t('runAgain'),
                      trailing:
                          Icon(Icons.chevron_right_rounded, color: Iron.faint),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const OnboardingPage(reentry: true),
                        ));
                      },
                    ),
                    _divider(),
                    _row(
                      icon: Icons.description_rounded,
                      hue: Iron.tier(3),
                      title: L10n.t('licenses'),
                      trailing:
                          Icon(Icons.chevron_right_rounded, color: Iron.faint),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: L10n.t('appTitle'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- about
              _label(L10n.t('about')),
              IronCard(
                color: Iron.tint(Iron.accent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 18, color: Iron.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(L10n.t('offlinePitch'),
                              style: Iron.body(14, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(L10n.t('disclaimer'), style: Iron.caption()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- theme

  Widget _themePicker() {
    final zh = L10n.zh;
    final custom = Iron.themeId == 'custom';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (final spec in Iron.presets)
              _swatch(spec, spec.id == Iron.themeId, zh),
            _swatch(ThemeSpec.custom(Iron.customHue), custom, zh,
                isCustom: true),
          ],
        ),
        // the hue slider slides open under the swatches when Custom is on
        AnimatedSize(
          duration: Motion.of(context, Motion.smooth.duration),
          curve: Motion.smooth,
          alignment: Alignment.topCenter,
          child: custom
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _hueSlider(),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 14),
        _themePreview(),
      ],
    );
  }

  Widget _swatch(ThemeSpec spec, bool selected, bool zh,
      {bool isCustom = false}) {
    final tones = Iron.previewTones(spec);
    final ring = Iron.inkOf(tones[0]);
    final tintBg = Color.lerp(Iron.card, tones[0], Iron.isDark ? 0.18 : 0.14)!;
    Widget dot(Color c, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    final face = isCustom
        // custom: the hue wheel around the chosen accent
        ? Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: _hueStops(12)),
            ),
            child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tintBg,
                  border: Border.all(color: tintBg, width: 3)),
              child: dot(tones[0], 20),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot(tones[0], 28),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in tones.skip(1)) ...[
                    dot(c, 8),
                    if (c != tones.last) const SizedBox(width: 3),
                  ],
                ],
              ),
            ],
          );
    return Semantics(
      button: true,
      selected: selected,
      label: spec.name(zh),
      child: ExcludeSemantics(
        child: Pressable(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _setTheme(spec.id),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: Motion.of(context, Motion.snappy.duration),
                    curve: Motion.snappy,
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tintBg,
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                      border: Border.all(
                          color: selected ? ring : Colors.transparent,
                          width: 2.5),
                    ),
                    child: face,
                  ),
                  const SizedBox(height: 6),
                  Text(spec.name(zh),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Iron.caption(
                          color: selected ? Iron.ink : Iron.sub,
                          weight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Accent colours sampled around the wheel (what Custom would produce).
  /// Depends only on brightness, so it's cached — the slider rebuilds every
  /// drag frame.
  static final Map<(int, bool), List<Color>> _stops = {};
  List<Color> _hueStops(int n) => _stops.putIfAbsent(
      (n, Iron.isDark),
      () => [
            for (var i = 0; i <= n; i++)
              Iron.previewTones(ThemeSpec.custom(360.0 * i / n))[0],
          ]);

  Widget _hueSlider() {
    final hue = Iron.customHue;
    final stops = _hueStops(18);
    return Semantics(
      slider: true,
      label: L10n.t('hue'),
      value: '${hue.round()}°',
      increasedValue: '${((hue + 10) % 360).round()}°',
      decreasedValue: '${((hue - 10) % 360).round()}°',
      onIncrease: () => _setHue((hue + 10) % 360, save: true),
      onDecrease: () => _setHue((hue - 10) % 360, save: true),
      child: LayoutBuilder(builder: (context, box) {
        const thumb = 34.0;
        final w = box.maxWidth;
        double hueAt(double dx) =>
            ((dx - thumb / 2) / (w - thumb) * 360).clamp(0.0, 359.9);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragDown: (d) => _setHue(hueAt(d.localPosition.dx)),
          onHorizontalDragUpdate: (d) => _setHue(hueAt(d.localPosition.dx)),
          onHorizontalDragEnd: (_) => _setHue(Iron.customHue, save: true),
          onTapUp: (d) => _setHue(hueAt(d.localPosition.dx), save: true),
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Iron.rPill),
                    gradient: LinearGradient(colors: stops),
                  ),
                ),
                Positioned(
                  left: hue / 360 * (w - thumb),
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: Iron.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// A miniature of the real UI in the current theme, so the effect of a
  /// choice is visible before leaving Settings.
  Widget _themePreview() {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: IronCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in [1, 2, 3])
                    IronPill(tierLabel(t),
                        color: Iron.tier(t), icon: tierIcon(t), solid: t == 1),
                ],
              ),
              const SizedBox(height: 14),
              const BarbellProgress(current: 2, total: 5),
              const SizedBox(height: 14),
              Row(
                children: [
                  const SetDots(done: 2, total: 4),
                  const Spacer(),
                  Text(L10n.tf('weekProgress', '2/3'),
                      style: Iron.caption(color: Iron.accent)),
                ],
              ),
              const SizedBox(height: 14),
              IronButton(
                label: L10n.t('startWorkout'),
                icon: Icons.play_arrow_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(text, style: Iron.body(16, weight: FontWeight.w800)),
      );

  Widget _divider() => Divider(
      height: 1, thickness: 1, indent: 64, endIndent: 16, color: Iron.line);

  /// One-of-three choice: iOS sliding segmented control on Apple devices,
  /// Material segmented button elsewhere.
  Widget _segmented({
    required String value,
    required ValueChanged<String> onChanged,
    required List<(String, IconData, String)> options,
  }) {
    if (!isApple(context)) {
      return SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          selected: {value},
          onSelectionChanged: (sel) => onChanged(sel.first),
          segments: [
            for (final (key, icon, label) in options)
              ButtonSegment(
                value: key,
                icon: Icon(icon, size: 16),
                label:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: value,
        backgroundColor: Iron.cardHi,
        thumbColor:
            Iron.isDark ? Color.lerp(Iron.cardHi, Iron.ink, 0.14)! : Iron.card,
        padding: const EdgeInsets.all(3),
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
        children: {
          for (final (key, icon, label) in options)
            key: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 16,
                      color:
                          value == key ? Iron.inkOf(Iron.accent) : Iron.faint),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Iron.caption(
                            color: value == key ? Iron.ink : Iron.sub,
                            weight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color hue,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBlob(icon, color: hue, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Iron.body(15, weight: FontWeight.w700)),
                  if (subtitle != null)
                    Text(subtitle, style: Iron.caption(color: Iron.faint)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color hue,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _row(
      icon: icon,
      hue: hue,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: isApple(context)
          ? CupertinoSwitch(
              value: value, activeTrackColor: Iron.accent, onChanged: onChanged)
          : Switch(value: value, onChanged: onChanged),
    );
  }
}
