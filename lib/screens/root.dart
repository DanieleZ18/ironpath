import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../widgets/ios_chrome.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;
  // Key the tab bodies so Library refreshes its lists when switching back
  // after edits made elsewhere.
  final _homeKey = GlobalKey<HomeScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _historyKey = GlobalKey<HistoryScreenState>();
  // One controller per tab: re-tapping the active tab scrolls it to the top.
  final _scroll = List.generate(4, (_) => ScrollController());

  @override
  void dispose() {
    for (final c in _scroll) {
      c.dispose();
    }
    super.dispose();
  }

  void _select(int i) {
    HapticFeedback.selectionClick();
    if (i == _tab) {
      final c = _scroll[i];
      if (c.hasClients && c.offset > 0) {
        c.animateTo(0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic);
      }
      return;
    }
    setState(() => _tab = i);
    if (i == 0) _homeKey.currentState?.refresh();
    if (i == 1) _libraryKey.currentState?.refresh();
    if (i == 2) _historyKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => L10n.t(key);
    final tabs = [
      HomeScreen(
          key: _homeKey,
          scrollController: _scroll[0],
          goLibrary: () => _select(1)),
      LibraryScreen(key: _libraryKey, scrollController: _scroll[1]),
      HistoryScreen(key: _historyKey, scrollController: _scroll[2]),
      SettingsScreen(scrollController: _scroll[3]),
    ];
    return Scaffold(
      // content scrolls under the translucent tab bar
      extendBody: true,
      body: Stack(
        children: [
          for (var i = 0; i < tabs.length; i++)
            _FadeThroughTab(active: i == _tab, child: tabs[i]),
        ],
      ),
      bottomNavigationBar: IronTabBar(
        index: _tab,
        onTap: _select,
        items: [
          (CupertinoIcons.house, CupertinoIcons.house_fill, t('tabHome')),
          (CupertinoIcons.square_list, CupertinoIcons.square_list_fill,
              t('tabLibrary')),
          (CupertinoIcons.clock, CupertinoIcons.clock_fill, t('tabHistory')),
          (CupertinoIcons.gear, CupertinoIcons.gear_solid, t('tabSettings')),
        ],
      ),
    );
  }
}

/// Keeps every tab alive (like IndexedStack) but cross-fades between them
/// with a small upward drift. Inactive tabs are invisible, untouchable and
/// have their tickers paused, so they cost nothing while hidden.
class _FadeThroughTab extends StatelessWidget {
  final bool active;
  final Widget child;

  const _FadeThroughTab({required this.active, required this.child});

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    // the fade itself runs outside TickerMode so a leaving tab can finish
    // fading out; only the tab's own content is paused
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: _duration,
          curve: active ? Curves.easeOut : Curves.easeIn,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.015),
            duration: _duration,
            curve: Curves.easeOutCubic,
            child: TickerMode(
              enabled: active,
              // the page draws its own pixels once; the fade only composites
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
