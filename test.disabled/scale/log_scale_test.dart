/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.scale;

testLogScale() {
  group('LogScale.domain', () {
    test('is positive if the first element in domain is non-negative', () {
      LogScale log = new LogScale();
      log.domain = [1, 100];
      expect(log.apply(0.1), closeTo(-0.5, EPSILON));
      expect(log.apply(1), equals(0));
      expect(log.apply(10), equals(0.5));
      expect(log.apply(100), equals(1));
      expect(log.apply(1000), closeTo(1.5, EPSILON));
      expect(log.invert(0), equals(1));
      expect(log.invert(0.5), equals(10));
      expect(log.invert(1), equals(100));
    });
    test('is negative if the first element in domain is negative', () {
      LogScale log = new LogScale();
      log.domain = [-1, -100];
      expect(log.apply(-1), equals(0));
      expect(log.apply(-10), equals(0.5));
      expect(log.apply(-100), equals(1));
      expect(log.invert(0), equals(-1));
      expect(log.invert(0.5), equals(-10));
      expect(log.invert(1), equals(-100));
    });
  });

  test('LogScale supports setting clamp to clamp range', () {
    LogScale log = new LogScale();
    log.domain = [1, 100];
    log.clamp = true;
    expect(log.apply(0.1), equals(0));
    expect(log.apply(1), equals(0));
    expect(log.apply(10), equals(0.5));
    expect(log.apply(100), equals(1));
    expect(log.apply(1000), equals(1));
  });

  test('LogScale supports setting base of log', () {
    LogScale log = new LogScale();
    log.base = 2;
    log.domain = [1, 8];
    log.range = [1, 8];
    expect(log.apply(1), equals(1));
    expect(log.apply(4), closeTo(5.666666666666666, EPSILON));
    expect(log.apply(8), equals(8));
  });

  test('LogScale.rangeRound sets the interpolator to interpolateRound', () {
    LogScale log = new LogScale();
    log.domain = [1, 8];
    log.rangeRound([1, 8]);
    expect(log.apply(1), equals(1));
    expect(log.apply(4), equals(6));
    expect(log.apply(8), equals(8));
  });

  test('LogScale.ticks returns representative values from domain', () {
    LogScale log = new LogScale();
    log.domain = [1, 100];
    expect(log.ticks(), orderedEquals(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]));
    log.domain = [-1, -100];
    expect(log.ticks(), orderedEquals([-100, -90, -80, -70, -60, -50, -40, -30,
        -20, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1]));
  });

  test('LogScale.tickFormat formats tick values by specified formatter', () {
    // Default formatter
    LogScale log = new LogScale();
    log.domain = [1, 10];
    expect(log.ticks().map((d) => log.createTickFormatter(20)(d)),
        orderedEquals(['1e+0', '2e+0', '3e+0', '4e+0', '5e+0', '6e+0', '7e+0',
                       '8e+0', '9e+0', '1e+1']));
    // Specified formatter
    log.domain = [0.1, 1];
    expect(log.ticks().map((d) => log.createTickFormatter(20, '+%')(d)),
        orderedEquals(['+10%', '+20%', '+30%', '+40%', '+50%', '+60%', '+70%',
                       '+80%', '+90%', '+100%']));
  });

  test('LogScale.nice extends the domain to nice round values', () {
    LogScale log = new LogScale();
    log.domain = [0.20147987687960267, 0.996679553296417];
    log.nice();
    expect(log.domain, orderedEquals([0.1, 1]));
    log.domain = [-0.20147987687960267, -0.996679553296417];
    log.nice();
    expect(log.domain, orderedEquals([-0.1, -1]));
  });
}