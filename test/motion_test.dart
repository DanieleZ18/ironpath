import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/l10n.dart';
import 'package:gym_app/motion.dart';
import 'package:gym_app/screens/plan_detail.dart';
import 'package:gym_app/screens/root.dart';
import 'package:gym_app/store.dart';
import 'package:gym_app/theme.dart';
import 'package:gym_app/widgets/zoom_route.dart';

void main() {
  Future<void> setUpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await Store.instance.load();
    Store.instance.settings.onboardingDone = true;
    L10n.setLang('en');
    Iron.setAppearance('light');
    Iron.setTheme('sage');
  }

  Widget app(Widget home, {bool reduceMotion = false}) => MaterialApp(
        theme: Iron.theme(),
        home: home,
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      );

  final platforms =
      TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});

  testWidgets('library card zooms into plan detail and back',
      variant: platforms, (tester) async {
    await setUpPhone(tester);
    await tester.pumpWidget(app(const RootShell()));
    await tester.tap(find.byIcon(CupertinoIcons.square_list));
    await tester.pumpAndSettle();

    final title = Store.instance.builtin.first.titleEn;
    await tester.tap(find.text(title).last);
    await tester.pump(); // route pushed (offstage for one frame)
    await tester.pump(const Duration(milliseconds: 16));
    expect(ModalRoute.of(tester.element(find.byType(PlanDetailPage))),
        isA<ZoomPageRoute>());
    // mid-flight the page is being drawn inside the card's shape
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsOneWidget);

    final apple = defaultTargetPlatform == TargetPlatform.iOS;
    await tester.tap(
        find.byIcon(apple ? CupertinoIcons.chevron_back : Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsNothing);
  });

  testWidgets('iOS: dragging from the left edge zooms the page back',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS), (tester) async {
    await setUpPhone(tester);
    await tester.pumpWidget(app(const RootShell()));
    await tester.tap(find.byIcon(CupertinoIcons.square_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Store.instance.builtin.first.titleEn).last);
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsOneWidget);

    // a short drag that's let go springs back open…
    final g1 = await tester.startGesture(const Offset(5, 400));
    await g1.moveBy(const Offset(60, 0));
    await tester.pump();
    await g1.up();
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsOneWidget);

    // …a long one closes it
    final g2 = await tester.startGesture(const Offset(5, 400));
    for (var i = 0; i < 10; i++) {
      await g2.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g2.up();
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsNothing);
  });

  testWidgets('reduce motion: zoom becomes a quick cross-fade', (tester) async {
    await setUpPhone(tester);
    await tester.pumpWidget(app(const RootShell(), reduceMotion: true));
    await tester.tap(find.byIcon(CupertinoIcons.square_list));
    await tester.pumpAndSettle();

    await tester.tap(find.text(Store.instance.builtin.first.titleEn).last);
    await tester.pump();
    final route = ModalRoute.of(
        tester.element(find.byType(PlanDetailPage, skipOffstage: false)))!;
    expect(route, isNot(isA<ZoomPageRoute>()));
    expect(route.transitionDuration, const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  });

  testWidgets('Android: the predictive back gesture scrubs the zoom',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
    await setUpPhone(tester);
    await tester.pumpWidget(app(const RootShell()));
    await tester.tap(find.byIcon(CupertinoIcons.square_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Store.instance.builtin.first.titleEn).last);
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.byType(PlanDetailPage)))!;

    Future<void> send(String method, [double? progress]) async {
      final message = const StandardMethodCodec().encodeMethodCall(MethodCall(
          method,
          progress == null
              ? null
              : {
                  'touchOffset': [5.0, 400.0],
                  'progress': progress,
                  'swipeEdge': 0,
                }));
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.backGesture.name, message, (_) {});
      await tester.pump();
    }

    await send('startBackGesture', 0.0);
    await send('updateBackGestureProgress', 0.5);
    // halfway through the gesture the page is halfway back to the card
    expect(route.animation!.value, closeTo(0.5, 0.01));
    await send('commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsNothing);
  });

  test('spring curve starts at 0, ends at 1 and settles', () {
    for (final c in [Motion.snappy, Motion.smooth, Motion.bouncy]) {
      expect(c.transform(0), 0);
      expect(c.transform(1), 1);
      expect(c.transformInternal(0.999), closeTo(1, 0.01));
      expect(c.duration.inMilliseconds, inInclusiveRange(150, 1200));
    }
    // underdamped springs overshoot, critically damped ones don't
    final over = List.generate(100, (i) => Motion.bouncy.transform(i / 100))
        .reduce((a, b) => a > b ? a : b);
    expect(over, greaterThan(1.0));
    final crit = List.generate(100, (i) => Motion.smooth.transform(i / 100))
        .reduce((a, b) => a > b ? a : b);
    expect(crit, lessThanOrEqualTo(1.0));
  });

  testWidgets('RollingText shows the latest value after rolling',
      (tester) async {
    Widget at(String v) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RollingText(v, style: const TextStyle())));
    await tester.pumpWidget(at('1:30'));
    await tester.pumpWidget(at('1:29'));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Pressable never swallows the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Pressable(
          child: TextButton(onPressed: () => taps++, child: const Text('hit')),
        ),
      ),
    ));
    await tester.tap(find.text('hit'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('openPlanDetail falls back when the source is gone',
      (tester) async {
    await setUpPhone(tester);
    late BuildContext ctx;
    await tester.pumpWidget(app(Builder(builder: (c) {
      ctx = c;
      return const SizedBox.expand();
    })));
    openPlanDetail(ctx, Store.instance.builtin.first);
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailPage), findsOneWidget);
    expect(debugDefaultTargetPlatformOverride, isNull);
  });
}
