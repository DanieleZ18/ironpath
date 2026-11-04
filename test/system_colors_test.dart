import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/screens/settings_screen.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/system_colors.dart';
import 'package:gym_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.material.plugins/dynamic_color');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    Iron.systemHue = null;
    Iron.setTheme('sage');
  });

  test('Android 12+: the hue of the wallpaper accent', () async {
    // five tonal palettes × 13 tones; tone 40 of the first is the accent
    const accent = 0xFF3A6EA5; // a steel blue
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'getCorePalette') return null;
      // Android sends the colours as an int[] — an Int32List here
      return Int32List.fromList(
          List<int>.generate(65, (i) => i == 4 ? accent : 0xFF808080));
    });
    final hue = await SystemColors.accentHue();
    expect(hue, closeTo(HSLColor.fromColor(const Color(accent)).hue, 0.01));
  });

  test('desktop: the accent colour', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return call.method == 'getAccentColor' ? 0xFFC0504D : null;
    });
    final hue = await SystemColors.accentHue();
    expect(hue, closeTo(HSLColor.fromColor(const Color(0xFFC0504D)).hue, 0.01));
  });

  test('iPhone / older Android: no system colour', () async {
    // no handler: the plugin answers nothing
    expect(await SystemColors.accentHue(), isNull);
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await SystemColors.accentHue(), isNull);
  });

  testWidgets('Settings: System comes first and explains itself',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    Store.instance.settings.themeId = 'sage';
    L10n.setLang('en');
    Iron.setAppearance('light');
    Iron.setTheme('sage');
    await tester.pumpWidget(MaterialApp(
        theme: Iron.theme(), home: const Scaffold(body: SettingsScreen())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(Iron.themeId, 'system');
    expect(Store.instance.settings.themeId, 'system');
    // no system colour in tests: the note says Sage stands in
    expect(find.text(L10n.t('systemColorNone')), findsOneWidget);
  });
}
