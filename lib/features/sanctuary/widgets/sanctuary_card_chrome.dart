import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Shared header row for a Sanctuary card: a leading icon, a bold title with
/// a muted subtitle beneath it, and a trailing widget (typically a
/// [PixelBadge]). All 3 Sanctuary cards (adaptation ledger, macrocycle,
/// recovery grid) render this exact layout with their own icon/copy/badge.
class SanctuaryCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const SanctuaryCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: colors.amberAccent, size: 18.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: colors.amberAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
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
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        trailing,
      ],
    );
  }
}

/// Shared "still loading" placeholder for a Sanctuary card's async content.
class SanctuaryCardLoadingMessage extends StatelessWidget {
  final String message;

  const SanctuaryCardLoadingMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.0,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: 'Silkscreen',
            fontFamilyFallback: const ['monospace'],
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.colors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Shared error message for a Sanctuary card's async content.
class SanctuaryCardErrorMessage extends StatelessWidget {
  final String message;

  const SanctuaryCardErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Silkscreen',
          fontFamilyFallback: const ['monospace'],
          fontSize: 11.0,
          color: context.colors.signalRed,
        ),
      ),
    );
  }
}
