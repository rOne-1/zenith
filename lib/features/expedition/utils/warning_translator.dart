import 'package:flutter/material.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Semantic classification for coaching notifications to drive terminal styling.
enum CoachingNoticeType {
  postural,
  recovery,
  detraining,
  general,
}

/// Structured coaching note translated from SBEE biomechanical rules.
class CoachingNotice {
  final String title;
  final String message;
  final CoachingNoticeType type;

  const CoachingNotice({
    required this.title,
    required this.message,
    required this.type,
  });
}

/// Translates SBEE engine warning states, detraining flags, and same-day volume
/// considerations into calm, supportive, empowering educational coaching guidance.
class WarningTranslator {
  /// Calm coaching translation for [PosturalWarningReason.noPullingAvailable].
  static const String noPullingAvailableMessage =
      'Focusing on pushing movements today. Consider adding pulling gear (bands/bar) to your Depot for balanced posture.';

  /// Calm coaching translation for [PosturalWarningReason.historicalDeficit].
  static const String historicalDeficitMessage =
      'Prioritizing upper-body pulling volume today to restore shoulder balance.';

  /// Calm coaching translation for [RecoveryReason.allMovementPatternsLocked].
  static const String allMovementPatternsLockedMessage =
      'High-intensity fatigue detected across all patterns. Today is an Active Recovery session (low intensity, restorative movement) to accelerate repair.';

  /// Calm coaching translation for detraining (14+ days inactive).
  static const String detrainingMessage =
      'Welcome back. Tempo adjusted to 4-2-1 with joint stabilization focus for safe re-acclimation.';

  /// Same-day second session advisory header and copy.
  static const String sameDayAdvisoryTitle = 'EXPEDITION ADVISORY';
  static const String sameDayAdvisoryMessage =
      'You have already completed an expedition today. Another session in the same day compounds neuromuscular fatigue. Listen to your body and prioritize restorative recovery, or proceed mindfully with light volume.';

  /// Translates a [PosturalWarningReason] enum into calm coaching guidance.
  static String? translatePosturalWarning(PosturalWarningReason reason) {
    switch (reason) {
      case PosturalWarningReason.noPullingAvailable:
        return noPullingAvailableMessage;
      case PosturalWarningReason.historicalDeficit:
        return historicalDeficitMessage;
      case PosturalWarningReason.none:
        return null;
    }
  }

  /// Translates a [RecoveryReason] enum into calm coaching guidance.
  static String? translateRecoveryReason(RecoveryReason reason) {
    switch (reason) {
      case RecoveryReason.allMovementPatternsLocked:
        return allMovementPatternsLockedMessage;
      case RecoveryReason.none:
        return null;
    }
  }

  /// Translates detraining flag into an empowering acclimation notice.
  static String? translateDetraining({required bool isDetrained}) {
    if (isDetrained) {
      return detrainingMessage;
    }
    return null;
  }

  /// Extracts all active coaching notices from a [WorkoutSession].
  static List<CoachingNotice> extractNotices({
    required WorkoutSession session,
    bool isDetrained = false,
  }) {
    final notices = <CoachingNotice>[];

    // Detraining notice
    final detrained =
        isDetrained ||
        session.sets.any(
          (s) => s.cues.any(
            (c) =>
                c.toLowerCase().contains('stabilization baseline') ||
                c.toLowerCase().contains('4-2-1'),
          ),
        );

    if (detrained) {
      notices.add(
        const CoachingNotice(
          title: 'ACCLIMATION PROTOCOL',
          message: detrainingMessage,
          type: CoachingNoticeType.detraining,
        ),
      );
    }

    // Whole-body active recovery notice
    final recoveryText = translateRecoveryReason(session.recoveryReason);
    if (recoveryText != null) {
      notices.add(
        CoachingNotice(
          title: 'ACTIVE RECOVERY',
          message: recoveryText,
          type: CoachingNoticeType.recovery,
        ),
      );
    }

    // Postural balance notice
    final posturalText = translatePosturalWarning(session.posturalWarningReason);
    if (posturalText != null) {
      notices.add(
        CoachingNotice(
          title: 'POSTURAL HARMONY',
          message: posturalText,
          type: CoachingNoticeType.postural,
        ),
      );
    }

    return notices;
  }

  /// Evaluates whether the operator has already completed any workout session today.
  static Future<bool> hasCompletedSessionToday(
    SessionRepository sessionRepository, {
    DateTime? currentTime,
  }) async {
    final now = currentTime ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final sessionsToday = await sessionRepository.getSessionsInDateRange(
      startOfDay,
      endOfDay,
    );

    return sessionsToday.any((s) => s.isCompleted);
  }

  /// Renders a modal confirmation dialog warning the athlete that an expedition
  /// was already completed today.
  ///
  /// Returns `true` if the operator chooses to proceed anyway, or `false` if cancelled.
  static Future<bool> showSameDayAdvisoryDialog(BuildContext context) async {
    final result = await ZenithDialog.show<bool>(
      context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const SameDayAdvisoryDialog();
      },
    );
    return result ?? false;
  }
}

/// Retro 16-bit dialog container displaying the same-day expedition advisory.
class SameDayAdvisoryDialog extends StatelessWidget {
  const SameDayAdvisoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: PixelCard(
        backgroundColor: colors.surfaceDark,
        borderColor: colors.amberAccent,
        bevelColor: colors.borderMuted,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colors.amberAccent,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    WarningTranslator.sameDayAdvisoryTitle,
                    style: TextStyle(
                      fontFamily: 'Silkscreen',
                      fontFamilyFallback: const ['monospace'],
                      fontSize: 14.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // Divider ribbon
            Container(
              height: 2.0,
              color: colors.borderMuted,
            ),
            const SizedBox(height: 14.0),

            // Supportive Message
            Text(
              WarningTranslator.sameDayAdvisoryMessage,
              style: TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: const ['sans-serif'],
                fontSize: 13.0,
                height: 1.5,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 22.0),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'CANCEL',
                    variant: PixelButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: PixelButton(
                    label: 'PROCEED',
                    variant: PixelButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
