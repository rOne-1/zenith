import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/preferences_provider.dart';
import 'package:zenith/core/storage/secure_storage_provider.dart';
import 'package:zenith/core/theme/district_registry.dart';
import 'package:zenith/core/widgets/pixel_button.dart';
import 'package:zenith/core/widgets/pixel_toast.dart';
import 'package:zenith/features/archive/models/zenith_archive_bundle.dart';
import 'package:zenith/features/archive/providers/archive_providers.dart';
import 'package:zenith/features/archive/services/archive_file_bridge.dart';
import 'package:zenith/features/archive/widgets/archive_inspection_dialog.dart';
import 'package:zenith/features/armory/widgets/data_archive_section.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestHost({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        ...overrides,
      ],
      child: MaterialApp(
        theme: zenithThemeRegistry.defaultTheme.themeData,
        home: Scaffold(
          body: PixelToastHost(
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  group('DataArchiveSection Widget Tests (PKG-11.5)', () {
    testWidgets('renders section header, export button, and restore button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        buildTestHost(
          child: const DataArchiveSection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DATA ARCHIVE // LOCAL BACKUP'), findsOneWidget);
      expect(find.text('LOCAL SOVEREIGNTY ARCHIVE'), findsOneWidget);
      expect(find.text('EXPORT DATA ARCHIVE'), findsOneWidget);
      expect(find.text('RESTORE FROM ARCHIVE'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.tray_arrow_up), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.tray_arrow_down), findsOneWidget);
    });

    testWidgets('tapping Export invokes bridge and displays toast', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      bool didSave = false;
      final mockBridge = ArchiveFileBridge(
        isDesktopOrWebOverride: true,
        saveJson: (json, fileName, {dialogTitle = 'Save File'}) async {
          didSave = true;
          return true;
        },
      );

      await tester.pumpWidget(
        buildTestHost(
          child: const DataArchiveSection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
            archiveFileBridgeProvider.overrideWithValue(mockBridge),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('EXPORT DATA ARCHIVE'));
      await tester.pumpAndSettle();

      expect(didSave, isTrue);
      expect(find.text('DATA ARCHIVE EXPORTED'), findsOneWidget);
    });

    testWidgets('tapping Restore when session is in progress displays explanatory lockout alert', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        buildTestHost(
          child: const DataArchiveSection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
            // Simulate active session in progress via activeSessionControllerProvider
            activeSessionControllerProvider.overrideWith((ref) {
              return _MockActiveSessionController(
                ActiveSessionState(
                  session: WorkoutSession(
                    id: 'live-expedition',
                    startTime: DateTime.now(),
                    sets: [],
                  ),
                  fsmState: SessionState.activeSet,
                ),
                ref,
              );
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESTORE FROM ARCHIVE'));
      await tester.pumpAndSettle();

      expect(find.text('SESSION IN PROGRESS'), findsOneWidget);
      expect(find.textContaining('Conclude or discard current expedition'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('DISMISS'));
      await tester.pumpAndSettle();
      expect(find.text('SESSION IN PROGRESS'), findsNothing);
    });

    testWidgets('ArchiveInspectionDialog displays metadata and handles Cancel and Confirm', (tester) async {
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      final bundle = ZenithArchiveBundle(
        schema: kArchiveSchema,
        version: kArchiveVersion,
        exportedAt: now,
        appVersion: '0.9.0',
        checksum: 'checksum-xyz',
        profile: const ArchiveProfileBundle(
          nonSensitive: {
            'availableEquipment': ['bodyweight', 'pullUpBar'],
            'experienceLevel': 'intermediate',
          },
        ),
        preferences: const ArchivePreferencesBundle(
          hasCompletedOnboarding: true,
        ),
        database: const ArchiveDatabaseBundle(
          workoutSessions: [{'id': 's1'}, {'id': 's2'}],
          workoutSets: [{'id': 'set1'}, {'id': 'set2'}, {'id': 'set3'}],
          exerciseProgressions: [{'exerciseId': 'pullup'}],
          statusAchieved: [{'status': 'Intermediate'}],
        ),
      );

      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) => PixelButton(
                label: 'SHOW INSPECTION',
                onPressed: () async {
                  userChoice = await ArchiveInspectionDialog.show(context, bundle);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open inspection dialog
      await tester.tap(find.text('SHOW INSPECTION'));
      await tester.pumpAndSettle();

      expect(find.text('ARCHIVE INSPECTION'), findsOneWidget);
      expect(find.text('PERMANENT OVERWRITE'), findsOneWidget);
      expect(find.text('v0.9.0'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // sessions
      expect(find.text('3'), findsOneWidget); // sets
      expect(find.text('1 exercises'), findsOneWidget); // progressions
      expect(find.text('INTERMEDIATE'), findsOneWidget);
      expect(find.text('bodyweight, pullUpBar'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(userChoice, isFalse);

      // Re-open and tap Confirm Overwrite
      await tester.tap(find.text('SHOW INSPECTION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRM OVERWRITE'));
      await tester.pumpAndSettle();
      expect(userChoice, isTrue);
    });
  });
}

class _MockActiveSessionController extends StateNotifier<ActiveSessionState>
    implements ActiveSessionController {
  _MockActiveSessionController(super.state, Ref ref);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
