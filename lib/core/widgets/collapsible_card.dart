import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'pixel_card.dart';

/// A [PixelCard] that starts collapsed to a single summary row and expands
/// on tap to reveal its full content, using the app's own quantized
/// [zenithStepCurve] motion (never a default Flutter transition curve).
///
/// Used to keep secondary information (data that's useful but not the
/// reason the athlete opened this screen) out of the way by default,
/// without deleting it — tapping the header always reveals the exact same
/// content a non-collapsible card would have shown.
class CollapsibleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = widget.accentColor ?? colors.amberAccent;

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.borderMuted,
      padding: const EdgeInsets.all(12.0),
      onTap: _toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: accent, size: 16.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 8.0,
                          letterSpacing: 0.5,
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: zenithMotionDuration,
                curve: zenithStepCurve,
                child: Icon(
                  Icons.expand_more,
                  color: colors.textMuted,
                  size: 18.0,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: zenithMotionDuration,
            curve: zenithStepCurve,
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: AnimatedOpacity(
                opacity: _expanded ? 1.0 : 0.0,
                duration: zenithMotionDuration,
                curve: zenithStepCurve,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: widget.child,
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
