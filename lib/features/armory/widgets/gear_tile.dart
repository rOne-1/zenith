import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/pixel_toast.dart';
import '../../../core/widgets/stepped_pixel_border.dart';

/// Presentation metadata for a piece of equipment.
class EquipmentInfo {
  final String displayName;
  final String categoryTag;
  final String code;
  final String description;

  const EquipmentInfo({
    required this.displayName,
    required this.categoryTag,
    required this.code,
    required this.description,
  });

  static const Map<Equipment, EquipmentInfo> catalog = {
    Equipment.bodyweight: EquipmentInfo(
      displayName: 'Bodyweight',
      categoryTag: 'CALISTHENIC BASE',
      code: 'BW',
      description: 'Immutable mass-bearing baseline',
    ),
    Equipment.pullUpBar: EquipmentInfo(
      displayName: 'Pull-up Bar',
      categoryTag: 'OVERHEAD ANCHOR',
      code: 'BAR',
      description: 'Overhead bar or structural beam',
    ),
    Equipment.bands: EquipmentInfo(
      displayName: 'Resistance Bands',
      categoryTag: 'VARIABLE TENSION',
      code: 'BND',
      description: 'Elastic resistance bands or loops',
    ),
    Equipment.benchOrChair: EquipmentInfo(
      displayName: 'Bench / Chair',
      categoryTag: 'ELEVATED PLATFORM',
      code: 'CHR',
      description: 'Stable chair, bench, or step platform',
    ),
    Equipment.suspension: EquipmentInfo(
      displayName: 'Suspension Straps',
      categoryTag: 'CLOSED CHAIN',
      code: 'SUS',
      description: 'Suspension trainer or gymnastic rings',
    ),
    Equipment.towel: EquipmentInfo(
      displayName: 'Door Towel Anchor',
      categoryTag: 'EXPEDIENT ANCHOR',
      code: 'TWL',
      description: 'Knot-in-door tension anchor setup',
    ),
  };

  static EquipmentInfo forEquipment(Equipment equipment) {
    return catalog[equipment] ??
        EquipmentInfo(
          displayName: equipment.name.toUpperCase(),
          categoryTag: 'EXPEDITION GEAR',
          code: equipment.name.substring(0, 3).toUpperCase(),
          description: 'Accessory expedition gear',
        );
  }
}

/// A retro 16-bit stepped card representing an equipment slot in the Armory.
///
/// Features:
/// - Three distinct visual states: `ANCHORED ●` (Bodyweight), `EQUIPPED ●`, and `LOCKED ○`.
/// - Tactile mechanical 1-frame drop and spring-rebound on press.
/// - Haptic feedback on state modification.
class GearTile extends StatefulWidget {
  final Equipment equipment;
  final bool isEquipped;
  final VoidCallback? onToggle;

  const GearTile({
    super.key,
    required this.equipment,
    required this.isEquipped,
    this.onToggle,
  });

  bool get isBodyweight => equipment == Equipment.bodyweight;

  @override
  State<GearTile> createState() => _GearTileState();
}

class _GearTileState extends State<GearTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  late final Animation<double> _springAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _springController, curve: HouseSpring.curve),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _springController.reset();
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _springController.forward(from: 0.0);
    _triggerAction();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _springController.forward(from: 0.0);
  }

  void _triggerAction() {
    if (widget.isBodyweight) {
      HapticFeedback.lightImpact();
      PixelToastHost.of(context)?.show(
        'Bodyweight is permanently anchored to guarantee calisthenic safety paths.',
      );
      return;
    }

    HapticFeedback.selectionClick();
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;
    final info = EquipmentInfo.forEquipment(widget.equipment);

    // Color states
    final Color borderColor;
    final Color statusTextColor;
    final String statusLabel;

    if (widget.isBodyweight) {
      borderColor = colors.amberAccent;
      statusTextColor = colors.amberAccent;
      statusLabel = 'ANCHORED ●';
    } else if (widget.isEquipped) {
      borderColor = colors.borderBright;
      statusTextColor = colors.amberGlow;
      statusLabel = 'EQUIPPED ●';
    } else {
      borderColor = colors.borderMuted;
      statusTextColor = colors.textMuted;
      statusLabel = 'LOCKED ○';
    }

    final double dropOffset = _isPressed
        ? 2.0
        : (1.0 - _springAnimation.value) * 1.5;

    return AnimatedBuilder(
      animation: _springAnimation,
      builder: (context, child) {
        return Transform.translate(offset: Offset(0, dropOffset), child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: ShapeDecoration(
            color: widget.isEquipped
                ? colors.surfaceElevated
                : colors.surfaceDark,
            shape: SteppedPixelBorder(
              side: BorderSide(color: borderColor, width: metrics.borderWidth),
              stepSize: metrics.cornerStepSize,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Code Badge & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: colors.backgroundVoid,
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      info.code,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: statusTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Middle: Name & Category
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.displayName,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: widget.isEquipped
                          ? colors.textPrimary
                          : colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    info.categoryTag,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9.0,
                      letterSpacing: 1.0,
                      color: colors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),

              // Bottom: Description snippet
              Text(
                info.description,
                style: TextStyle(
                  fontSize: 10.0,
                  height: 1.3,
                  color: colors.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
