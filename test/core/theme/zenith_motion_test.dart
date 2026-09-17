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
}
