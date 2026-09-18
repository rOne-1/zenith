import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pixel_card.dart';

/// Presents a dialog using the app's own fast [zenithMotionCurve] motion
/// instead of Flutter's default fade+scale dialog transition.
///
/// Content is unchanged — callers still build whatever `PixelCard`/
/// `PixelButton` layout they need inside [builder]. Only the
/// entrance/exit choreography around that content is themed here, so
/// every `showDialog` call site in the app can share one implementation
/// (EP-3) instead of each inheriting Flutter's stock transition curve.
class ZenithDialog {
  const ZenithDialog._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: zenithMotionDuration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        // showDialog's DialogRoute wraps content in a route-scoping
        // Semantics node and a SafeArea; showGeneralDialog doesn't do
        // either on its own, so both are added explicitly here -- without
        // them a screen reader never announces entering a modal context,
        // and content isn't protected from notch/home-indicator overlap.
        return Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          label: MaterialLocalizations.of(dialogContext).dialogLabel,
          child: SafeArea(child: builder(dialogContext)),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: zenithMotionCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Convenience wrapper for the app's most common dialog shape: a
  /// transparent [Dialog] hosting a single [PixelCard].
  ///
  /// Every confirmation dialog in the app (abort, skip-set, same-day
  /// advisory) was independently hand-rolling this exact
  /// `Dialog(backgroundColor: Colors.transparent, child: PixelCard(...))`
  /// wrapper around [show] -- copy-pasted at each call site rather than
  /// shared, which had already let the sites drift slightly out of sync
  /// (one added `insetPadding` the others lacked). Centralizing it here
  /// means a future chrome tweak (padding, inset, corner treatment) only
  /// needs to change in one place (EP-3).
  static Future<T?> showCard<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? borderColor,
    bool barrierDismissible = true,
  }) {
    final colors = context.colors;
    return show<T>(
      context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 24.0,
        ),
        child: PixelCard(
          backgroundColor: colors.surfaceDark,
          borderColor: borderColor ?? colors.borderBright,
          padding: const EdgeInsets.all(20.0),
          child: builder(dialogContext),
        ),
      ),
    );
  }
}
