import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';
import 'engine/engine.dart';
import 'features/armory/armory.dart';
import 'features/districts/railside_outskirts/railside_atmosphere_backdrop.dart';

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
      home: const ZenithLandingScreen(),
    );
  }
}

/// Initial landing shell representing the expedition staging area in District 01.
class ZenithLandingScreen extends ConsumerStatefulWidget {
  const ZenithLandingScreen({super.key});

  @override
  ConsumerState<ZenithLandingScreen> createState() =>
      _ZenithLandingScreenState();
}

class _ZenithLandingScreenState extends ConsumerState<ZenithLandingScreen> {
  String? _statusFeedback;
  bool _isGenerating = false;

  Future<void> _handleInitiateExpedition() async {
    setState(() {
      _isGenerating = true;
      _statusFeedback = 'ENGAGING SBEE FACADE...';
    });

    try {
      final sbeeService = ref.read(sbeeServiceProvider);
      final profile = ref.read(userProfileProvider);
      final session = await sbeeService.generateNextWorkout(
        currentTime: DateTime.now(),
        availableEquipment: profile.availableEquipment,
        femaleProfile: profile.femaleProfile,
        hasJointPain: profile.hasJointPain,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          final dayTypeName = session.dayType?.name.toUpperCase() ?? 'CUSTOM';
          _statusFeedback =
              'DISPATCH PREPARED: $dayTypeName // ${session.sets.length} SETS PROGRAMMED';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusFeedback = 'DISPATCH ADAPTATION ERROR: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final districtTheme = themeController.current;
    final colors = districtTheme.colors;
    final resumeState = ref.watch(activeSessionResumeProvider);

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ZENITH // 頂点',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: colors.amberAccent,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          districtTheme.displayName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12.0,
                            letterSpacing: 1.5,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceDark,
                        border: Border.all(
                          color: colors.amberAccent,
                          width: 2.0,
                        ),
                      ),
                      child: Text(
                        'SECTOR 01',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Active Crash-Recovery Banner or Core Status Card
                resumeState.when(
                  data: (resumableManager) {
                    if (resumableManager != null) {
                      return PixelCard(
                        backgroundColor: colors.surfaceDark,
                        borderColor: colors.amberGlow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNRESOLVED EXPEDITION DETECTED',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: colors.amberGlow,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'A prior session was interrupted mid-dispatch. State reconstruction is primed and intact.',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              children: [
                                Expanded(
                                  child: PixelButton(
                                    label: 'RESUME DISPATCH',
                                    variant: PixelButtonVariant.primary,
                                    onPressed: () {
                                      setState(() {
                                        _statusFeedback =
                                            'RESUMING SAVED SESSION...';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                PixelButton(
                                  label: 'DISCARD',
                                  variant: PixelButtonVariant.secondary,
                                  onPressed: () async {
                                    await ref
                                        .read(sbeeServiceProvider)
                                        .discardActiveSession();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.borderBright,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SBEE ENGINE CORE // ONLINE',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: colors.amberAccent,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Periodized progressive overload engine ready.',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '• 5 Biomechanical Movement Patterns\n'
                            '• 15 Calibrated Exercises In Acyclic DAG\n'
                            '• Drift Local SQLite Persistence Active',
                            style: TextStyle(
                              fontSize: 12.0,
                              height: 1.5,
                              color: colors.textMuted,
                            ),
                          ),
                          if (_statusFeedback != null) ...[
                            const SizedBox(height: 12.0),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: colors.backgroundVoid,
                                border: Border.all(
                                  color: colors.amberAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                _statusFeedback!,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: colors.amberAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(colors.amberAccent),
                    ),
                  ),
                  error: (err, _) => PixelCard(
                    borderColor: colors.signalRed,
                    child: Text(
                      'Failed to initialize persistence: $err',
                      style: TextStyle(color: colors.signalRed),
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Primary Dispatch Action Button
                PixelButton(
                  label: _isGenerating
                      ? 'COMPUTING EXPEDITION...'
                      : 'INITIATE EXPEDITION',
                  enabled: !_isGenerating,
                  onPressed: _isGenerating ? null : _handleInitiateExpedition,
                ),
                const SizedBox(height: 10.0),
                PixelButton(
                  label: 'THE ARMORY // 装備庫',
                  variant: PixelButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ArmoryScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
