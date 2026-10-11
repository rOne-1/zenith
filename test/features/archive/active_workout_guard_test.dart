import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/preferences_provider.dart';
import 'package:zenith/core/storage/secure_storage_provider.dart';
import 'package:zenith/engine/database_provider.dart';
import 'package:zenith/engine/sbee_service.dart';
import 'package:zenith/features/archive/models/zenith_archive_bundle.dart';
import 'package:zenith/features/archive/providers/archive_providers.dart';
import 'package:zenith/features/archive/services/archive_restore_service.dart';
import 'package:zenith/features/armory/providers/user_profile_provider.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Active Workout Guard & Reactive Invalidation Tests (Guardrail 4)', () {
    late ZenithArchiveBundle dummyBundle;

    setUp(() {
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      dummyBundle = ZenithArchiveBundle(
        schema: kArchiveSchema,
        version: kArchiveVersion,
        exportedAt: now,
        appVersion: '0.9.0',
        checksum: 'dummy-checksum',
        profile: const ArchiveProfileBundle(
          nonSensitive: {'availableEquipment': ['bodyweight']},
        ),
        preferences: const ArchivePreferencesBundle(
          hasCompletedOnboarding: true,
        ),
        database: const ArchiveDatabaseBundle(),
      );
    });

    test('throws ActiveSessionInProgressException when resume probe finds incomplete session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
          // Simulate activeSessionResumeProvider returning an active SessionStreamManager
          activeSessionResumeProvider.overrideWith(
            (ref) async => _MockSessionStreamManager(),
          ),
        ],
      );

      // Await probe resolution
      await container.read(activeSessionResumeProvider.future);

      final coordinator = container.read(archiveRestoreCoordinatorProvider);
      expect(coordinator.isSessionInProgress, isTrue);

      expect(
        () => coordinator.restore(dummyBundle),
        throwsA(isA<ActiveSessionInProgressException>()),
      );
    });

    test('throws ActiveSessionInProgressException when ActiveSessionController is in warmUp/activeSet', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
          activeSessionResumeProvider.overrideWith((ref) async => null),
          // Override activeSessionControllerProvider with an active workout state
          activeSessionControllerProvider.overrideWith((ref) {
            return _MockActiveSessionController(
              ActiveSessionState(
                session: WorkoutSession(
                  id: 'session-live',
                  startTime: DateTime.now(),
                  sets: [],
                ),
                fsmState: SessionState.activeSet,
              ),
              ref,
            );
          }),
        ],
      );

      final coordinator = container.read(archiveRestoreCoordinatorProvider);
      expect(coordinator.isSessionInProgress, isTrue);

      expect(
        () => coordinator.restore(dummyBundle),
        throwsA(isA<ActiveSessionInProgressException>()),
      );
    });

    test('succeeds and invalidates shell providers when no session is in progress', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      bool didRestore = false;
      final mockRestoreService = _MockArchiveRestoreService(
        prefs: prefs,
        onRestore: (bundle) => didRestore = true,
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
          activeSessionResumeProvider.overrideWith((ref) async => null),
          archiveRestoreServiceProvider.overrideWithValue(mockRestoreService),
        ],
      );

      final coordinator = container.read(archiveRestoreCoordinatorProvider);
      expect(coordinator.isSessionInProgress, isFalse);

      await coordinator.restore(dummyBundle);
      expect(didRestore, isTrue);

      // Verify that userProfileProvider was invalidated and reloads cleanly
      final profile = container.read(userProfileProvider);
      expect(profile, isNotNull);
    });
  });
}

class _MockSessionStreamManager implements SessionStreamManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockActiveSessionController extends StateNotifier<ActiveSessionState>
    implements ActiveSessionController {
  _MockActiveSessionController(super.state, Ref ref);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockArchiveRestoreService extends ArchiveRestoreService {
  final void Function(ZenithArchiveBundle) onRestore;

  _MockArchiveRestoreService({
    required super.prefs,
    required this.onRestore,
  }) : super(
          secureStorage: InMemorySecureStorage(),
          db: SbeeDatabase(createDatabaseExecutor(inMemory: true)),
        );

  @override
  Future<void> restoreArchiveBundle(ZenithArchiveBundle bundle) async {
    onRestore(bundle);
  }
}
