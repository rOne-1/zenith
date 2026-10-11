import 'package:flutter/material.dart';
import 'package:zenith/core/theme/zenith_motion.dart';

/// A transparent [PageRoute] that does not occlude underlying routes.
///
/// Ensures the persistent [DistrictAtmosphereBackdrop] in [ZenithAppShell]
/// remains rendered and active behind pushed screens, enforcing the
/// Single Backdrop Invariant (SP-1) and preventing native video texture
/// unbinding when pushed routes are popped or aborted.
class ZenithTransparentPageRoute<T> extends PageRoute<T> {
  ZenithTransparentPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    this.transitionDuration = zenithMotionDuration,
  });

  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = Theme.of(context).pageTransitionsTheme;
    return theme.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
