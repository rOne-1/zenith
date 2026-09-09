import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

/// Presents a bottom sheet using the app's own [HouseSpring] motion instead
/// of Flutter's default slide-up bottom-sheet transition.
///
/// Content is unchanged -- callers still build whatever pixel-bordered
/// sheet layout they need inside [builder] (typically already wrapped in
/// `DragToDismissSheet` for the drag-to-close gesture). Only the
/// entrance/exit choreography and route-level Semantics around that content
/// are themed/added here, mirroring [ZenithDialog] so every themed-overlay
/// call site in the app shares one motion language (EP-3) instead of some
/// defaulting to Flutter's stock `showModalBottomSheet` transition.
class ZenithSheet {
  const ZenithSheet._();

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
        // showModalBottomSheet's own BottomSheet route wraps content in a
        // route-scoping Semantics node (empty label on iOS/macOS, the
        // shared "dialog" label elsewhere -- Flutter has no distinct
        // "sheet" label of its own); showGeneralDialog doesn't do this on
        // its own, so it's replicated here to match.
        final localizations = MaterialLocalizations.of(dialogContext);
        final routeLabel = switch (defaultTargetPlatform) {
          TargetPlatform.iOS || TargetPlatform.macOS => '',
          _ => localizations.dialogLabel,
        };
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: routeLabel,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: builder(dialogContext),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: HouseSpring.curve,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}
