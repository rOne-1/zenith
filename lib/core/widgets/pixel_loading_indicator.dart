import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'stepped_pixel_border.dart';

/// An indeterminate loading indicator sharing [PixelCountdownBar]'s segmented
/// 16-bit HUD visual language, replacing Flutter's default
/// [CircularProgressIndicator] spinner.
///
/// A short window of illuminated blocks sweeps continuously across the bar
/// rather than spinning a stock circular arc — "telemetry still resolving,"
/// not "generic system busy."
class PixelLoadingIndicator extends StatefulWidget {
  final int totalBlocks;
  final int windowSize;
  final double height;
  final double width;
  final Duration sweepDuration;

  const PixelLoadingIndicator({
    super.key,
    this.totalBlocks = 14,
    this.windowSize = 3,
    this.height = 12.0,
    this.width = 120.0,
    this.sweepDuration = const Duration(milliseconds: 900),
  });

  @override
  State<PixelLoadingIndicator> createState() => _PixelLoadingIndicatorState();
}

class _PixelLoadingIndicatorState extends State<PixelLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.sweepDuration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final headPosition = (_controller.value * widget.totalBlocks).floor();

          return Container(
            padding: const EdgeInsets.all(2.0),
            decoration: ShapeDecoration(
              color: colors.surfaceDark,
              shape: SteppedPixelBorder(
                side: BorderSide(color: colors.borderBright, width: 1.0),
                stepSize: 2.0,
              ),
            ),
            child: Row(
              children: List.generate(widget.totalBlocks, (index) {
                final distance = (index - headPosition) % widget.totalBlocks;
                final isLit = distance < widget.windowSize;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < widget.totalBlocks - 1 ? 1.5 : 0.0,
                    ),
                    color: isLit ? colors.amberAccent : colors.borderMuted,
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
