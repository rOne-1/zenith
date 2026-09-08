import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZenithApp(),
    ),
  );
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
