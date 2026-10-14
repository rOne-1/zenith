import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/widgets/widgets.dart';
import 'features/armory/armory.dart';
import 'features/grimoire/grimoire.dart';
import 'features/outpost/outpost.dart';
import 'features/sanctuary/sanctuary.dart';

/// App-level provider tracking the active bottom navigation tab index.
final activeNavigationTabIndexProvider = StateProvider<int>((ref) => 0);

/// Minimum cumulative horizontal displacement (logical dp) required for a swipe
/// gesture to change tabs.
const double _kTabSwipeDisplacementThreshold = 64.0;

/// Minimum horizontal fling velocity (logical px/s) for a swipe gesture to
/// change tabs. Below this (or with insufficient displacement), a drag is left
/// alone so it doesn't fight a deliberate drag on content nested inside a tab
/// (e.g. the Atlas filter-pill row) -- only a real, committed swipe should navigate.
const double _kTabSwipeVelocityThreshold = 500.0;

/// Primary App Shell managing top-level feature routing and persistent tab states.
///
/// Uses [IndexedStack] to ensure that map panning in Atlas, scroll positions
/// in the Outpost and Depot, and atmospheric canvas backdrops remain
/// intact across tab transitions. The Expedition Portal's full itinerary is
/// no longer a persistent tab (F-23) -- the Outpost's daily-briefing summary
/// is the home screen instead, with a single push-navigated entry point into
/// the full itinerary.
class ZenithAppShell extends ConsumerStatefulWidget {
  const ZenithAppShell({super.key});

  static const List<Widget> _screens = [
    OutpostScreen(),
    GrimoireScreen(),
    ArmoryScreen(),
    SanctuaryScreen(),
  ];

  @override
  ConsumerState<ZenithAppShell> createState() => _ZenithAppShellState();
}

class _ZenithAppShellState extends ConsumerState<ZenithAppShell> {
  double _cumulativeDragDeltaX = 0.0;

  void _onHorizontalDragStart(DragStartDetails details) {
    _cumulativeDragDeltaX = 0.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _cumulativeDragDeltaX += details.primaryDelta ?? 0.0;
  }

  void _onHorizontalDragCancel() {
    _cumulativeDragDeltaX = 0.0;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    final displacement = _cumulativeDragDeltaX;
    _cumulativeDragDeltaX = 0.0;

    // Both displacement and velocity must exceed thresholds and agree in direction.
    if (displacement.abs() < _kTabSwipeDisplacementThreshold ||
        velocity.abs() < _kTabSwipeVelocityThreshold ||
        (displacement * velocity) <= 0) {
      return;
    }

    // A negative velocity/displacement is a right-to-left swipe (finger moving
    // toward negative x) -- that advances to the next tab.
    final direction = velocity < 0 ? 1 : -1;
    final currentIndex = ref.read(activeNavigationTabIndexProvider);
    final nextIndex = (currentIndex + direction).clamp(
      0,
      ZenithAppShell._screens.length - 1,
    );
    if (nextIndex != currentIndex) {
      ref.read(activeNavigationTabIndexProvider.notifier).state = nextIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(activeNavigationTabIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        key: const Key('zenithTabSwipeDetector'),
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragCancel: _onHorizontalDragCancel,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: IndexedStack(
          index: currentIndex,
          children: ZenithAppShell._screens,
        ),
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
