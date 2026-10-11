import 'package:flutter/cupertino.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_card.dart';
import '../../../core/widgets/zenith_dialog.dart';
import '../models/zenith_archive_bundle.dart';

/// Modal dialog inspecting an imported archive's metadata, entity counts,
/// and presenting high-friction confirmation before executing a destructive restore.
class ArchiveInspectionDialog extends StatelessWidget {
  final ZenithArchiveBundle bundle;

  const ArchiveInspectionDialog({super.key, required this.bundle});

  /// Presents the inspection dialog inside [ZenithDialog.showCard].
  /// Returns `true` if the user confirmed the overwrite, `false` or `null` if cancelled.
  static Future<bool?> show(BuildContext context, ZenithArchiveBundle bundle) {
    return ZenithDialog.showCard<bool>(
      context,
      builder: (dialogContext) => ArchiveInspectionDialog(bundle: bundle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exportedDateStr = bundle.exportedAt.toLocal().toString().split('.').first;
    final equipmentList = (bundle.profile.nonSensitive['availableEquipment'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final experienceLevel =
        bundle.profile.nonSensitive['experienceLevel']?.toString() ?? 'Standard';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                color: colors.amberAccent,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'ARCHIVE INSPECTION',
                  style: zenithPixelDisplay(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Metadata Grid Container
          PixelCard(
            backgroundColor: colors.backgroundVoid,
            borderColor: colors.borderMuted,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(
                  context,
                  label: 'EXPORT DATE',
                  value: exportedDateStr,
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'APP VERSION',
                  value: 'v${bundle.appVersion}',
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'SESSIONS LOGGED',
                  value: '${bundle.database.workoutSessions.length}',
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'SETS COMPLETED',
                  value: '${bundle.database.workoutSets.length}',
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'PROGRESSIONS',
                  value: '${bundle.database.exerciseProgressions.length} exercises',
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'MILESTONES',
                  value: '${bundle.database.statusAchieved.length}',
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'EXPERIENCE TIER',
                  value: experienceLevel.toUpperCase(),
                ),
                const SizedBox(height: 6.0),
                _buildMetaRow(
                  context,
                  label: 'EQUIPMENT POOL',
                  value: equipmentList.isEmpty
                      ? 'Bodyweight only'
                      : equipmentList.join(', '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Danger Warning Banner
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colors.signalRed.withValues(alpha: 0.12),
              border: Border.all(
                color: colors.signalRed,
                width: 2.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: colors.signalRed,
                  size: 20.0,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERMANENT OVERWRITE',
                        style: zenithPixelDisplay(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: colors.signalRed,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Restoring this archive will replace all current training history, local profile settings, and encrypted health data on this device.',
                        style: zenithBodyMono(
                          fontSize: 12.0,
                          height: 1.35,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  variant: PixelButtonVariant.secondary,
                  label: 'CANCEL',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: PixelButton(
                  variant: PixelButtonVariant.danger,
                  label: 'CONFIRM OVERWRITE',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.0,
          child: Text(
            label,
            style: zenithPixelDisplay(
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: colors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: zenithBodyMono(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
