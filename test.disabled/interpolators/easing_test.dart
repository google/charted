/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.interpolators;

testEasing() {
  test('easeClamp clamps function returned value to [0, 1]', () {
    EasingFn f = (t) => t;
    EasingFn clampedFn = clampEasingFn(f);
    expect(clampedFn(-1), equals(0));
    expect(clampedFn(0), equals(0));
    expect(clampedFn(0.5), equals(0.5));
    expect(clampedFn(1), equals(1));
    expect(clampedFn(1.5), equals(1));
  });

  test('easeReverse returns the reversed ease function of parameter', () {
    EasingFn f = (t) => t * t;
    EasingFn reversedFn = reverseEasingFn(f);
    expect(reversedFn(0), equals(0));
    expect(reversedFn(0.5), equals(0.75));
    expect(reversedFn(1), equals(1));
  });

  test('easeReflect returns the reflected ease function of parameter', () {
    EasingFn f = (t) => t * t;
    EasingFn reflectedFn = reflectEasingFn(f);
    expect(reflectedFn(0), equals(0));
    expect(reflectedFn(0.25), equals(0.125));
    expect(reflectedFn(0.5), equals(0.5));
    expect(reflectedFn(0.75), equals(0.875));
    expect(reflectedFn(1), equals(1));
  });

  test('easePoly returns the pow ease function', () {
    EasingFn fn = easePoly(3);
    expect(fn(0), equals(0));
    expect(fn(0.5), equals(0.125));
    expect(fn(1), equals(1));
  });

  test('easeCubicInOut returns the in-out ease function', () {
    EasingFn fn = easeCubicInOut();
    expect(fn(0), equals(0));
    expect(fn(0.25), equals(0.0625));
    expect(fn(0.5), equals(0.5));
    expect(fn(0.75), equals(0.9375));
    expect(fn(1), equals(1));
  });

  test('easeSin returns the sin ease function', () {
    EasingFn fn = easeSin();
    expect(fn(0), equals(0));
    expect(fn(2 / 3), closeTo(0.5, EPSILON));
    expect(fn(1),  closeTo(1, EPSILON));
  });

  test('easeExp returns the sin ease function', () {
    EasingFn fn = easeExp();
    expect(fn(0), equals(0.0009765625));
    expect(fn(0.5), equals(0.03125));
    expect(fn(1),  equals(1));
  });

  test('easeCircle returns the sin ease function', () {
    EasingFn fn = easeCircle();
    expect(fn(0), equals(0));
    expect(fn(0.5), closeTo(0.1339745962155614, EPSILON));
    expect(fn(1),  equals(1));
  });

  test('easeElastic returns an elastic ease function', () {
    EasingFn fn = easeElastic();
    expect(fn(0), closeTo(0.7966042495754591, EPSILON));
    expect(fn(0.25), closeTo(1.0929845855896863, EPSILON));
    expect(fn(0.5), closeTo(0.9754637077195417, EPSILON));
    expect(fn(0.75), closeTo(1.0052459611883011, EPSILON));
    expect(fn(1), closeTo(0.9990238855152622, EPSILON));
  });

  test('easeBack returns a back ease function', () {
    EasingFn fn = easeBack();
    expect(fn(0), closeTo(0, EPSILON));
    expect(fn(0.25), closeTo(-0.06413656250000001, EPSILON));
    expect(fn(0.5), closeTo(-0.08769750000000004, EPSILON));
    expect(fn(0.75), closeTo(0.1825903124999999, EPSILON));
    expect(fn(1), closeTo(1, EPSILON));
  });

  test('easeBounce returns a bounce ease function', () {
    EasingFn fn = easeBounce();
    expect(fn(0), closeTo(0, EPSILON));
    expect(fn(0.1), closeTo(0.075625, EPSILON));
    expect(fn(0.2), closeTo(0.3025, EPSILON));
    expect(fn(0.3), closeTo(0.680625, EPSILON));
    expect(fn(0.4), closeTo(0.91, EPSILON));
    expect(fn(0.5), closeTo(0.765625, EPSILON));
    expect(fn(0.6), closeTo(0.7725, EPSILON));
    expect(fn(0.7), closeTo(0.930625, EPSILON));
    expect(fn(0.8), closeTo(0.94, EPSILON));
    expect(fn(0.9), closeTo(0.988125, EPSILON));
    expect(fn(1), closeTo(1, EPSILON));
  });
}