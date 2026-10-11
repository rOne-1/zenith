import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Typography Zero-Raw-TextStyle Regression Tests (PKG-12.2 / PKG-12.4)', () {
    test('lib/features/ contains zero raw TextStyle instantiations', () {
      final featuresDir = Directory('lib/features');
      expect(featuresDir.existsSync(), isTrue, reason: 'lib/features directory must exist');

      final dartFiles = featuresDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
            continue;
          }
          if (line.contains('TextStyle(')) {
            violations.add('${file.path}:${i + 1}: $trimmed');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Raw TextStyle(...) instantiations are prohibited in feature code. '
            'Use zenithPixelDisplay(...), zenithBodyMono(...), or Theme.of(context).textTheme instead.\n'
            'Violations found:\n${violations.join('\n')}',
      );
    });
  });
}
