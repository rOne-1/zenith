import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import '../theme/theme.dart';
import 'stepped_pixel_border.dart';

/// Specification for an individual ticket tab in [ZenithNavigationBar].
class ZenithNavigationTabItem {
  final String indexLabel;
  final String title;
  final IconData icon;

  const ZenithNavigationTabItem({
    required this.indexLabel,
    required this.title,
    required this.icon,
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
      title: 'EXPEDITION',
      icon: Icons.explore_outlined,
    ),
    ZenithNavigationTabItem(
      indexLabel: '02',
      title: 'GRIMOIRE',
      icon: Icons.map_outlined,
    ),
    ZenithNavigationTabItem(
      indexLabel: '03',
      title: 'ARMORY',
      icon: Icons.fitness_center_outlined,
    ),
    ZenithNavigationTabItem(
      indexLabel: '04',
      title: 'SANCTUARY',
      icon: Icons.nightlight_round_outlined,
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

class _TicketTabItem extends StatefulWidget {
  final ZenithNavigationTabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TicketTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TicketTabItem> createState() => _TicketTabItemState();
}

class _TicketTabItemState extends State<_TicketTabItem> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;
    final item = widget.item;
    final isSelected = widget.isSelected;

    final activeBorderColor = colors.amberAccent;
    final activeTextColor = colors.amberAccent;
    final inactiveTextColor = colors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: _isPressed
            ? const Duration(milliseconds: 60)
            : HouseSpring.duration,
        curve: HouseSpring.curve,
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
                  Icon(
                    item.icon,
                    size: 16.0,
                    color: isSelected ? activeTextColor : inactiveTextColor,
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
      ),
    );
  }
}
