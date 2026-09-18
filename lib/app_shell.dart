import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';
import 'features/armory/armory.dart';
import 'features/grimoire/grimoire.dart';
import 'features/outpost/outpost.dart';
import 'features/sanctuary/sanctuary.dart';

/// App-level provider tracking the active bottom navigation tab index.
final activeNavigationTabIndexProvider = StateProvider<int>((ref) => 0);

/// Minimum horizontal fling velocity (logical px/s) for a swipe gesture to
/// change tabs. Below this, a drag is left alone so it doesn't fight a
/// deliberate short drag on content nested inside a tab (e.g. the Atlas
/// filter-pill row) -- only a real, committed swipe should navigate.
const double _kTabSwipeVelocityThreshold = 300.0;

/// Primary App Shell managing top-level feature routing and persistent tab states.
///
/// Uses [IndexedStack] to ensure that map panning in Atlas, scroll positions
/// in the Outpost and Depot, and atmospheric canvas backdrops remain
/// intact across tab transitions. The Expedition Portal's full itinerary is
/// no longer a persistent tab (F-23) -- the Outpost's daily-briefing summary
/// is the home screen instead, with a single push-navigated entry point into
/// the full itinerary.
class ZenithAppShell extends ConsumerWidget {
  const ZenithAppShell({super.key});

  static const List<Widget> _screens = [
    OutpostScreen(),
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
      body: GestureDetector(
        key: const Key('zenithTabSwipeDetector'),
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (velocity.abs() < _kTabSwipeVelocityThreshold) return;
          // A negative velocity is a right-to-left swipe (finger moving
          // toward negative x) -- that advances to the next tab.
          final direction = velocity < 0 ? 1 : -1;
          final nextIndex = (currentIndex + direction).clamp(
            0,
            _screens.length - 1,
          );
          if (nextIndex != currentIndex) {
            ref.read(activeNavigationTabIndexProvider.notifier).state =
                nextIndex;
          }
        },
        child: IndexedStack(index: currentIndex, children: _screens),
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
