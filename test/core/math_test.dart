/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.core;

testMath() {
  test('toRadius() correctly converts degrees to radians', () {
    expect(toRadians(0), equals(0));
    expect(toRadians(180), equals(math.PI));
    expect(toRadians(360), equals(math.PI * 2));
    expect(toRadians(90), equals(math.PI / 2));
    expect(toRadians(30), equals(math.PI / 6));
    expect(toRadians(45), equals(math.PI / 4));
  });

  test('toDegrees() correctly converts radians to degrees', () {
    expect(toDegrees(0), closeTo(0, EPSILON));
    expect(toDegrees(math.PI), closeTo(180, EPSILON));
    expect(toDegrees(math.PI * 2), closeTo(360, EPSILON));
    expect(toDegrees(math.PI / 2), closeTo(90, EPSILON));
    expect(toDegrees(math.PI / 6), closeTo(30, EPSILON));
    expect(toDegrees(math.PI / 4), closeTo(45, EPSILON));
  });

  test('sinh() correctly calculates sinh', () {
    expect(sinh(0), equals(0));
    expect(sinh(0.5), closeTo(0.5210953054937474, EPSILON));
    expect(sinh(1), closeTo(1.1752011936438014, EPSILON));
    expect(sinh(-0.5), closeTo(-0.5210953054937474, EPSILON));
    expect(sinh(-1), closeTo(-1.1752011936438014, EPSILON));
  });

  test('cosh() correctly calculates cosh', () {
    expect(cosh(0), equals(1));
    expect(cosh(0.5), closeTo(1.1276259652063807, EPSILON));
    expect(cosh(1), closeTo(1.5430806348152437, EPSILON));
    expect(cosh(-0.5), closeTo(1.1276259652063807, EPSILON));
    expect(cosh(-1), closeTo(1.5430806348152437, EPSILON));
  });

  test('tanh() correctly calculates cosh', () {
    expect(tanh(0), equals(0));
    expect(tanh(0.5), closeTo(0.46211715726000974, EPSILON));
    expect(tanh(1), closeTo(0.7615941559557649, EPSILON));
    expect(tanh(-0.5), closeTo(-0.46211715726000974, EPSILON));
    expect(tanh(-1), closeTo(-0.7615941559557649, EPSILON));
  });
}
