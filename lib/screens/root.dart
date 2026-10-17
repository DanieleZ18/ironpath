import 'package:flutter/material.dart';

import '../l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    String t(String key) => L10n.t(key);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(key: _homeKey, goLibrary: () => setState(() => _tab = 1)),
          LibraryScreen(key: _libraryKey),
          HistoryScreen(key: _historyKey),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 0) _homeKey.currentState?.refresh();
          if (i == 1) _libraryKey.currentState?.refresh();
          if (i == 2) _historyKey.currentState?.refresh();
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t('tabHome')),
          NavigationDestination(icon: const Icon(Icons.list_outlined), selectedIcon: const Icon(Icons.list), label: t('tabLibrary')),
          NavigationDestination(icon: const Icon(Icons.history), selectedIcon: const Icon(Icons.history), label: t('tabHistory')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: t('tabSettings')),
        ],
      ),
    );
  }
}
