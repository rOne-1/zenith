import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';
import 'features/armory/armory.dart';
import 'features/expedition/expedition.dart';
import 'features/grimoire/grimoire.dart';
import 'features/sanctuary/sanctuary.dart';

/// App-level provider tracking the active bottom navigation tab index.
final activeNavigationTabIndexProvider = StateProvider<int>((ref) => 0);

/// Primary App Shell managing top-level feature routing and persistent tab states.
///
/// Uses [IndexedStack] to ensure that map panning in Grimoire, scroll positions
/// in Expedition Portal and Armory, and atmospheric canvas backdrops remain
/// intact across tab transitions.
class ZenithAppShell extends ConsumerWidget {
  const ZenithAppShell({super.key});

  static const List<Widget> _screens = [
    ExpeditionPortalScreen(),
    GrimoireScreen(),
    ArmoryScreen(),
    SanctuaryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentIndex = ref.watch(activeNavigationTabIndexProvider);

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ZenithNavigationBar(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(activeNavigationTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
