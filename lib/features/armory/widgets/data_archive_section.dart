import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_card.dart';
import '../../../core/widgets/pixel_toast.dart';
import '../../../core/widgets/zenith_dialog.dart';
import '../../archive/providers/archive_providers.dart';
import '../../archive/services/archive_restore_service.dart';
import '../../archive/services/archive_validator.dart';
import '../../archive/widgets/archive_inspection_dialog.dart';

/// Armory section providing athlete data sovereignty controls:
/// full zero-telemetry JSON export and two-stage high-friction restore.
class DataArchiveSection extends ConsumerWidget {
  const DataArchiveSection({super.key});

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      final exportService = ref.read(archiveExportServiceProvider);
      final jsonString = await exportService.exportArchiveJson();
      final bridge = ref.read(archiveFileBridgeProvider);
      final dispatched = await bridge.saveOrShareArchive(jsonString);

      if (dispatched && context.mounted) {
        PixelToastHost.of(context)?.show('DATA ARCHIVE EXPORTED');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'EXPORT FAILED', e.toString());
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final coordinator = ref.read(archiveRestoreCoordinatorProvider);

    // Guardrail 4: Active workout lockout check
    if (coordinator.isSessionInProgress) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'SESSION IN PROGRESS',
          'An expedition is currently active or interrupted. Conclude or discard current expedition before restoring data.',
        );
      }
      return;
    }

    try {
      final bridge = ref.read(archiveFileBridgeProvider);
      final pickedJson = await bridge.pickArchiveFile();

      if (pickedJson == null || !context.mounted) {
        return; // User cancelled file picker
      }

      // Validate schema, bounds, checksum, and referential integrity
      final validator = ref.read(archiveValidatorProvider);
      final bundle = await validator.validateJsonString(pickedJson);

      if (!context.mounted) return;

      // Two-Stage Confirmation Inspection Modal
      final confirmed = await ArchiveInspectionDialog.show(context, bundle);

      if (confirmed == true && context.mounted) {
        await coordinator.restore(bundle);
        if (context.mounted) {
          PixelToastHost.of(context)?.show('DATA ARCHIVE RESTORED');
        }
      }
    } on ArchiveValidationException catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'INVALID ARCHIVE', e.message);
      }
    } on ActiveSessionInProgressException catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'SESSION IN PROGRESS', e.message);
      }
    } on ArchiveRestoreException catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'RESTORE FAILED', e.message);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'RESTORE ERROR', e.toString());
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    final colors = context.colors;
    ZenithDialog.showCard(
      context,
      borderColor: colors.signalRed,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: colors.signalRed,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  style: zenithPixelDisplay(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.signalRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            message,
            style: zenithBodyMono(
              fontSize: 12.0,
              height: 1.4,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
          PixelButton(
            variant: PixelButtonVariant.secondary,
            label: 'DISMISS',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              color: colors.amberAccent,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'DATA ARCHIVE // LOCAL BACKUP',
                  style: zenithPixelDisplay(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Info Card
        PixelCard(
          backgroundColor: colors.surfaceDark,
          borderColor: colors.borderBright,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'LOCAL SOVEREIGNTY ARCHIVE',
                style: zenithPixelDisplay(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.amberAccent,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Export complete training telemetry, SQLite history, and encrypted health data as an offline JSON archive, or restore local state from a verified backup. Zero external network telemetry.',
                style: zenithBodyMono(
                  fontSize: 12.0,
                  height: 1.4,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 16.0),

              // Action Buttons
              PixelButton(
                variant: PixelButtonVariant.secondary,
                label: 'EXPORT DATA ARCHIVE',
                icon: const Icon(CupertinoIcons.tray_arrow_up, size: 16.0),
                onPressed: () => _handleExport(context, ref),
              ),
              const SizedBox(height: 10.0),
              PixelButton(
                variant: PixelButtonVariant.danger,
                label: 'RESTORE FROM ARCHIVE',
                icon: const Icon(CupertinoIcons.tray_arrow_down, size: 16.0),
                onPressed: () => _handleRestore(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
