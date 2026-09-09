import 'package:flutter/material.dart';

import '../theme/test_env/test_env.dart';

/// A small filled circle that can pulse to signal a live/changing state,
/// matching the original design mockup's `zlamp`/`zblink` keyframe language:
/// a settled ("ready") state stays still, while an actively-counting-down or
/// still-very-locked state visibly pulses, with two distinct pulse
/// characters -- a smooth ease-in-out breathing pulse for "almost there,"
/// and a harder, faster on/off blink for "still far off."
///
/// Deliberately does **not** use `HouseSpring`: this is an indefinite,
/// repeating oscillation, not a one-shot transition settling to a target,
/// so a spring curve (built for settling) is the wrong tool. A plain
/// repeating [AnimationController] with an explicit shape function is used
/// instead.
class PixelPulseDot extends StatefulWidget {
  final double size;
  final Color color;

  /// Full cycle duration. Ignored when [animate] is false.
  final Duration period;

  /// The opacity the dot dips to at the low point of its pulse.
  final double minOpacity;

  /// `true` for a hard on/off blink (matches the design's `steps(2,end)`
  /// timing -- an instant cut, not a fade); `false` for a smooth
  /// ease-in-out breathing pulse.
  final bool hardCut;

  /// `false` renders a fully static, full-opacity dot with no ticker at
  /// all -- the "ready/settled" state, which the design deliberately never
  /// animates (`anim:'none'`).
  final bool animate;

  const PixelPulseDot({
    super.key,
    required this.color,
    this.size = 10.0,
    this.period = const Duration(milliseconds: 1600),
    this.minOpacity = 0.35,
    this.hardCut = true,
    this.animate = true,
  });

  /// Pure pulse-shape function, exposed for direct testing: given a cycle
  /// position [t] in `[0, 1)`, returns the opacity the dot should show.
  /// Kept separate from the animating [State] so the shape itself (the
  /// `steps(2,end)` hard-cut vs. the eased breathing curve) is verifiable
  /// without needing a running [AnimationController] -- which is exactly
  /// what's suppressed under `flutter test` to avoid an infinite
  /// [AnimationController.repeat] hanging `WidgetTester.pumpAndSettle()`.
  static double opacityAt(
    double t, {
    required bool hardCut,
    required double minOpacity,
  }) {
    if (hardCut) {
      // steps(2,end): an instant cut halfway through the cycle, no fade.
      return t < 0.5 ? 1.0 : minOpacity;
    }
    // Smooth ease-in-out breathing pulse: a triangle wave (1 -> 0 -> 1 over
    // one cycle) reshaped by an ease-in-out curve.
    final triangle = 1.0 - (2.0 * t - 1.0).abs();
    final eased = Curves.easeInOut.transform(triangle);
    return minOpacity + (1.0 - minOpacity) * eased;
  }

  @override
  State<PixelPulseDot> createState() => _PixelPulseDotState();
}

class _PixelPulseDotState extends State<PixelPulseDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(PixelPulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.period != widget.period) {
      _controller?.dispose();
      _controller = null;
      _syncController();
    }
  }

  void _syncController() {
    // An infinitely-repeating AnimationController never satisfies
    // WidgetTester.pumpAndSettle() (it waits for animations to finish, and
    // this one never does) -- every existing screen test that pumps a
    // screen containing this widget would hang. Render statically at full
    // opacity under test instead, matching how the theme builder already
    // sidesteps Google Fonts network loading under FLUTTER_TEST.
    if (!widget.animate || isTestEnvironment) return;
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildDot(double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _buildDot(1.0);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _buildDot(
        PixelPulseDot.opacityAt(
          controller.value,
          hardCut: widget.hardCut,
          minOpacity: widget.minOpacity,
        ),
      ),
    );
  }
}
