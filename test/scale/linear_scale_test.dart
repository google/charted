/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.scale;

testLinearScale() {
  group('LinearScale', () {
    test('applies a bilinearScale when domain length is 2', () {
      LinearScale linear = new LinearScale([1, 2], [5, 8]);
      expect(linear.apply(0), equals(2));
      expect(linear.apply(1), equals(5));
      expect(linear.apply(1.5), equals(6.5));
      expect(linear.apply(2), equals(8));
      expect(linear.invert(5), equals(1));
      expect(linear.invert(6.5), equals(1.5));
      expect(linear.invert(8), equals(2));
    });
    test('applies a polylinearScale when domain length is larger than 2', () {
      LinearScale linear = new LinearScale([1, 2, 3], [5, 8, 7]);
      expect(linear.apply(1), equals(5));
      expect(linear.apply(1.5), equals(6.5));
      expect(linear.apply(2), equals(8));
      expect(linear.apply(2.5), equals(7.5));
      expect(linear.apply(3), equals(7));
    });
  });

  test('LinearScale supports setting clamp to clamp range', () {
    LinearScale linear = new LinearScale([1, 2], [5, 8],
        interpolateNumber, true);
    expect(linear.apply(0), equals(5));
    expect(linear.apply(1), equals(5));
    expect(linear.apply(1.5), equals(6.5));
    expect(linear.apply(2), equals(8));
    expect(linear.apply(5), equals(8));
  });

  test('LinearScale.rangeRound sets the interpolator to interpolateRound', () {
    LinearScale linear = new LinearScale([1, 2]);
    linear.rangeRound([5, 8]);
    expect(linear.apply(1), equals(5));
    expect(linear.apply(1.5), equals(7));
    expect(linear.apply(2), equals(8));
  });

  test('LinearScale.ticks sets tick number and returns tick values', () {
    LinearScale linear = new LinearScale([0, 10], [1, 100]);
    expect(linear.ticks(2), orderedEquals([0, 5, 10]));
    expect(linear.ticks(3), orderedEquals([0, 5, 10]));
    expect(linear.ticks(4), orderedEquals([0, 2, 4, 6, 8, 10]));
    expect(linear.ticks(5), orderedEquals([0, 2, 4, 6, 8, 10]));
    expect(linear.ticks(6), orderedEquals([0, 2, 4, 6, 8, 10]));
    expect(linear.ticks(7), orderedEquals([0, 2, 4, 6, 8, 10]));
    expect(linear.ticks(8), orderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(linear.ticks(9), orderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(linear.ticks(10), orderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
  });

  test('LinearScale.tickFormat formats tick values by specified formatter', () {
    // Default formatter
    LinearScale linear = new LinearScale([0, 1], [1, 100]);
    expect(linear.ticks(2).map((d) => linear.createTickFormatter(2)(d)),
        orderedEquals(['0.0', '0.5', '1.0']));
    expect(linear.ticks(5).map((d) => linear.createTickFormatter(5)(d)),
        orderedEquals(['0.0', '0.2', '0.4', '0.6', '0.8', '1.0']));
    expect(linear.ticks(10).map((d) => linear.createTickFormatter(10)(d)),
        orderedEquals(['0.0', '0.1', '0.2', '0.3', '0.4', '0.5',
                       '0.6', '0.7', '0.8', '0.9', '1.0' ]));
    // Specified formatter
    expect(linear.ticks(2).map((d) => linear.createTickFormatter(2, '+%')(d)),
        orderedEquals(['+0%', '+50%', '+100%']));
    expect(linear.ticks(5).map((d) => linear.createTickFormatter(5, '+%')(d)),
        orderedEquals(['+0%', '+20%', '+40%', '+60%', '+80%', '+100%']));
    expect(linear.ticks(10).map((d) => linear.createTickFormatter(10, '+%')(d)),
        orderedEquals(['+0%', '+10%', '+20%', '+30%', '+40%', '+50%',
                       '+60%', '+70%', '+80%', '+90%', '+100%']));
  });

  test('LinearScale.nice extends the domain to nice round values', () {
    LinearScale linear = new LinearScale([0.5, 10.6], [1, 100]);
    linear.nice(10);
    expect(linear.domain, orderedEquals([0, 11]));
    linear.domain = [0.5, 10.6];
    linear.nice(4);
    expect(linear.domain, orderedEquals([0, 12]));
  });
}