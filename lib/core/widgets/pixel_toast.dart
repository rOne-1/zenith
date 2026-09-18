import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A screen-local, self-dismissing toast banner — the themed replacement
/// for a stock Material [SnackBar].
///
/// Unlike [ScaffoldMessenger.showSnackBar], which attaches to the app's
/// root overlay and keeps showing regardless of which tab is active in an
/// [IndexedStack]-based shell, [PixelToastHost] renders inside the calling
/// screen's own widget subtree. A screen that isn't the active tab isn't
/// painted at all, so its toast simply isn't visible either — no cross-tab
/// bleed-through to guard against separately.
///
/// Usage: wrap a screen's body in [PixelToastHost], then call
/// `PixelToastHost.of(context)?.show('message')` from anywhere below it.
class PixelToastHost extends StatefulWidget {
  final Widget child;

  const PixelToastHost({super.key, required this.child});

  static PixelToastHostState? of(BuildContext context) {
    return context.findAncestorStateOfType<PixelToastHostState>();
  }

  @override
  State<PixelToastHost> createState() => PixelToastHostState();
}

class PixelToastHostState extends State<PixelToastHost> {
  String? _message;
  Timer? _dismissTimer;

  void show(String message, {Duration duration = const Duration(seconds: 2)}) {
    _dismissTimer?.cancel();
    setState(() => _message = message);
    _dismissTimer = Timer(duration, () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
          // widget.child carries its own SafeArea further down its own
          // subtree, but this toast is a Stack sibling of it, not a
          // descendant -- so without its own SafeArea here, `bottom: 16.0`
          // is measured against the full body and can render under a
          // device's home indicator / gesture bar instead of above it.
          child: SafeArea(
            top: false,
            child: IgnorePointer(
              child: AnimatedSlide(
                offset: _message != null ? Offset.zero : const Offset(0, 0.3),
                duration: zenithMotionDuration,
                curve: zenithMotionCurve,
                child: AnimatedOpacity(
                  opacity: _message != null ? 1.0 : 0.0,
                  duration: zenithMotionDuration,
                  curve: zenithMotionCurve,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      border: Border.all(color: colors.amberAccent, width: 1.5),
                    ),
                    child: Text(
                      _message ?? '',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 12.0,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
