// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

Uint8List createWav(List<double> samples, {int sampleRate = 44100}) {
  final numSamples = samples.length;
  final byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample
  const blockAlign = 2;
  final subchunk2Size = numSamples * 2;
  final chunkSize = 36 + subchunk2Size;

  final byteData = ByteData(44 + subchunk2Size);

  // ChunkID: "RIFF"
  byteData.setUint8(0, 0x52);
  byteData.setUint8(1, 0x49);
  byteData.setUint8(2, 0x46);
  byteData.setUint8(3, 0x46);

  // ChunkSize
  byteData.setUint32(4, chunkSize, Endian.little);

  // Format: "WAVE"
  byteData.setUint8(8, 0x57);
  byteData.setUint8(9, 0x41);
  byteData.setUint8(10, 0x56);
  byteData.setUint8(11, 0x45);

  // Subchunk1ID: "fmt "
  byteData.setUint8(12, 0x66);
  byteData.setUint8(13, 0x6D);
  byteData.setUint8(14, 0x74);
  byteData.setUint8(15, 0x20);

  // Subchunk1Size: 16 (PCM)
  byteData.setUint32(16, 16, Endian.little);

  // AudioFormat: 1 (PCM)
  byteData.setUint16(20, 1, Endian.little);

  // NumChannels: 1 (Mono)
  byteData.setUint16(22, 1, Endian.little);

  // SampleRate
  byteData.setUint32(24, sampleRate, Endian.little);

  // ByteRate
  byteData.setUint32(28, byteRate, Endian.little);

  // BlockAlign
  byteData.setUint16(32, blockAlign, Endian.little);

  // BitsPerSample: 16
  byteData.setUint16(34, 16, Endian.little);

  // Subchunk2ID: "data"
  byteData.setUint8(36, 0x64);
  byteData.setUint8(37, 0x61);
  byteData.setUint8(38, 0x74);
  byteData.setUint8(39, 0x61);

  // Subchunk2Size
  byteData.setUint32(40, subchunk2Size, Endian.little);

  // Samples
  for (int i = 0; i < numSamples; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final pcmSample = (clamped * 32767.0).round();
    byteData.setInt16(44 + i * 2, pcmSample, Endian.little);
  }

  return byteData.buffer.asUint8List();
}

List<double> generateTick({int sampleRate = 44100}) {
  // 65ms woodblock / high-pitched arcade blip (880Hz decaying rapidly with second harmonic)
  final totalSamples = (sampleRate * 0.065).round();
  final samples = <double>[];

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final env = math.exp(-t * 60.0);
    final wave = 0.7 * math.sin(2 * math.pi * 960 * t) +
        0.3 * math.sin(2 * math.pi * 1920 * t);
    samples.add(wave * env);
  }
  return samples;
}

List<double> generateStart({int sampleRate = 44100}) {
  // 200ms energetic neo-pixel arcade chirp (587Hz -> 880Hz upward arpeggio with 16-bit harmonics)
  final totalSamples = (sampleRate * 0.200).round();
  final part1Samples = (sampleRate * 0.070).round();
  final samples = <double>[];

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    double freq;
    double env;
    if (i < part1Samples) {
      freq = 587.33; // D5
      env = 0.8 * (1.0 - (i / part1Samples) * 0.3);
    } else {
      freq = 880.0; // A5
      final t2 = (i - part1Samples) / sampleRate;
      env = 0.9 * math.exp(-t2 * 12.0);
    }
    // Blend square harmonic with sine for retro 16-bit arcade tone
    final sine = math.sin(2 * math.pi * freq * t);
    final square = sine >= 0 ? 0.3 : -0.3;
    samples.add((0.7 * sine + square) * env);
  }
  return samples;
}

List<double> generateRest({int sampleRate = 44100}) {
  // 360ms descending harmonic chime (659Hz E5 -> 523Hz C5 soft bell)
  final totalSamples = (sampleRate * 0.360).round();
  final part1Samples = (sampleRate * 0.140).round();
  final samples = <double>[];

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    double freq;
    double env;
    if (i < part1Samples) {
      freq = 659.25; // E5
      final t1 = i / sampleRate;
      env = 0.75 * math.exp(-t1 * 8.0);
    } else {
      freq = 523.25; // C5
      final t2 = (i - part1Samples) / sampleRate;
      env = 0.85 * math.exp(-t2 * 7.0);
    }
    // Dual harmonic bell
    final wave = 0.8 * math.sin(2 * math.pi * freq * t) +
        0.2 * math.sin(2 * math.pi * (freq * 2.0) * t);
    samples.add(wave * env);
  }
  return samples;
}

List<double> generateComplete({int sampleRate = 44100}) {
  // 700ms triumphant 16-bit arpeggiated fanfare (C5 523Hz -> E5 659Hz -> G5 784Hz -> C6 1046Hz)
  final totalSamples = (sampleRate * 0.700).round();
  final step1 = (sampleRate * 0.090).round();
  final step2 = (sampleRate * 0.180).round();
  final step3 = (sampleRate * 0.270).round();
  final samples = <double>[];

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    double freq;
    double env;

    if (i < step1) {
      freq = 523.25; // C5
      env = 0.7;
    } else if (i < step2) {
      freq = 659.25; // E5
      env = 0.75;
    } else if (i < step3) {
      freq = 783.99; // G5
      env = 0.8;
    } else {
      freq = 1046.50; // C6
      final tFinal = (i - step3) / sampleRate;
      // Slight vibrato on final triumphant held note
      final vibrato = 4.0 * math.sin(2 * math.pi * 6.0 * tFinal);
      freq += vibrato;
      env = 0.9 * math.exp(-tFinal * 3.5);
    }

    final sine = math.sin(2 * math.pi * freq * t);
    final overtone = 0.25 * math.sin(2 * math.pi * (freq * 2.0) * t);
    samples.add((0.75 * sine + overtone) * env);
  }
  return samples;
}

void main() {
  final audioDir = Directory('assets/audio');
  if (!audioDir.existsSync()) {
    audioDir.createSync(recursive: true);
  }

  File('assets/audio/tick.wav').writeAsBytesSync(createWav(generateTick()));
  File('assets/audio/start.wav').writeAsBytesSync(createWav(generateStart()));
  File('assets/audio/rest.wav').writeAsBytesSync(createWav(generateRest()));
  File('assets/audio/complete.wav').writeAsBytesSync(createWav(generateComplete()));

  print('Audio assets generated successfully:');
  for (final file in audioDir.listSync()) {
    if (file is File) {
      print('${file.path}: ${file.lengthSync()} bytes');
    }
  }
}
