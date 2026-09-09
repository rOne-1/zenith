import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import '../theme/theme.dart';
import 'stepped_pixel_border.dart';

/// Specification for an individual ticket tab in [ZenithNavigationBar].
class ZenithNavigationTabItem {
  final String indexLabel;
  final String title;

  /// A bespoke pixel glyph character (rendered in the display font), not a
  /// Material [IconData] -- keeps the nav bar's iconography as hand-picked
  /// as its borders and typography instead of falling back to a stock icon
  /// font glyph.
  final String glyph;

  const ZenithNavigationTabItem({
    required this.indexLabel,
    required this.title,
    required this.glyph,
  });
}

/// A retro 16-bit railway ticket navigation bar.
///
/// Features authentic ticket-punch tab styling, high contrast active highlights,
/// and tactile micro-haptic selection feedback.
class ZenithNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const ZenithNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const List<ZenithNavigationTabItem> tabs = [
    ZenithNavigationTabItem(
      indexLabel: '01',
      title: 'OUTPOST',
      glyph: '◉', // ◉ fisheye
    ),
    ZenithNavigationTabItem(
      indexLabel: '02',
      title: 'ATLAS',
      glyph: '◈', // ◈ diamond-in-diamond
    ),
    ZenithNavigationTabItem(
      indexLabel: '03',
      title: 'DEPOT',
      glyph: '▣', // ▣ square-in-square
    ),
    ZenithNavigationTabItem(
      indexLabel: '04',
      title: 'SANCTUARY',
      glyph: '◐', // ◐ half-shaded circle (moon/rest motif)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundVoid,
        border: Border(
          top: BorderSide(
            color: colors.borderMuted,
            width: 2.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(tabs.length, (index) {
              final item = tabs[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: _TicketTabItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    if (!isSelected) {
                      onDestinationSelected(index);
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TicketTabItem extends StatelessWidget {
  final ZenithNavigationTabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TicketTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;

    final activeBorderColor = colors.amberAccent;
    final activeTextColor = colors.amberAccent;
    final inactiveTextColor = colors.textMuted;

    // The press-and-spring-back interaction itself (isPressed tracking +
    // GestureDetector + AnimatedScale on HouseSpring) used to be hand-rolled
    // here, near-line-for-line duplicating PixelButton's own version --
    // flutter_refined_kit already ships exactly this as PressableScale, just
    // never adopted here. scaleAmount/pressDuration/behavior are passed
    // explicitly to preserve this tab's original tactile feel exactly.
    return PressableScale(
      onTap: onTap,
      hapticFeedback: true,
      scaleAmount: 0.92,
      pressDuration: const Duration(milliseconds: 60),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
        decoration: ShapeDecoration(
          color: isSelected ? colors.surfaceDark : Colors.transparent,
          shape: SteppedPixelBorder(
            side: BorderSide(
              color: isSelected ? activeBorderColor : Colors.transparent,
              width: 1.5,
            ),
            stepSize: metrics.cornerStepSize,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.glyph,
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 15.0,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
                const SizedBox(width: 4.0),
                Text(
                  item.indexLabel,
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.0),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Silkscreen',
                fontFamilyFallback: const ['monospace'],
                fontSize: 9.0,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.8,
                color: isSelected ? activeTextColor : inactiveTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
