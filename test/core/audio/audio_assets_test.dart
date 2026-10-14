import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/audio/audio.dart';

void main() {
  group('16-Bit Neo-Pixel Sound Pool Asset Library (PKG-13.2)', () {
    test('all 4 canonical audio assets exist on disk with valid WAV headers', () {
      int totalBytes = 0;

      for (final cue in AudioCue.values) {
        final file = File('assets/${cue.assetPath}');
        expect(file.existsSync(), isTrue, reason: 'File must exist at assets/${cue.assetPath}');

        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(1000), reason: '${cue.name} must contain audio data');
        totalBytes += bytes.length;

        // Verify RIFF header
        expect(
          String.fromCharCodes(bytes.sublist(0, 4)),
          'RIFF',
          reason: '${cue.name} must start with RIFF header',
        );

        // Verify WAVE format
        expect(
          String.fromCharCodes(bytes.sublist(8, 12)),
          'WAVE',
          reason: '${cue.name} must be a WAVE format file',
        );

        // Verify fmt chunk
        expect(
          String.fromCharCodes(bytes.sublist(12, 16)),
          'fmt ',
          reason: '${cue.name} must declare fmt chunk',
        );

        // Verify PCM audio format code (1 = uncompressed PCM)
        final audioFormat = bytes[20] | (bytes[21] << 8);
        expect(audioFormat, 1, reason: '${cue.name} must be uncompressed PCM');

        // Verify 16-bit depth
        final bitsPerSample = bytes[34] | (bytes[35] << 8);
        expect(bitsPerSample, 16, reason: '${cue.name} must be 16-bit audio');
      }

      // Assert total footprint is strictly under 500 KB (< 512,000 bytes)
      expect(totalBytes, lessThan(500 * 1024), reason: 'Total audio assets footprint must be < 500 KB');
    });
  });
}
