import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/zenith_motion.dart';

void main() {
  group('zenithMotionCurve', () {
    test('starts at 0.0 and ends at 1.0', () {
      expect(zenithMotionCurve.transform(0.0), 0.0);
      expect(zenithMotionCurve.transform(1.0), 1.0);
    });

    test('is non-decreasing as t increases', () {
      var previous = zenithMotionCurve.transform(0.0);
      for (var i = 1; i <= 100; i++) {
        final value = zenithMotionCurve.transform(i / 100);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('is continuous, not stepped -- must not land on only a handful of '
        'discrete values', () {
      // Regression guard for the bug this curve replaced: a discrete-step
      // curve (6 held values) read as stutter/frame drops on a real
      // device even after its timing was retuned to align with 60Hz/120Hz
      // frame boundaries -- the fix was to stop stepping altogether, not
      // to tune the steps further. A continuous curve sampled at 100
      // points should land on close to 100 distinct values.
      final values = [
        for (var i = 0; i <= 100; i++) zenithMotionCurve.transform(i / 100),
      ];
      expect(values.toSet().length, greaterThan(50));
    });

    test('is front-loaded -- most motion happens early, for a fast snap', () {
      // "Ramp up the speed and snap": the curve should already be well
      // past the halfway point a tenth of the way through the animation,
      // not still easing in like a linear or ease-in-out curve would.
      expect(zenithMotionCurve.transform(0.1), greaterThan(0.4));
    });
  });

  group('zenithMotionDuration', () {
    test(
      'is short enough to read as a fast snap, not a lingering animation',
      () {
        expect(zenithMotionDuration.inMilliseconds, lessThanOrEqualTo(200));
      },
    );
  });
}
