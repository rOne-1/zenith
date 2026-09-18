import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/zenith_motion.dart';

void main() {
  group('ZenithStepCurve', () {
    test('quantizes into the expected number of discrete steps', () {
      const curve = ZenithStepCurve(6);
      final values = [for (var i = 0; i <= 100; i++) curve.transform(i / 100)];
      final distinctValues = values.toSet();

      expect(
        distinctValues.length,
        6,
        reason: 'should only ever land on 6 discrete values',
      );
      expect(curve.transform(0.0), 0.0);
      expect(curve.transform(1.0), 1.0);
    });

    test('is non-decreasing as t increases', () {
      const curve = ZenithStepCurve(6);
      var previous = curve.transform(0.0);
      for (var i = 1; i <= 100; i++) {
        final value = curve.transform(i / 100);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('default zenithStepCurve constant uses 6 steps', () {
      expect(zenithStepCurve.steps, 6);
    });
  });

  group('zenithMotionDuration', () {
    test('per-step hold time cleanly divides both 60Hz and 120Hz frame '
        'periods -- no fractional-frame jitter', () {
      final stepHoldMicros =
          zenithMotionDuration.inMicroseconds / (zenithStepCurve.steps - 1);
      const frame60Micros = 1000000 / 60;
      const frame120Micros = 1000000 / 120;

      double distanceFromWholeMultiple(double value, double period) {
        final remainder = value % period;
        return remainder < period / 2 ? remainder : period - remainder;
      }

      // A hold time must land within 1ms of an exact multiple of the
      // frame period at both refresh rates, or real-world vsync jitter
      // will make some steps render for one more/fewer frame than their
      // neighbors -- the mechanism behind the "frame drop" complaint at
      // the old 180ms/6-step curve (36ms/step, only ~2.7ms clear of the
      // 60Hz 2-frame boundary at 33.3ms).
      expect(
        distanceFromWholeMultiple(stepHoldMicros, frame60Micros),
        lessThan(1000),
        reason: 'not cleanly aligned to a 60Hz frame multiple',
      );
      expect(
        distanceFromWholeMultiple(stepHoldMicros, frame120Micros),
        lessThan(1000),
        reason: 'not cleanly aligned to a 120Hz frame multiple',
      );
    });
  });
}
