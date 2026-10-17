import 'package:flutter/material.dart';

import '../l10n.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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

  void _setReminderTime({int? hour, int? minute}) {
    setState(() {
      if (hour != null) Store.instance.settings.reminderHour = hour;
      if (minute != null) Store.instance.settings.reminderMinute = minute;
    });
    Store.instance.save();
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.instance.settings;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(L10n.t('appearance')),
          RadioGroup<String>(
            groupValue: s.appearance,
            onChanged: (value) {
              if (value != null) _setAppearance(value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'system',
                  title:
                      Text(L10n.t('systemDefault'), style: Iron.body(14)),
                ),
                RadioListTile<String>(
                  value: 'dark',
                  title: Text(L10n.t('dark'), style: Iron.body(14)),
                ),
                RadioListTile<String>(
                  value: 'light',
                  title: Text(L10n.t('light'), style: Iron.body(14)),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          _sectionTitle(L10n.t('language')),
          RadioGroup<String>(
            groupValue: s.lang,
            onChanged: (value) {
              if (value != null) _setLang(value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'system',
                  activeColor: Iron.accent,
                  title:
                      Text(L10n.t('systemDefault'), style: Iron.body(14)),
                ),
                RadioListTile<String>(
                  value: 'en',
                  activeColor: Iron.accent,
                  title: Text(L10n.t('english'), style: Iron.body(14)),
                ),
                RadioListTile<String>(
                  value: 'zh',
                  activeColor: Iron.accent,
                  title: Text(L10n.t('chinese'), style: Iron.body(14)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _sectionTitle(L10n.t('soundHaptics')),
          SwitchListTile(
            value: s.feedbackOn,
            onChanged: (v) {
              setState(() => Store.instance.settings.feedbackOn = v);
              Store.instance.save();
            },
            activeThumbColor: Iron.onAccent,
            activeTrackColor: Iron.accent,
            inactiveTrackColor: Iron.cardHi,
            inactiveThumbColor: Iron.faint,
            title: Text(L10n.t('soundHaptics'), style: Iron.body(14)),
            subtitle: Text(L10n.t('soundHapticsHint'),
                style: Iron.caption(color: Iron.faint)),
          ),
          SizedBox(height: 16),
          _sectionTitle(L10n.t('reminders')),
          SwitchListTile(
            value: s.remindersOn,
            onChanged: _setReminders,
            activeThumbColor: Iron.onAccent,
            activeTrackColor: Iron.accent,
            inactiveTrackColor: Iron.cardHi,
            inactiveThumbColor: Iron.faint,
            title: Text(
                '${L10n.t('reminders')}: ${pad2(s.reminderHour)}:${pad2(s.reminderMinute)}',
                style: Iron.body(14)),
          ),
          if (s.remindersOn)
            Row(
              children: [
                SizedBox(width: 16),
                DropdownButton<int>(
                  value: s.reminderHour,
                  dropdownColor: Iron.cardHi,
                  items: [
                    for (var h = 0; h < 24; h++)
                      DropdownMenuItem(
                          value: h,
                          child: Text(pad2(h), style: Iron.body(14))),
                  ],
                  onChanged: (v) => _setReminderTime(hour: v),
                ),
                const Text(' : '),
                DropdownButton<int>(
                  value: s.reminderMinute,
                  dropdownColor: Iron.cardHi,
                  items: [
                    for (var m = 0; m < 60; m += 5)
                      DropdownMenuItem(
                          value: m,
                          child: Text(pad2(m), style: Iron.body(14))),
                  ],
                  onChanged: (v) => _setReminderTime(minute: v),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
            child: Text(L10n.t('reminderStub'),
                style: Iron.caption(color: Iron.faint)),
          ),
          SizedBox(height: 16),
          _sectionTitle(L10n.t('runAgain')),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const OnboardingPage(reentry: true),
              ));
            },
            icon: Icon(Icons.person_pin_outlined, size: 18),
            label: Text(L10n.t('runAgain')),
          ),
          SizedBox(height: 16),
          _sectionTitle(L10n.t('about')),
          SizedBox(height: 4),
          IronCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t('offlinePitch'),
                    style: Iron.body(13, color: Iron.sub)),
                SizedBox(height: 12),
                Text(L10n.t('disclaimer'),
                    style: Iron.caption(color: Iron.faint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Iron.body(16, weight: FontWeight.w600)),
    );
  }
}
