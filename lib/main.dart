import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            home: Store.instance.settings.onboardingDone
                ? const RootShell()
                : const OnboardingPage(),
          ),
        );
      },
    );
  }
}
