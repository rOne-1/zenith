import 'dart:io' as io;

/// True if running under a Flutter test environment on IO platforms.
bool get isTestEnvironment => io.Platform.environment.containsKey('FLUTTER_TEST');
