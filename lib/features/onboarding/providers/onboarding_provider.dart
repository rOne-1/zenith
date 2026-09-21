import 'package:shared_preferences/shared_preferences.dart';

import '../../armory/providers/user_profile_provider.dart';

/// Storage key marking that the first-launch onboarding flow has been
/// completed (or explicitly skipped through to the end).
const String kHasCompletedOnboardingKey = 'zenith_has_completed_onboarding';

/// Whether the app should show the onboarding flow or go straight to the
/// app shell. A fresh install (no stored flag) sees onboarding; an install
/// upgrading from before onboarding existed (a [kUserProfileStorageKey]
/// already on disk, but no flag yet) is treated as already onboarded rather
/// than trapped in a setup flow for settings it already configured via the
/// Depot.
bool hasCompletedOnboarding(SharedPreferences prefs) {
  return prefs.getBool(kHasCompletedOnboardingKey) ??
      prefs.containsKey(kUserProfileStorageKey);
}
