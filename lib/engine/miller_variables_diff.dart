import 'package:sbee/sbee.dart';

/// True if [after] represents a genuine Kenneth Miller variable increase
/// over [before] -- i.e. any of the 5 fields is strictly greater.
///
/// `MillerVariables.increment()` (SBEE/lib/src/engine/miller_variables.dart)
/// only ever raises exactly one field by exactly one level, in a fixed
/// priority order, and never lowers a field or moves more than one field at
/// once; `.regress()` is the exact mirror. So comparing field-by-field like
/// this is exact, not a heuristic -- it's how host apps can read back what
/// SBEE's autoregulation logic actually did without needing
/// `AutoregulationAction`/`AutoregulationEngine`, which are internal to the
/// package and never exported.
bool millerVariablesIncreased(MillerVariables before, MillerVariables after) {
  return after.load > before.load ||
      after.bodyPosition > before.bodyPosition ||
      after.rom > before.rom ||
      after.height > before.height ||
      after.tempo > before.tempo;
}
