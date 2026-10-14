import 'package:flutter/material.dart';
import 'package:zenith/core/theme/zenith_motion.dart';

/// A [PageRoute] that occludes underlying routes while allowing the root backdrop to shine through.
///
/// In Zenith, [DistrictAtmosphereBackdrop] is hosted at the root in
/// [MaterialApp.builder] behind the [Navigator]. With [opaque] returning true,
/// Flutter's [RenderTheater] occludes and ceases painting underlying routes
/// (such as [ExpeditionPortalScreen] behind [ActiveExpeditionScreen]),
/// completely eliminating visual stacking and GPU overdraw while letting the
/// root backdrop shine through each screen's transparent [Scaffold].
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
  bool get opaque => true;

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
