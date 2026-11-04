import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root.dart';
import 'store.dart';
import 'theme.dart';
import 'widget_bridge.dart';
import 'widgets/theme_crossfade.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // bundled font ships under OFL-1.1; surface it on the licenses page
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
        ['Nunito'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await Store.instance.load();
  // pass the REAL system locale — otherwise 'system' silently resolves to
  // English for every non-English phone at startup
  L10n.setLang(
    Store.instance.settings.lang,
    systemLocale: ui.PlatformDispatcher.instance.locale.toString(),
  );
  Iron.setAppearance(
    Store.instance.settings.appearance,
    platformDark:
        ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark,
  );
  Iron.setTheme(Store.instance.settings.themeId,
      hue: Store.instance.settings.customHue);
  // the home-screen widget may be a week out of date by now
  unawaited(WidgetBridge.sync());
  runApp(const GymApp());
}

class GymApp extends StatefulWidget {
  const GymApp({super.key});

  @override
  State<GymApp> createState() => _GymAppState();
}

class _GymAppState extends State<GymApp> with WidgetsBindingObserver {
  final _crossfade = GlobalKey<ThemeCrossfadeState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _reduceMotion => WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  void _apply(VoidCallback change) {
    final host = _crossfade.currentState;
    if (host == null || _reduceMotion) {
      change();
    } else {
      host.crossfade(change);
    }
  }

  // 'system' settings follow the phone live, with the same crossfade the
  // phone itself uses when it switches appearance
  @override
  void didChangePlatformBrightness() {
    if (Iron.appearance != 'system') return;
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    if (dark == Iron.isDark) return;
    _apply(() => Iron.setAppearance('system', platformDark: dark));
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (L10n.setting != 'system') return;
    _apply(() => L10n.setLang('system',
        systemLocale:
            WidgetsBinding.instance.platformDispatcher.locale.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([L10n.notifier, Iron.notifier]),
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: Iron.overlay,
          child: MaterialApp(
            title: L10n.t('appTitle'),
            debugShowCheckedModeBanner: false,
            theme: Iron.theme(),
            // system widgets (time picker, menus, tooltips, Cupertino
            // pickers) follow the app language, not just our own strings
            locale: Locale(L10n.zh ? 'zh' : 'en'),
            supportedLocales: const [Locale('en'), Locale('zh')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            // our widgets read the palette directly, so a 200ms theme lerp
            // would animate only half the screen — switch in one frame
            themeAnimationDuration: Duration.zero,
            // iOS shows black behind a page that a card sheet pushes back
            builder: (context, child) => ThemeCrossfade(
              key: _crossfade,
              child: ColoredBox(color: Colors.black, child: child),
            ),
            home: Store.instance.settings.onboardingDone
                ? const RootShell()
                : const OnboardingPage(),
          ),
        );
      },
    );
  }
}
