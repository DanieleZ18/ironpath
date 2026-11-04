import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/models.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/theme.dart';
import 'package:gym_app/widget_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');

  SessionLog log(DateTime at) => SessionLog(
      id: '$at',
      planId: 'p',
      planTitleEn: 'p',
      planTitleZh: 'p',
      startedAt: at,
      durationSeconds: 60,
      items: const []);

  final settings = AppSettings()
    ..onboardingDone = true
    ..userTier = 2
    ..userDays = 4
    ..userEquipment = 'dumbbell';

  setUp(() => L10n.setLang('en'));

  test('payload: the week as the widget needs it', () {
    final now = DateTime(2026, 10, 29, 20); // Thursday
    final logs = [
      log(DateTime(2026, 10, 29, 8)), // Thu
      log(DateTime(2026, 10, 26, 7)), // Mon
      log(DateTime(2026, 10, 25, 9)), // last week
    ];
    final p = WidgetBridge.payload(settings, logs, now: now);
    expect(p['week_done'], 2);
    expect(p['week_total'], 4);
    expect(p['week_days'], '1001000');
    expect(p['next_title'], isNotEmpty); // day 3 of the 4-day program
    expect(p['day_labels'], 'Mon|Tue|Wed|Thu|Fri|Sat|Sun');
    expect(p['label_week'], 'This week');
    expect(p['updated_at'], now.millisecondsSinceEpoch);
    // the app's accent travels with it, as signed 32-bit ARGB
    expect(p['accent_light'],
        Iron.accentFor(dark: false).fill.toARGB32().toSigned(32));
    expect(p['accent_dark'],
        Iron.accentFor(dark: true).fill.toARGB32().toSigned(32));
    for (final k in [
      'accent_text_light',
      'accent_text_dark',
      'accent_soft_light',
      'accent_soft_dark'
    ]) {
      final v = p[k] as int;
      expect(v, inInclusiveRange(-0x80000000, 0x7FFFFFFF), reason: k);
    }

    L10n.setLang('zh');
    final zh = WidgetBridge.payload(settings, logs, now: now);
    expect(zh['day_labels'], '一|二|三|四|五|六|日');
    expect(zh['label_week'], '本周');
  });

  test('payload: no program (skipped onboarding) still counts the week', () {
    final p = WidgetBridge.payload(AppSettings(), [log(DateTime(2026, 10, 27))],
        now: DateTime(2026, 10, 29));
    expect(p['week_done'], 1);
    expect(p['week_total'], 0);
    expect(p['next_title'], '');
  });

  test('sync writes every field and asks the widgets to redraw', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    Store.instance.settings = settings;
    Store.instance.logs.add(log(DateTime(2026, 10, 27, 7)));
    await WidgetBridge.sync(now: DateTime(2026, 10, 29, 20));

    final methods = calls.map((c) => c.method).toList();
    expect(methods.first, 'setAppGroupId');
    expect(calls.first.arguments['groupId'], WidgetBridge.appGroup);
    final saved = {
      for (final c in calls.where((c) => c.method == 'saveWidgetData'))
        c.arguments['id'] as String: c.arguments['data'],
    };
    expect(saved['week_done'], 1);
    expect(saved['week_total'], 4);
    expect(saved['week_days'], '0100000');
    expect(saved.keys, containsAll(['next_title', 'label_week', 'day_labels']));
    final update = calls.last;
    expect(update.method, 'updateWidget');
    expect(update.arguments['android'], WidgetBridge.androidProvider);
    expect(update.arguments['ios'], WidgetBridge.iosWidget);
  });

  test('sync is harmless where no widget plugin exists', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException();
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    await expectLater(WidgetBridge.sync(), completes);
  });
}
