import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (error) {
    // Without this, a platform-channel failure here throws before runApp
    // is ever called, so the app never reaches a widget tree and the user
    // sees a blank/frozen screen with no on-screen indication of failure.
    runApp(_StartupFailureApp(error: error));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZenithApp(),
    ),
  );
}

/// Minimal fallback shown only if startup fails before the app's own theme
/// and providers can be established.
class _StartupFailureApp extends StatelessWidget {
  final Object error;

  const _StartupFailureApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to start Zenith.\n$error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// The root widget of the Zenith application.
class ZenithApp extends ConsumerWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Zenith',
      debugShowCheckedModeBanner: false,
      theme: themeController.current.themeData,
      home: const ZenithAppShell(),
    );
  }
}
