import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'l10n.dart';
import 'models.dart';
import 'store.dart';
import 'utils.dart';
import 'weekly_program.dart';

/// Feeds the home-screen widget ("This week"): after every save the week's
/// state is written to the shared store the native widgets read (App Group
/// user defaults on iOS, home_widget's preferences on Android) and the
/// widgets are asked to redraw. Labels are sent already localised, so the
/// widget follows the app's language without its own strings.
class WidgetBridge {
  WidgetBridge._();

  /// Shared with the iOS widget extension (set the same id on both targets).
  static const appGroup = 'group.com.daniele.ironpath';
  static const androidProvider = 'WeekWidgetProvider';
  static const iosWidget = 'IronPathWidget';

  static bool _grouped = false;
  static bool _unavailable = false; // no plugin here (tests, desktop)

  /// What the widget shows, computed from [logs] and [settings] at [now].
  static Map<String, Object> payload(
      AppSettings settings, List<SessionLog> logs,
      {DateTime? now}) {
    final n = now ?? DateTime.now();
    final zh = L10n.zh;
    final program = deriveWeeklyProgram(settings);
    final done = completedThisWeek(settings, logs, now: n);
    final total = program?.slots.length ?? 0;
    final start = weekStartOf(n);
    final trained = List<bool>.filled(7, false);
    for (final l in logs) {
      if (l.startedAt.isBefore(start)) continue;
      final i = l.startedAt.difference(start).inDays;
      if (i >= 0 && i < 7) trained[i] = true;
    }
    final next = program != null && done < total ? program.slots[done] : null;
    return {
      'week_done': done,
      'week_total': total,
      'week_days': trained.map((t) => t ? '1' : '0').join(),
      'next_title': next?.title(zh) ?? '',
      'label_week': L10n.t('weekStrip'),
      'label_next': L10n.t('nextUp'),
      'label_done': L10n.t('weekAllDone'),
      'day_labels':
          [for (var d = 1; d <= 7; d++) fmtWeekdayShort(d, zh)].join('|'),
      'updated_at': n.millisecondsSinceEpoch,
    };
  }

  /// Write the current week to the widgets. Safe to call anywhere: on
  /// platforms without the plugin it does nothing.
  static Future<void> sync({DateTime? now}) async {
    if (kIsWeb || _unavailable) return;
    try {
      if (!_grouped) {
        await HomeWidget.setAppGroupId(appGroup);
        _grouped = true;
      }
      final data =
          payload(Store.instance.settings, Store.instance.logs, now: now);
      for (final e in data.entries) {
        final v = e.value;
        if (v is int) {
          await HomeWidget.saveWidgetData<int>(e.key, v);
        } else {
          await HomeWidget.saveWidgetData<String>(e.key, '$v');
        }
      }
      await HomeWidget.updateWidget(
          androidName: androidProvider, iOSName: iosWidget);
    } on MissingPluginException {
      _unavailable = true;
    } on PlatformException catch (e) {
      debugPrint('widget sync: ${e.message}');
    }
  }
}
