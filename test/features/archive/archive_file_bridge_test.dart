import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/features/archive/services/archive_file_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArchiveFileBridge Tests', () {
    test('formatArchiveFileName formats canonical timestamp string', () {
      final fixedDate = DateTime(2026, 10, 11, 14, 30, 45);
      final fileName = ArchiveFileBridge.formatArchiveFileName(fixedDate);
      expect(fileName, equals('zenith_archive_20261011_143045.json'));
    });

    test('saveOrShareArchive delegates cleanly to custom saver on desktop/web', () async {
      String? savedJson;
      String? savedFileName;
      String? savedTitle;

      final bridge = ArchiveFileBridge(
        isDesktopOrWebOverride: true,
        saveJson: (json, fileName, {dialogTitle = 'Save File'}) async {
          savedJson = json;
          savedFileName = fileName;
          savedTitle = dialogTitle;
          return true;
        },
      );

      final success = await bridge.saveOrShareArchive(
        '{"test": 123}',
        fileName: 'test_backup.json',
      );

      expect(success, isTrue);
      expect(savedJson, equals('{"test": 123}'));
      expect(savedFileName, equals('test_backup.json'));
      expect(savedTitle, equals('Export Zenith Archive'));
    });

    test('saveOrShareArchive delegates cleanly to custom sharer on mobile', () async {
      String? sharedJson;
      String? sharedFileName;
      String? sharedSubject;

      final bridge = ArchiveFileBridge(
        isDesktopOrWebOverride: false,
        shareJson: (json, fileName, {subject = 'Shared File'}) async {
          sharedJson = json;
          sharedFileName = fileName;
          sharedSubject = subject;
        },
      );

      final success = await bridge.saveOrShareArchive(
        '{"test": 456}',
        fileName: 'mobile_backup.json',
      );

      expect(success, isTrue);
      expect(sharedJson, equals('{"test": 456}'));
      expect(sharedFileName, equals('mobile_backup.json'));
      expect(sharedSubject, equals('Zenith Data Archive'));
    });

    test('pickArchiveFile delegates cleanly to custom picker', () async {
      final bridge = ArchiveFileBridge(
        pickJson: () async => '{"archive": true}',
      );

      final result = await bridge.pickArchiveFile();
      expect(result, equals('{"archive": true}'));
    });
  });
}
