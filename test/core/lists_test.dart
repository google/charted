/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.core;

testLists() {
  group('sum()', () {
    test('adds all elements in a list', () {
      expect(sum([10, 20, 30, -10]), equals(50));
    });

    test('returns 0 when the list is null or empty', () {
      expect(sum([]), equals(0));
      expect(sum(null), equals(0));
    });
  });

  group('Range', () {
    test('throws ArgumentError when range is infinite', () {
      expect(() => new Range(0, 1, 0), throwsArgumentError);
    });
    test('returns integers between 0 and [start] when only start is set', () {
      expect(new Range(5), orderedEquals([0, 1, 2, 3, 4]));
    });
    test('returns a list of increasing step values '
        'when start is less than stop', () {
      expect(new Range(0, 5), orderedEquals([0, 1, 2, 3, 4]));
      expect(new Range(10, 50, 10), orderedEquals([10, 20, 30, 40]));
      expect(new Range(-6, 0, 1.2),
          orderedEquals([-6, -4.8, -3.6, -2.4, -1.2]));
      expect(new Range(1.2, 1.6, 0.2), orderedEquals([1.2, 1.4]));
    });
    test('returns a list of decreasing step values '
        'when start is greater than stop', () {
      expect(new Range(5, 0, -1), orderedEquals([5, 4, 3, 2, 1]));
      expect(new Range(-1.2, -1.6, -0.2), orderedEquals([-1.2, -1.4]));
    });
  });
}
