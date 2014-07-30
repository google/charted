/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.scale;

testScaleUtil() {
  test('ScaleUtil::integerScaleRange() correctly finds the exponent of 10 '
      'to multiply a num variable to be an integer', () {
    /* Integers */
    expect(ScaleUtil.integerScaleRange(0), equals(1));
    expect(ScaleUtil.integerScaleRange(1), equals(1));
    expect(ScaleUtil.integerScaleRange(12), equals(1));
    /* Float numbers */
    expect(ScaleUtil.integerScaleRange(0.5), equals(10));
    expect(ScaleUtil.integerScaleRange(3.157), equals(1000));
    /* Negative numbers */
    expect(ScaleUtil.integerScaleRange(-1), equals(1));
    expect(ScaleUtil.integerScaleRange(-0.5), equals(10));
    expect(ScaleUtil.integerScaleRange(-3.157), equals(1000));
  });

  group('ScaleUtil::range()', () {
    test('throws RangeError when range is infinite', () {
      expect(() => ScaleUtil.range(0, 1, 0), throwsRangeError);
    });
    test('returns integers between 0 and [start] when only start is set', () {
      expect(ScaleUtil.range(5), orderedEquals([0, 1, 2, 3, 4]));
    });
    test('returns a list of increasing step values '
        'when start is less than stop', () {
      expect(ScaleUtil.range(0, 5), orderedEquals([0, 1, 2, 3, 4]));
      expect(ScaleUtil.range(10, 50, 10), orderedEquals([10, 20, 30, 40]));
      expect(ScaleUtil.range(-6, 0, 1.2),
          orderedEquals([-6, -4.8, -3.6, -2.4, -1.2]));
      expect(ScaleUtil.range(1.2, 1.6, 0.2), orderedEquals([1.2, 1.4]));
    });
    test('returns a list of decreasing step values '
        'when start is greater than stop', () {
      expect(ScaleUtil.range(5, 0, -1), orderedEquals([5, 4, 3, 2, 1]));
      expect(ScaleUtil.range(-1.2, -1.6, -0.2), orderedEquals([-1.2, -1.4]));
    });
  });

  group('ScaleUtil::nice()', () {
    Nice nice = new Nice((num x) => x.ceil(), (num x) => x.floor());
    test('extends domain extent to nice values '
        'when domain[0] <= domain[last]', () {
      expect(ScaleUtil.nice([0, 5], nice), orderedEquals([0, 5]));
      expect(ScaleUtil.nice([0.5, 4.5], nice), orderedEquals([0, 5]));
    });
    test('extends domain extent to nice values '
        'when domain[0] > domain[last]', () {
      expect(ScaleUtil.nice([5, 0], nice), orderedEquals([5, 0]));
      expect(ScaleUtil.nice([4.5, 0.5], nice), orderedEquals([5, 0]));
    });
  });

  group('ScaleUtil::niceStep()', () {
    Nice nice = ScaleUtil.niceStep(5);
    test('aligns a number to the nearest multiple of step less than num '
        'when step > 0', () {
      expect(nice.ceil(4), equals(5));
      expect(nice.ceil(5), equals(5));
      expect(nice.ceil(6), equals(10));
      expect(nice.floor(4), equals(0));
      expect(nice.floor(5), equals(5));
      expect(nice.floor(6), equals(5));
    });
    Nice nice2 = ScaleUtil.niceStep(0);
    test('returns the number itself when step <= 0', () {
      expect(nice2.ceil(4), equals(4));
      expect(nice2.ceil(5), equals(5));
      expect(nice2.floor(4), equals(4));
      expect(nice2.floor(6), equals(6));
    });
  });

  test('ScaleUtil::bilinearScale() returns a Function mapping a value '
      'on domain to corrsponding value on bilinear scale range', () {
    /* Polylinear scale maps [1, 5] to [2, 10] */
    Function domain2Range = ScaleUtil.bilinearScale(
        [1, 5], [2, 10], uninterpolateNumber, interpolateNumber);
    expect(domain2Range(1), equals(2));
    expect(domain2Range(5), equals(10));
    expect(domain2Range(2.5), equals(5));
    /* Polylinear scale maps [1, 5] to [10, 2] */
    domain2Range = ScaleUtil.bilinearScale(
        [1, 5], [10, 2], uninterpolateNumber, interpolateNumber);
    expect(domain2Range(1), equals(10));
    expect(domain2Range(5), equals(2));
    expect(domain2Range(2.5), equals(7));
  });

  test('ScaleUtil::polylinearScale() returns a Function mapping a value '
      'on domain to corrsponding value on polylinear scale range', () {
    /* Polylinear scale maps [1, 7, 9, 15] to [2, 10, 12, 15] */
    Function domain2Range = ScaleUtil.polylinearScale(
        [1, 7, 9, 15], [2, 10, 12, 15], uninterpolateNumber, interpolateNumber);
    /* Values less than 1 use the first segment */
    expect(domain2Range(-2), equals(-2));
    /* Values use the first segment */
    expect(domain2Range(1), equals(2));
    expect(domain2Range(2.5), equals(4));
    /* Values use the second segment */
    expect(domain2Range(7), equals(10));
    expect(domain2Range(8), equals(11));
    /* Values use the thrid segment */
    expect(domain2Range(9), equals(12));
    expect(domain2Range(12), equals(13.5));
    expect(domain2Range(15), equals(15));
    /* Values larger than 15 use the last segment */
    expect(domain2Range(20), equals(17.5));
  });

  test('ScaleUtil::bisectLeft() returns the insertion point for x such that'
      'all left values are smaller than x', () {
    /* Bisect in the whole segment */
    expect(ScaleUtil.bisectLeft([0, 1, 2, 3, 4], 1), equals(1));
    expect(ScaleUtil.bisectLeft([0, 1, 2, 3, 4], 1.5), equals(2));
    /* Bisect in the segment starting from the third element */
    expect(ScaleUtil.bisectLeft([0, 1, 2, 3, 4], 1.4, 3), equals(3));
    /* Bisect in specific segment */
    expect(ScaleUtil.bisectLeft([0, 1, 2, 3, 4], 1, 3, 4), equals(3));
    expect(ScaleUtil.bisectLeft([0, 1, 2, 3, 4], 5, 1, 2), equals(2));
  });

  test('ScaleUtil::bisectRight() returns the insertion point for x such that'
      'all left values are smaller or equal to x', () {
    /* Bisect in the whole segment */
    expect(ScaleUtil.bisectRight([0, 1, 2, 3, 4], 1), equals(2));
    expect(ScaleUtil.bisectRight([0, 1, 2, 3, 4], 1.5), equals(2));
    /* Bisect in the segment starting from the third element */
    expect(ScaleUtil.bisectRight([0, 1, 2, 3, 4], 1, 3), equals(3));
    /* Bisect in specific segment */
    expect(ScaleUtil.bisectRight([0, 1, 2, 3, 4], 1, 3, 4), equals(3));
    expect(ScaleUtil.bisectRight([0, 1, 2, 3, 4], 5, 1, 2), equals(2));
  });

}
