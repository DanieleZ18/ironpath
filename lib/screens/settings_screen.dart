import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ios_chrome.dart';
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
    setState(() => Store.instance.settings.appearance = value);
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    Iron.setAppearance(value, platformDark: platformDark);
    Store.instance.save();
  }

  void _setLang(String value) {
    setState(() => Store.instance.settings.lang = value);
    L10n.setLang(value,
        systemLocale:
            WidgetsBinding.instance.platformDispatcher.locale.toString());
    Store.instance.save();
  }

  void _setReminders(bool on) {
    setState(() => Store.instance.settings.remindersOn = on);
    Store.instance.save();
  }

  /// iOS wheel time picker in a bottom popup; commits on "Done".
  Future<void> _pickReminderTime() async {
    final s = Store.instance.settings;
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(text, style: Iron.body(16, weight: FontWeight.w800)),
      );

  Widget _divider() => Divider(
      height: 1, thickness: 1, indent: 64, endIndent: 16, color: Iron.line);

  /// iOS sliding segmented control: icon + label per option.
  Widget _segmented({
    required String value,
    required ValueChanged<String> onChanged,
    required List<(String, IconData, String)> options,
  }) {
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
      trailing: CupertinoSwitch(
          value: value, activeTrackColor: Iron.accent, onChanged: onChanged),
    );
  }
}
