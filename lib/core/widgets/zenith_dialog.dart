import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

/// Presents a dialog using the app's own [HouseSpring] motion instead of
/// Flutter's default fade+scale dialog transition.
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
      transitionDuration: HouseSpring.duration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return builder(dialogContext);
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: HouseSpring.curve,
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
}
