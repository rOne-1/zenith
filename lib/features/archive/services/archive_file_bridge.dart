import 'package:flutter/foundation.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

/// Cross-platform abstraction for exporting and importing data archives
/// with host operating system parity across Desktop, Web, iOS, and Android.
class ArchiveFileBridge {
  final Future<bool> Function(String, String, {String dialogTitle})? saveJson;
  final Future<void> Function(String, String, {String subject})? shareJson;
  final Future<String?> Function()? pickJson;
  final bool? isDesktopOrWebOverride;

  const ArchiveFileBridge({
    this.saveJson,
    this.shareJson,
    this.pickJson,
    this.isDesktopOrWebOverride,
  });

  /// Generates the canonical export filename formatted as `zenith_archive_YYYYMMDD_HHMMSS.json`.
  static String formatArchiveFileName([DateTime? timestamp]) {
    final dt = (timestamp ?? DateTime.now()).toLocal();
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return 'zenith_archive_$year$month${day}_$hour$minute$second.json';
  }

  /// Whether current host platform is Desktop or Web.
  bool get isDesktopOrWeb {
    if (isDesktopOrWebOverride != null) return isDesktopOrWebOverride!;
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Exports an archive JSON string using the appropriate platform paradigm:
  /// - Native Desktop and Web: triggers native file save dialog or browser download.
  /// - Mobile (iOS / Android): presents the system share sheet.
  ///
  /// Returns `true` if the export was dispatched or accepted.
  Future<bool> saveOrShareArchive(
    String jsonString, {
    String? fileName,
  }) async {
    final targetName = fileName ?? formatArchiveFileName();
    if (isDesktopOrWeb) {
      final saver = saveJson ?? saveJsonFile;
      return saver(
        jsonString,
        targetName,
        dialogTitle: 'Export Zenith Archive',
      );
    } else {
      final sharer = shareJson ?? shareJsonFile;
      await sharer(
        jsonString,
        targetName,
        subject: 'Zenith Data Archive',
      );
      return true;
    }
  }

  /// Invokes the native file picker filtered to `.json` files and returns
  /// the contents as a UTF-8 string, or `null` if the user dismissed the dialog.
  Future<String?> pickArchiveFile() async {
    final picker = pickJson ?? pickJsonFile;
    return picker();
  }
}
