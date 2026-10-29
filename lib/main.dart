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
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

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
            builder: (context, child) =>
                ColoredBox(color: Colors.black, child: child),
            home: Store.instance.settings.onboardingDone
                ? const RootShell()
                : const OnboardingPage(),
          ),
        );
      },
    );
  }
}
